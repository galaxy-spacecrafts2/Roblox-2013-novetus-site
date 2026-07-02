@echo off
REM Run server with admin privileges
cd /d C:\Roblox-2013-novetus-site

REM Create a temporary VBScript to run with elevation
set "VBScript=%temp%\elevate.vbs"
(
echo Set oShell = CreateObject("Shell.Application"
echo oShell.ShellExecute "cmd.exe", "/c cd /d C:\Roblox-2013-novetus-site ^& .\server.exe RobloxWebSite 8080", "", "runas", 1
) > "%VBScript%"

cscript "%VBScript%"
del "%VBScript%"
