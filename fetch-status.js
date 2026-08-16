#!/usr/bin/env node
/**
 * fetch-status.js
 *
 * Pulls REAL data from AWS for the platform status dashboard —
 * no mock values. Run this locally (uses your existing AWS CLI credentials,
 * the same ones terragrunt/terraform already use) before opening
 * platform-status.html, or point a cron/task scheduler at it to refresh
 * data.json periodically.
 *
 * Usage:
 *   node fetch-status.js dev
 *   node fetch-status.js qa
 *   node fetch-status.js prod
 *   node fetch-status.js all      (fetches dev, qa, prod into one data.json)
 *
 * Requires: @aws-sdk/client-ecs, @aws-sdk/client-elastic-load-balancing-v2,
 *           @aws-sdk/client-cloudwatch, @aws-sdk/client-rds, @aws-sdk/client-ecr
 *
 * Install once:
 *   npm install @aws-sdk/client-ecs @aws-sdk/client-elastic-load-balancing-v2 \
 *               @aws-sdk/client-cloudwatch @aws-sdk/client-rds @aws-sdk/client-ecr
 */

const fs = require("fs");
const path = require("path");

const { ECSClient, DescribeServicesCommand, DescribeClustersCommand } = require("@aws-sdk/client-ecs");
const { ElasticLoadBalancingV2Client, DescribeLoadBalancersCommand, DescribeTargetGroupsCommand, DescribeTargetHealthCommand } = require("@aws-sdk/client-elastic-load-balancing-v2");
const { CloudWatchClient, GetMetricDataCommand } = require("@aws-sdk/client-cloudwatch");
const { RDSClient, DescribeDBInstancesCommand } = require("@aws-sdk/client-rds");
const { ECRClient, DescribeImagesCommand, DescribeImageScanFindingsCommand } = require("@aws-sdk/client-ecr");

const REGION = "us-east-1";
const PROJECT = "enterprise-deployment-platform";
const ACCOUNT_ID = "260969591589";

const ENV_CONFIG = {
  dev:  { cidr: "10.0.0.0/16", nat: "Single (shared)", scaling: "min 1 / max 2" },
  qa:   { cidr: "10.1.0.0/16", nat: "Single (shared)", scaling: "min 1 / max 2" },
  prod: { cidr: "10.2.0.0/16", nat: "One per AZ (HA)", scaling: "min 2 / max 4" },
};

function client(Ctor) { return new Ctor({ region: REGION }); }

async function safe(fn, fallback = null) {
  try { return await fn(); } catch (err) {
    console.error(`  ! ${err.name || "Error"}: ${err.message}`);
    return fallback;
  }
}

async function getMetric(cw, namespace, metricName, dimensions, stat = "Average", periodMin = 5, windowMin = 60) {
  const end = new Date();
  const start = new Date(end.getTime() - windowMin * 60 * 1000);
  const res = await safe(() => cw.send(new GetMetricDataCommand({
    StartTime: start,
    EndTime: end,
    MetricDataQueries: [{
      Id: "m1",
      MetricStat: {
        Metric: { Namespace: namespace, MetricName: metricName, Dimensions: dimensions },
        Period: periodMin * 60,
        Stat: stat,
      },
      ReturnData: true,
    }],
  })));
  if (!res || !res.MetricDataResults || !res.MetricDataResults[0].Values.length) return null;
  const values = res.MetricDataResults[0].Values;
  return stat === "Sum" ? values.reduce((a, b) => a + b, 0) : values[values.length - 1];
}

