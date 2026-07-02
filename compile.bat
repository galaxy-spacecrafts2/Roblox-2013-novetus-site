@echo off
REM Compile MonoHost library
echo Compiling MonoHost.dll...
csc /target:library /r:System.Web.dll host.cs /out:MonoHost.dll

REM Copy to bin folder
echo Copying MonoHost.dll to RobloxWebSite\bin\
if not exist "RobloxWebSite\bin" mkdir RobloxWebSite\bin
copy MonoHost.dll RobloxWebSite\bin\MonoHost.dll

REM Compile the server executable
echo Compiling server.exe...
csc /r:System.Web.dll /r:MonoHost.dll program.cs /out:server.exe

echo Done! You can now run: server.exe
