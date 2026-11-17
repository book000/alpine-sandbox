@echo off
setlocal DisableDelayedExpansion
set "datadir=%~dp0data"
set "attempts=0"

:allocate
set /a attempts+=1
if %attempts% GTR 100 exit /b 1
set "session=%datadir%\%random%-%random%"
mkdir "%session%" 2>nul
if errorlevel 1 goto allocation_failed
set "workdir=%session%\work"
set "logdir=%session%\logs"
mkdir "%workdir%"
if errorlevel 1 exit /b %errorlevel%
mkdir "%logdir%"
if errorlevel 1 exit /b %errorlevel%

docker build --tag alpine-sandbox:1.0 .
if errorlevel 1 exit /b %errorlevel%
docker run -it --rm -v "%logdir%:/logs" -v "%workdir%:/work" alpine-sandbox:1.0
exit /b %errorlevel%

:allocation_failed
set "result=%errorlevel%"
if exist "%session%" goto allocate
exit /b %result%
