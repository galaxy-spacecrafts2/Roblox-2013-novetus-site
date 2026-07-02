@echo off
REM Run as Administrator
cd /d C:\Roblox-2013-novetus-site

REM Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo Requesting Administrator privileges...
	powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
	exit /b
)

echo Running server on port 8080...
.\server.exe RobloxWebSite 8080

pause