async function fetchEnv(env) {
  console.log(`\nFetching real AWS data for [${env}]...`);
  const prefix = `${PROJECT}-${env}`;
  const cfg = ENV_CONFIG[env];

  const ecs = client(ECSClient);
  const elb = client(ElasticLoadBalancingV2Client);
  const cw = client(CloudWatchClient);
  const rds = client(RDSClient);
  const ecr = client(ECRClient);

  const clusterName = `${prefix}-cluster`;
  const serviceName = `${prefix}-service`;
  const albName = `edp-${env}-alb`;
  const tgName = `edp-${env}-tg`;
  const dbId = null; // filled in after describeDBInstances lookup by tag/prefix if needed

  // ---- ECS ----
  const svcRes = await safe(() => ecs.send(new DescribeServicesCommand({
    cluster: clusterName, services: [serviceName],
  })));
  const svc = svcRes?.services?.[0];
  const ecsDeployed = !!svc && svc.status === "ACTIVE";

  let ecsCpu = null, ecsMem = null;
  if (ecsDeployed) {
    ecsCpu = await getMetric(cw, "AWS/ECS", "CPUUtilization",
      [{ Name: "ClusterName", Value: clusterName }, { Name: "ServiceName", Value: serviceName }]);
    ecsMem = await getMetric(cw, "AWS/ECS", "MemoryUtilization",
      [{ Name: "ClusterName", Value: clusterName }, { Name: "ServiceName", Value: serviceName }]);
  }

  // ---- ALB / Target Group ----
  const albRes = await safe(() => elb.send(new DescribeLoadBalancersCommand({ Names: [albName] })));
  const alb = albRes?.LoadBalancers?.[0];
  let tgHealthy = null, tgTotal = null, tgArn = null;

  if (alb) {
    const tgRes = await safe(() => elb.send(new DescribeTargetGroupsCommand({
      LoadBalancerArn: alb.LoadBalancerArn,
    })));
    const tg = tgRes?.TargetGroups?.find(t => t.TargetGroupName === tgName) || tgRes?.TargetGroups?.[0];
    if (tg) {
      tgArn = tg.TargetGroupArn;
      const healthRes = await safe(() => elb.send(new DescribeTargetHealthCommand({ TargetGroupArn: tgArn })));
      const descs = healthRes?.TargetHealthDescriptions || [];
      tgTotal = descs.length;
      tgHealthy = descs.filter(d => d.TargetHealth.State === "healthy").length;
    }
  }

  let albRequests = null, alb5xx = null, albLatency = null;
  if (alb) {
    const albArnSuffix = alb.LoadBalancerArn.split(":loadbalancer/")[1];
    albRequests = await getMetric(cw, "AWS/ApplicationELB", "RequestCount",
      [{ Name: "LoadBalancer", Value: albArnSuffix }], "Sum");
    alb5xx = await getMetric(cw, "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
      [{ Name: "LoadBalancer", Value: albArnSuffix }], "Sum");
    albLatency = await getMetric(cw, "AWS/ApplicationELB", "TargetResponseTime",
      [{ Name: "LoadBalancer", Value: albArnSuffix }], "Average");
  }

  // ---- RDS ----
  const rdsRes = await safe(() => rds.send(new DescribeDBInstancesCommand({})));
  const dbInstance = rdsRes?.DBInstances?.find(d =>
    (d.DBInstanceIdentifier || "").includes(env) &&
    (d.TagList || []).some(t => t.Value && t.Value.includes(PROJECT))
  ) || rdsRes?.DBInstances?.find(d => (d.DBInstanceIdentifier || "").includes(env));

  let rdsCpu = null, rdsStorage = null;
  if (dbInstance) {
    rdsCpu = await getMetric(cw, "AWS/RDS", "CPUUtilization",
      [{ Name: "DBInstanceIdentifier", Value: dbInstance.DBInstanceIdentifier }]);
    rdsStorage = await getMetric(cw, "AWS/RDS", "FreeStorageSpace",
      [{ Name: "DBInstanceIdentifier", Value: dbInstance.DBInstanceIdentifier }]);
  }

  // ---- ECR ----
  const ecrRepo = `${prefix}-app`;
  const imgRes = await safe(() => ecr.send(new DescribeImagesCommand({
    repositoryName: ecrRepo,
  })));
  const images = (imgRes?.imageDetails || []).sort((a, b) =>
    (b.imagePushedAt?.getTime() || 0) - (a.imagePushedAt?.getTime() || 0));
  const latestImage = images[0];
  const latestTag = latestImage?.imageTags?.[0] || null;

  let scanFindings = null;
  if (latestImage && latestTag) {
    const scanRes = await safe(() => ecr.send(new DescribeImageScanFindingsCommand({
      repositoryName: ecrRepo, imageId: { imageTag: latestTag },
    })));
    const counts = scanRes?.imageScanFindings?.findingSeverityCounts;
    scanFindings = counts ? Object.values(counts).reduce((a, b) => a + b, 0) : 0;
  }

  const deployed = ecsDeployed && !!alb && !!dbInstance;

  return {
    label: env,
    fetchedAt: new Date().toISOString(),
    deployed,
    statusText: deployed ? (tgHealthy === tgTotal && tgTotal > 0 ? "operational" : "degraded") : "not deployed",
    statusLevel: deployed ? (tgHealthy === tgTotal && tgTotal > 0 ? "up" : "warn") : "warn",
    tasks: svc ? `${svc.runningCount} / ${svc.desiredCount}` : "0 / 0",
    deploy: latestTag ? `${latestTag}` : "no image pushed",
    cidr: cfg.cidr, nat: cfg.nat, tasksCfg: cfg.scaling,
    db: dbInstance ? `${dbInstance.Engine} ${dbInstance.EngineVersion} (${dbInstance.MultiAZ ? "Multi-AZ" : "single-AZ"})` : "not deployed",
    services: [
      {
        name: "ALB", sub: albName, icon: "lb",
        status: alb ? (tgHealthy === tgTotal && tgTotal > 0 ? "up" : "warn") : "warn",
        metrics: [
          ["Target group", alb ? `${tgHealthy ?? 0}/${tgTotal ?? 0} healthy` : "N/A"],
          ["Avg latency", albLatency != null ? `${Math.round(albLatency * 1000)} ms` : "N/A"],
          ["5xx (1h)", alb5xx != null ? String(Math.round(alb5xx)) : "N/A"],
        ],
      },
      {
        name: "ECS Fargate", sub: serviceName, icon: "box",
        status: ecsDeployed ? (svc.runningCount === svc.desiredCount ? "up" : "warn") : "warn",
        metrics: [
          ["Desired / running", svc ? `${svc.desiredCount} / ${svc.runningCount}` : "0 / 0"],
          ["CPU", ecsCpu != null ? `${ecsCpu.toFixed(1)}%` : "N/A"],
          ["Memory", ecsMem != null ? `${ecsMem.toFixed(1)}%` : "N/A"],
        ],
      },
      {
        name: "RDS PostgreSQL", sub: dbInstance ? `${dbInstance.EngineVersion} · ${dbInstance.MultiAZ ? "Multi-AZ" : "single-AZ"}` : "not deployed", icon: "db",
        status: dbInstance ? (dbInstance.DBInstanceStatus === "available" ? "up" : "warn") : "warn",
        metrics: [
          ["Status", dbInstance?.DBInstanceStatus || "N/A"],
          ["CPU", rdsCpu != null ? `${rdsCpu.toFixed(1)}%` : "N/A"],
          ["Storage free", rdsStorage != null ? `${(rdsStorage / 1e9).toFixed(1)} GB` : "N/A"],
        ],
      },
      {
        name: "ECR", sub: ecrRepo, icon: "layer",
        status: latestImage ? "up" : "warn",
        metrics: [
          ["Latest tag", latestTag || "none pushed"],
          ["Scan findings", scanFindings != null ? String(scanFindings) : "N/A"],
          ["Images stored", String(images.length)],
        ],
      },
    ],
  };
}

async function main() {
  const arg = process.argv[2] || "dev";
  const envs = arg === "all" ? ["dev", "qa", "prod"] : [arg];

 const outPath = path.join(__dirname, "data.json");
  let result = {};
  if (fs.existsSync(outPath)) {
    try { result = JSON.parse(fs.readFileSync(outPath, "utf8")); } catch (e) { result = {}; }
  }
  for (const env of envs) {
    result[env] = await fetchEnv(env);
  }

  fs.writeFileSync(outPath, JSON.stringify(result, null, 2));
  console.log(`\n✓ Wrote real AWS status to ${outPath}`);
  console.log(`  Open platform-status.html in a browser (same folder) to view it.`);
}

main().catch(err => {
  console.error("Fatal error:", err);
  process.exit(1);
});
