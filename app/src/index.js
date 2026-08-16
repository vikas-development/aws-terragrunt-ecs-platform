const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;
const ENVIRONMENT = process.env.ENVIRONMENT || 'unknown';
const startTime = Date.now();

let pool = null;
if (process.env.DB_CREDENTIALS) {
  try {
    const creds = JSON.parse(process.env.DB_CREDENTIALS);
    pool = new Pool({
      host: creds.host,
      port: creds.port,
      user: creds.username,
      password: creds.password,
      database: creds.dbname,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 3000,
    });
  } catch (err) {
    console.error('Failed to parse DB_CREDENTIALS:', err.message);
  }
}

function formatUptime(ms) {
  const s = Math.floor(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  return `${h}h ${m}m ${sec}s`;
}

app.get('/', async (req, res) => {
  let dbStatus = 'not configured';
  let dbTime = null;

  if (pool) {
    try {
      const result = await pool.query('SELECT NOW() as now');
      dbStatus = 'connected';
      dbTime = result.rows[0].now;
    } catch (err) {
      dbStatus = `error: ${err.message}`;
    }
  }

  const uptime = formatUptime(Date.now() - startTime);
  const statusColor = dbStatus === 'connected' ? '#22c55e' : dbStatus === 'not configured' ? '#94a3b8' : '#ef4444';

  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Enterprise Deployment Platform — ${ENVIRONMENT}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: #1e293b;
      border-radius: 16px;
      padding: 40px;
      max-width: 520px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0,0,0,0.4);
      border: 1px solid #334155;
    }
    .badge {
      display: inline-block;
      background: #3b82f6;
      color: white;
      padding: 4px 14px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 16px;
    }
    h1 { font-size: 22px; margin-bottom: 8px; color: #f8fafc; }
    p.sub { color: #94a3b8; font-size: 14px; margin-bottom: 28px; }
    .row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 14px 0;
      border-bottom: 1px solid #334155;
    }
    .row:last-child { border-bottom: none; }
    .label { color: #94a3b8; font-size: 14px; }
    .value { font-size: 14px; font-weight: 600; color: #f1f5f9; }
    .dot {
      display: inline-block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      margin-right: 8px;
      background: ${statusColor};
    }
    .footer { margin-top: 24px; font-size: 12px; color: #64748b; text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">${ENVIRONMENT}</span>
    <h1>Enterprise Multi-Environment Deployment Platform</h1>
    <p class="sub">ECS Fargate · Terraform + Terragrunt · AWS</p>

    <div class="row">
      <span class="label">Environment</span>
      <span class="value">${ENVIRONMENT}</span>
    </div>
    <div class="row">
      <span class="label"><span class="dot"></span>Database Status</span>
      <span class="value">${dbStatus}</span>
    </div>
    <div class="row">
      <span class="label">DB Server Time</span>
      <span class="value">${dbTime ? new Date(dbTime).toISOString() : '—'}</span>
    </div>
    <div class="row">
      <span class="label">App Uptime</span>
      <span class="value">${uptime}</span>
    </div>
    <div class="row">
      <span class="label">Hostname</span>
      <span class="value">${require('os').hostname()}</span>
    </div>

    <div class="footer">Served via ALB → ECS Fargate task</div>
  </div>
</body>
</html>`);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/status', async (req, res) => {
  let dbStatus = 'not configured';
  if (pool) {
    try {
      await pool.query('SELECT 1');
      dbStatus = 'connected';
    } catch (err) {
      dbStatus = `error: ${err.message}`;
    }
  }
  res.json({
    environment: ENVIRONMENT,
    dbStatus,
    uptimeMs: Date.now() - startTime,
    hostname: require('os').hostname(),
  });
});

app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});