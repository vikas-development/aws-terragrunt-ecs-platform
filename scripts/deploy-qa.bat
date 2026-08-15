@echo off
setlocal enabledelayedexpansion
echo ============================================
echo   DEPLOY QA — full stack, in order
echo ============================================

set ROOT=%~dp0..
set ENV_DIR=%ROOT%\terragrunt\qa

for %%M in (networking iam ecr database ecs-service monitoring notifications) do (
    echo.
    echo --------------------------------------------
    echo   Applying: %%M
    echo --------------------------------------------
    pushd "%ENV_DIR%\%%M"
    call terragrunt apply -auto-approve
    if errorlevel 1 (
        echo.
        echo [FAILED] Module %%M failed to apply. Stopping here.
        echo Fix the error above, then re-run this script — already-applied
        echo modules will show "no changes" and be skipped over quickly.
        popd
        exit /b 1
    )
    popd
)

echo.
echo ============================================
echo   QA DEPLOY COMPLETE
echo ============================================
echo.
echo Verifying app health...
pushd "%ENV_DIR%\ecs-service"
for /f "delims=" %%D in ('terragrunt output -raw alb_dns_name') do set ALB_DNS=%%D
popd
echo ALB DNS: %ALB_DNS%
curl -s http://%ALB_DNS%/health
echo.
echo.
echo Refreshing dashboard data (fetch-status.js)...
pushd "%ROOT%"
node fetch-status.js qa
popd

echo.
echo Done. Open platform-status.html (via http-server) to see live data.
endlocal
