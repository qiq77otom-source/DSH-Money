@echo off
setlocal EnableExtensions
chcp 936 >nul
set "SELF=%~f0"
set "TARGET=%~dp0"
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"

if defined DSH_UNINSTALL_TEST goto skip_confirm
echo.
echo 即将彻底删除 DeepSeek 余额悬浮窗：
echo   程序目录：%TARGET%
echo   计划任务：DeepSeekBalanceFloat
echo.
echo   旧版备份：%USERPROFILE%\Documents\dsh余额_旧版Python备份
echo 警告：正式运行时不可恢复，请备份好你的API Key。
choice /c YN /n /m "确认删除？[Y/N] "
if errorlevel 2 exit /b 0
:skip_confirm

if /i "%~1"=="--elevated" goto elevated

set "STAGE=%TEMP%\dsh_uninstall_%RANDOM%%RANDOM%.cmd"
copy /y "%SELF%" "%STAGE%" >nul
if errorlevel 1 (
  echo 无法创建临时清理脚本。
  pause
  exit /b 1
)
set "DSH_UNINSTALL_DIR=%TARGET%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:ComSpec -ArgumentList '/c', $env:STAGE, '--elevated' -Verb RunAs"
if errorlevel 1 del /f /q "%STAGE%" >nul 2>&1
exit /b 0

:elevated
set "TARGET=%DSH_UNINSTALL_DIR%"
if "%TARGET%"=="" goto fail
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"
if /i "%TARGET%"=="%TEMP%" goto fail
if not exist "%TARGET%\DeepSeek余额悬浮窗.exe" if not exist "%TARGET%\config.ini" goto fail

cd /d "%TEMP%"
ping 127.0.0.1 -n 3 >nul

if not defined DSH_UNINSTALL_TEST (
  taskkill /f /im "DeepSeek余额悬浮窗.exe" >nul 2>&1
  schtasks /delete /tn "DeepSeekBalanceFloat" /f >nul 2>&1
  del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\DeepSeek余额悬浮窗.bat" >nul 2>&1
  del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\DeepSeek余额悬浮窗.lnk" >nul 2>&1
  del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\余额悬浮窗.lnk" >nul 2>&1
  del /f /q "%TEMP%\DeepSeekBalanceFloat-autostart.log" >nul 2>&1
)
ping 127.0.0.1 -n 3 >nul

rd /s /q "%TARGET%" >nul 2>&1
if exist "%TARGET%" (
  echo.
  echo 删除未完成，可能有文件正在使用。
  echo 请关闭程序后重试：%TARGET%
  pause
  exit /b 1
)
if not defined DSH_UNINSTALL_TEST rd /s /q "%USERPROFILE%\Documents\dsh余额_旧版Python备份" >nul 2>&1
echo.
echo 已彻底清理。
ping 127.0.0.1 -n 3 >nul
(goto) 2>nul & del /f /q "%~f0" >nul 2>&1
exit /b 0

:fail
echo.
echo 清理已中止：目标目录无效或程序文件不存在。
echo 目标：%TARGET%
pause
exit /b 1
