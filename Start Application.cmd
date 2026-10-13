@echo off
cd /d "%~dp0"
echo.
echo  Welcome to the Application Delivery Assistant! Starting up, this takes a few seconds...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0StartAssistant.ps1"
