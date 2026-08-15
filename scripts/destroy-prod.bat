@echo off
setlocal enabledelayedexpansion
echo ============================================
echo   DESTROY PROD — billable resources only
echo   (iam / ecr / storage are left running — free)
echo ============================================
echo.
set /p CONFIRM="Type YES to destroy PROD's networking/database/ecs-service/monitoring/notifications: "
if /i not "%CONFIRM%"=="YES" (
    echo Aborted — nothing was destroyed.
    exit /b 0
)

set ROOT=%~dp0..
set ENV_DIR=%ROOT%\terragrunt\prod

for %%M in (notifications monitoring ecs-service database networking) do (
    echo.
    echo --------------------------------------------
    echo   Destroying: %%M
    echo --------------------------------------------
    pushd "%ENV_DIR%\%%M"
    call terragrunt destroy -auto-approve
    if errorlevel 1 (
        echo.
        echo [FAILED] Module %%M failed to destroy. Stopping here.
        echo Check the error above before continuing manually.
        popd
        exit /b 1
    )
    popd
)

echo.
echo ============================================
echo   PROD TEARDOWN COMPLETE
echo   (iam, ecr, storage still running — free tier)
echo ============================================
endlocal
