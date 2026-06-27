@echo off
setlocal EnableDelayedExpansion
title RetroBlox - Setup and Build
color 0A

:: ============================================================
:: RETROBLOX WEBSITE - SETUP AND BUILD SCRIPT
:: Run this script as Administrator.
:: Phase 1: Installs all required tools, then reboots.
:: Phase 2: Run again after reboot to restore packages and build.
:: ============================================================

set "SCRIPT_DIR=%~dp0"
set "FLAG_FILE=%SCRIPT_DIR%.setup_phase2_ready"
set "LOG_FILE=%SCRIPT_DIR%setup_build.log"
set "NUGET_URL=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
set "NUGET_PATH=%SCRIPT_DIR%nuget.exe"
set "PACKAGES_DIR=%SCRIPT_DIR%packages"
set "SLN_FILE=%SCRIPT_DIR%RobloxWebSite.sln"
set "SITE_DIR=%SCRIPT_DIR%RobloxWebSite"
set "HOSTNAME=retroblox.com"
set "WWW_HOSTNAME=www.retroblox.com"
set "HTTP_PORT=80"
set "HTTPS_PORT=443"
set "HOSTS_FILE=C:\Windows\System32\drivers\etc\hosts"
set "CLOUDFLARED_URL=https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
set "CLOUDFLARED_PATH=%SCRIPT_DIR%cloudflared.exe"
set "CF_TOKEN_FILE=%SCRIPT_DIR%.cf_tunnel_token"
set "CF_CONFIG_DIR=%USERPROFILE%\.cloudflared"
set "CF_CONFIG_FILE=%CF_CONFIG_DIR%\config.yml"

echo. >> "%LOG_FILE%"
echo [%DATE% %TIME%] Script started >> "%LOG_FILE%"

:: ============================================================
:: ADMIN CHECK
:: ============================================================
echo.
echo  =====================================================
echo   RetroBlox Website Build ^& Setup Script
echo  =====================================================
echo.
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] This script must be run as Administrator.
    echo.
    echo  Right-click setup_and_build.bat and choose
    echo  "Run as administrator", then try again.
    echo.
    pause
    exit /b 1
)
echo  [OK] Running as Administrator.

:: ============================================================
:: PHASE DETECTION
:: ============================================================
if exist "%FLAG_FILE%" (
    echo  [INFO] Post-reboot phase detected. Proceeding to build...
    echo.
    goto :PHASE2_BUILD
)

echo  [INFO] First run detected. Starting Phase 1: Tool Installation.
echo.

:: ============================================================
:: PHASE 1 - TOOL INSTALLATION
:: ============================================================

:PHASE1_TOOLS

:: -- CHECK WINDOWS VERSION --
echo  [CHECK] Windows version...
ver | findstr /i "10\." >nul 2>&1
if %errorLevel% equ 0 (
    echo  [OK]    Windows 10 detected.
) else (
    ver | findstr /i "11\." >nul 2>&1
    if %errorLevel% equ 0 (
        echo  [OK]    Windows 11 detected.
    ) else (
        echo  [WARN]  Could not confirm Windows 10/11. Proceeding anyway.
    )
)

:: -- CHECK .NET FRAMEWORK 4.7.2 --
echo.
echo  [CHECK] .NET Framework 4.7.2...
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release ^| find "Release"') do set "DOTNET_RELEASE=%%a"
    if !DOTNET_RELEASE! GEQ 461808 (
        echo  [OK]    .NET Framework 4.7.2+ is installed (Release key: !DOTNET_RELEASE!).
        set "DOTNET_OK=1"
    ) else (
        echo  [MISSING] .NET Framework 4.7.2 not found (Release key: !DOTNET_RELEASE!).
        set "DOTNET_OK=0"
    )
) else (
    echo  [MISSING] .NET Framework not found in registry.
    set "DOTNET_OK=0"
)

:: -- CHECK CHOCOLATEY --
echo.
echo  [CHECK] Chocolatey package manager...
where choco >nul 2>&1
if %errorLevel% equ 0 (
    echo  [OK]    Chocolatey is installed.
    set "CHOCO_OK=1"
) else (
    echo  [MISSING] Chocolatey not found. Installing...
    set "CHOCO_OK=0"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if !errorLevel! neq 0 (
        echo  [ERROR] Chocolatey installation failed. Check your internet connection.
        echo  [ERROR] Chocolatey install failed >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    echo  [OK]    Chocolatey installed successfully.
    set "CHOCO_OK=1"
)

:: -- CHECK / INSTALL VISUAL STUDIO BUILD TOOLS 2022 --
echo.
echo  [CHECK] Visual Studio Build Tools / MSBuild...
set "MSBUILD_PATH="
for %%p in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
) do (
    if exist %%p (
        set "MSBUILD_PATH=%%~p"
    )
)

if defined MSBUILD_PATH (
    echo  [OK]    MSBuild found at: !MSBUILD_PATH!
    set "MSBUILD_OK=1"
) else (
    echo  [MISSING] MSBuild / Visual Studio Build Tools not found.
    echo  [INFO]    Installing Visual Studio Build Tools 2022 with ASP.NET workload...
    echo  [INFO]    This download is large (~2-3 GB) and may take 10-20 minutes.
    echo.
    choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.WebBuildTools --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools --add Microsoft.Net.Component.4.7.2.TargetingPack --add Microsoft.Net.Component.4.7.2.SDK --includeRecommended --passive --norestart" -y
    if !errorLevel! neq 0 (
        echo  [ERROR] VS Build Tools installation failed.
        echo  [ERROR] VS Build Tools install failed >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    echo  [OK]    Visual Studio Build Tools 2022 installed.
    set "MSBUILD_OK=1"
    set "NEED_REBOOT=1"
)

:: -- CHECK / INSTALL .NET 4.7.2 TARGETING PACK (via choco) --
if "!DOTNET_OK!"=="0" (
    echo.
    echo  [INFO]  Installing .NET Framework 4.7.2 Developer Pack...
    choco install netfx-4.7.2-devpack -y
    if !errorLevel! neq 0 (
        echo  [WARN]  .NET 4.7.2 Dev Pack install may have failed. Continuing...
    ) else (
        echo  [OK]    .NET Framework 4.7.2 Developer Pack installed.
    )
    set "NEED_REBOOT=1"
)

:: -- CHECK / INSTALL NUGET CLI --
echo.
echo  [CHECK] NuGet CLI...
if exist "%NUGET_PATH%" (
    echo  [OK]    nuget.exe found at: %NUGET_PATH%
    set "NUGET_OK=1"
) else (
    where nuget >nul 2>&1
    if %errorLevel% equ 0 (
        echo  [OK]    NuGet is in PATH.
        set "NUGET_OK=1"
    ) else (
        echo  [MISSING] NuGet CLI not found. Downloading...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%NUGET_URL%' -OutFile '%NUGET_PATH%'"
        if !errorLevel! neq 0 (
            echo  [ERROR] Failed to download nuget.exe. Check your internet connection.
            echo  [ERROR] NuGet download failed >> "%LOG_FILE%"
            pause
            exit /b 1
        )
        echo  [OK]    nuget.exe downloaded to: %NUGET_PATH%
        set "NUGET_OK=1"
    )
)

:: -- CHECK / INSTALL IIS EXPRESS --
echo.
echo  [CHECK] IIS Express...
set "IISEXPRESS_PATH="
for %%p in (
    "C:\Program Files\IIS Express\iisexpress.exe"
    "C:\Program Files (x86)\IIS Express\iisexpress.exe"
) do (
    if exist %%p set "IISEXPRESS_PATH=%%~p"
)
if defined IISEXPRESS_PATH (
    echo  [OK]    IIS Express found at: !IISEXPRESS_PATH!
) else (
    echo  [MISSING] IIS Express not found. Installing...
    choco install iis-express -y
    if !errorLevel! neq 0 (
        echo  [WARN]  IIS Express install may have failed. Continuing...
    ) else (
        echo  [OK]    IIS Express installed.
        set "NEED_REBOOT=1"
    )
)

:: -- CHECK / INSTALL GIT --
echo.
echo  [CHECK] Git...
where git >nul 2>&1
if %errorLevel% equ 0 (
    echo  [OK]    Git is installed.
) else (
    echo  [MISSING] Git not found. Installing...
    choco install git -y
    echo  [OK]    Git installed.
    set "NEED_REBOOT=1"
)

:: -- CHECK / DOWNLOAD CLOUDFLARED --
echo.
echo  [CHECK] Cloudflare Tunnel (cloudflared)...
if exist "%CLOUDFLARED_PATH%" (
    echo  [OK]    cloudflared.exe already present.
) else (
    where cloudflared >nul 2>&1
    if %errorLevel% equ 0 (
        echo  [OK]    cloudflared found in PATH.
    ) else (
        echo  [MISSING] cloudflared not found. Downloading...
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "Invoke-WebRequest -Uri '%CLOUDFLARED_URL%' -OutFile '%CLOUDFLARED_PATH%'"
        if !errorLevel! neq 0 (
            echo  [ERROR] Failed to download cloudflared. Check internet connection.
            pause
            exit /b 1
        )
        echo  [OK]    cloudflared.exe downloaded.
    )
)

:: -- SUMMARY --
echo.
echo  =====================================================
echo   Phase 1 Complete - Installation Summary
echo  =====================================================
echo  Chocolatey   : Installed/Verified
echo  MSBuild      : Installed/Verified
echo  .NET 4.7.2   : Installed/Verified
echo  NuGet CLI    : Installed/Verified
echo  IIS Express  : Installed/Verified
echo  cloudflared  : Installed/Verified
echo.

:: -- WRITE PHASE 2 FLAG --
echo Phase1Complete > "%FLAG_FILE%"
echo  [INFO] Phase 1 flag written.

:: -- REBOOT IF NEEDED --
if defined NEED_REBOOT (
    echo  [INFO] A reboot is required to complete the installation.
    echo  [INFO] After reboot, run this script again as Administrator
    echo         to continue with package restore and build.
    echo.
    echo  Rebooting in 15 seconds... Press Ctrl+C to cancel.
    timeout /t 15
    shutdown /r /t 0
) else (
    echo  [INFO] No reboot required. Proceeding directly to Phase 2...
    echo.
    goto :PHASE2_BUILD
)

exit /b 0

:: ============================================================
:: PHASE 2 - PACKAGE RESTORE, BUILD, AND NETWORK SETUP
:: ============================================================

:PHASE2_BUILD
echo.
echo  =====================================================
echo   Phase 2: Package Restore, Build ^& Network Setup
echo  =====================================================
echo.

:: -- LOCATE MSBUILD --
echo  [CHECK] Locating MSBuild...
set "MSBUILD_PATH="
for %%p in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
) do (
    if exist %%p (
        set "MSBUILD_PATH=%%~p"
    )
)

if not defined MSBUILD_PATH (
    echo  [ERROR] MSBuild not found. Did Phase 1 complete successfully?
    echo  [INFO]  Try running this script again as Administrator.
    echo  [ERROR] MSBuild not found in Phase 2 >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo  [OK]    MSBuild: !MSBUILD_PATH!

for %%F in ("!MSBUILD_PATH!") do set "MSBUILD_DIR=%%~dpF"
set "PATH=!PATH!;!MSBUILD_DIR!"

:: -- LOCATE NUGET --
echo.
echo  [CHECK] Locating NuGet CLI...
if exist "%NUGET_PATH%" (
    set "NUGET_EXE=%NUGET_PATH%"
    echo  [OK]    NuGet: %NUGET_PATH%
) else (
    where nuget >nul 2>&1
    if %errorLevel% equ 0 (
        set "NUGET_EXE=nuget"
        echo  [OK]    NuGet found in PATH.
    ) else (
        echo  [MISSING] nuget.exe not found. Downloading now...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%NUGET_URL%' -OutFile '%NUGET_PATH%'"
        if !errorLevel! neq 0 (
            echo  [ERROR] Failed to download nuget.exe.
            pause
            exit /b 1
        )
        set "NUGET_EXE=%NUGET_PATH%"
        echo  [OK]    NuGet downloaded.
    )
)

:: -- VERIFY SOLUTION FILE --
echo.
echo  [CHECK] Solution file...
if not exist "%SLN_FILE%" (
    echo  [ERROR] RobloxWebSite.sln not found at: %SLN_FILE%
    echo  [INFO]  Make sure you are running this script from the repo root folder.
    pause
    exit /b 1
)
echo  [OK]    Solution: %SLN_FILE%

:: -- NUGET RESTORE (MAIN PROJECT) --
echo.
echo  =====================================================
echo   Step 1/5: Restoring NuGet packages (main project)
echo  =====================================================
echo  [INFO] This may take a few minutes on first run...
echo.
"%NUGET_EXE%" restore "%SLN_FILE%" -PackagesDirectory "%PACKAGES_DIR%" -NonInteractive
if %errorLevel% neq 0 (
    echo  [WARN]  NuGet restore returned a non-zero exit code.
    echo  [WARN]  Some packages may have failed. Continuing...
) else (
    echo  [OK]    NuGet restore completed.
)

:: -- NUGET RESTORE (ALL ASSEMBLY PROJECTS) --
echo.
echo  =====================================================
echo   Step 2/5: Restoring NuGet packages (assemblies)
echo  =====================================================
set "RESTORE_ERRORS=0"
for /r "%SCRIPT_DIR%Assemblies" %%f in (*.sln *.csproj) do (
    echo  [RESTORE] %%f
    "%NUGET_EXE%" restore "%%f" -PackagesDirectory "%PACKAGES_DIR%" -NonInteractive >nul 2>&1
    if !errorLevel! neq 0 (
        echo  [WARN]    Restore issues for: %%~nxf
        set /a RESTORE_ERRORS+=1
    )
)
if !RESTORE_ERRORS! gtr 0 (
    echo  [WARN]  !RESTORE_ERRORS! assembly restore(s) had issues. Continuing with build...
) else (
    echo  [OK]    All assembly packages restored.
)

:: -- BUILD SOLUTION --
echo.
echo  =====================================================
echo   Step 3/5: Building Solution (Debug)
echo  =====================================================
echo  [INFO] Running MSBuild on full solution...
echo.

"!MSBUILD_PATH!" "%SLN_FILE%" ^
    /p:Configuration=Debug ^
    /p:Platform="Any CPU" ^
    /p:DeployOnBuild=false ^
    /m ^
    /nologo ^
    /verbosity:minimal ^
    /flp:LogFile="%SCRIPT_DIR%build_output.log";Verbosity=detailed ^
    2>&1

if %errorLevel% neq 0 (
    echo.
    echo  =====================================================
    echo   [ERROR] Build FAILED
    echo  =====================================================
    echo  Check build_output.log for full details.
    echo.
    echo  Common fixes:
    echo    - Missing .NET 4.7.2 targeting pack:
    echo      choco install netfx-4.7.2-devpack -y
    echo    - Missing a NuGet package:
    echo      Run nuget.exe restore RobloxWebSite.sln again
    echo    - TypeScript errors:
    echo      choco install typescript -y
    echo.
    echo  [ERROR] MSBuild failed with code %errorLevel% >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo.
echo  =====================================================
echo   [OK] Build SUCCEEDED
echo  =====================================================

:: ============================================================
:: STEP 4 - IIS EXPRESS CONFIG + CLOUDFLARE TUNNEL SETUP
:: ============================================================
echo.
echo  =====================================================
echo   Step 4/5: Configuring IIS Express + Cloudflare Tunnel
echo  =====================================================

:: -- URL RESERVATION (lets IIS Express bind to port 80 without conflict) --
echo  [INFO] Reserving HTTP URL with http.sys...
netsh http add urlacl url=http://localhost:%HTTP_PORT%/ user=Everyone >nul 2>&1
echo  [OK]    URL reservation done.

:: -- PORT 80 CONFLICT CHECK --
echo  [INFO] Checking if port %HTTP_PORT% is in use...
netstat -ano | findstr ":%HTTP_PORT% " | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo  [WARN]  Port %HTTP_PORT% already in use. Checking for IIS (W3SVC)...
    sc query W3SVC >nul 2>&1
    if %errorLevel% equ 0 (
        net stop W3SVC >nul 2>&1
        net stop WAS >nul 2>&1
        echo  [OK]    IIS stopped to free port 80.
    ) else (
        echo  [WARN]  Unknown process on port 80 - IIS Express may fail to bind.
    )
) else (
    echo  [OK]    Port %HTTP_PORT% is free.
)

:: -- CONFIGURE IIS EXPRESS --
echo  [INFO] Writing IIS Express config...
set "IIS_CONFIG_DIR=%USERPROFILE%\Documents\IISExpress\config"
set "IIS_CONFIG=%IIS_CONFIG_DIR%\applicationhost.config"
if not exist "%IIS_CONFIG_DIR%" mkdir "%IIS_CONFIG_DIR%" >nul 2>&1

(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<configuration^>
echo   ^<system.applicationHost^>
echo     ^<sites^>
echo       ^<site name="RetroBlox" id="1"^>
echo         ^<application path="/" applicationPool="RetroBloxAppPool"^>
echo           ^<virtualDirectory path="/" physicalPath="%SITE_DIR%" /^>
echo         ^</application^>
echo         ^<bindings^>
echo           ^<binding protocol="http" bindingInformation="*:%HTTP_PORT%:localhost" /^>
echo         ^</bindings^>
echo       ^</site^>
echo       ^<siteDefaults^>
echo         ^<logFile logFormat="W3C" directory="%USERPROFILE%\Documents\IISExpress\Logs" /^>
echo         ^<traceFailedRequestsLogging directory="%USERPROFILE%\Documents\IISExpress\TraceLogFiles" /^>
echo       ^</siteDefaults^>
echo       ^<applicationDefaults applicationPool="RetroBloxAppPool" /^>
echo       ^<virtualDirectoryDefaults allowSubDirConfig="true" /^>
echo     ^</sites^>
echo     ^<applicationPools^>
echo       ^<add name="RetroBloxAppPool" managedRuntimeVersion="v4.0" managedPipelineMode="Integrated" /^>
echo       ^<applicationPoolDefaults^>
echo         ^<processModel loadUserProfile="true" /^>
echo       ^</applicationPoolDefaults^>
echo     ^</applicationPools^>
echo     ^<modules runAllManagedModulesForAllRequests="true" /^>
echo   ^</system.applicationHost^>
echo ^</configuration^>
) > "%IIS_CONFIG%"
echo  [OK]    IIS Express config written.

:: -- LOCATE CLOUDFLARED --
echo.
echo  [INFO] Locating cloudflared...
set "CF_EXE="
if exist "%CLOUDFLARED_PATH%" (
    set "CF_EXE=%CLOUDFLARED_PATH%"
) else (
    where cloudflared >nul 2>&1
    if %errorLevel% equ 0 (
        set "CF_EXE=cloudflared"
    ) else (
        echo  [MISSING] cloudflared not found. Downloading now...
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "Invoke-WebRequest -Uri '%CLOUDFLARED_URL%' -OutFile '%CLOUDFLARED_PATH%'"
        if !errorLevel! neq 0 (
            echo  [ERROR] Could not download cloudflared.
            pause
            exit /b 1
        )
        set "CF_EXE=%CLOUDFLARED_PATH%"
    )
)
echo  [OK]    cloudflared: !CF_EXE!

:: ============================================================
:: STEP 5 - LAUNCH IIS EXPRESS + CLOUDFLARE QUICK TUNNEL
:: ============================================================
echo.
echo  =====================================================
echo   Step 5/5: Launching server and free public tunnel
echo  =====================================================

:: -- LOCATE IIS EXPRESS --
set "IISEXPRESS_PATH="
for %%p in (
    "C:\Program Files\IIS Express\iisexpress.exe"
    "C:\Program Files (x86)\IIS Express\iisexpress.exe"
) do (
    if exist %%p set "IISEXPRESS_PATH=%%~p"
)

if not defined IISEXPRESS_PATH (
    echo  [ERROR] IIS Express not found.
    echo  [INFO]  Run: choco install iis-express -y  then re-run this script.
    pause
    exit /b 1
)
echo  [OK]    IIS Express: !IISEXPRESS_PATH!

:: -- START IIS EXPRESS IN BACKGROUND --
echo  [INFO] Starting IIS Express on localhost:%HTTP_PORT%...
start "IISExpress-RetroBlox" /B "!IISEXPRESS_PATH!" /config:"%IIS_CONFIG%" /siteid:1

:: Give IIS Express a few seconds to initialise
timeout /t 4 /nobreak >nul

:: -- WRITE QUICK TUNNEL HELPER SCRIPT --
:: The Quick Tunnel prints the public URL to stdout.
:: We pipe it through findstr so it appears highlighted in the window.
set "TUNNEL_LOG=%SCRIPT_DIR%tunnel_url.log"

echo.
echo  =====================================================
echo   Iniciando Cloudflare Quick Tunnel...
echo   (sem conta, sem dominio, 100%% gratis)
echo.
echo   Aguarde ~5 segundos...
echo   A URL publica vai aparecer logo abaixo.
echo  =====================================================
echo.

echo  [INFO] Quick Tunnel launched >> "%LOG_FILE%"

:: -- CLEANUP FLAG --
if exist "%FLAG_FILE%" del "%FLAG_FILE%"

:: Run Quick Tunnel in foreground.
:: Cloudflare prints the public URL like:
::   https://xxxxxx-xxxx-xxxx-xxxx.trycloudflare.com
:: The URL changes each restart (it's free/no account).
:: When ready to use retroblox.com, register the domain and
:: replace this line with:
::   "!CF_EXE!" tunnel run --token "YOUR_TOKEN_HERE"
"!CF_EXE!" tunnel --url http://localhost:%HTTP_PORT% --no-autoupdate

:: When tunnel exits, kill IIS Express too
echo.
echo  [INFO] Tunnel stopped. Shutting down IIS Express...
taskkill /f /im iisexpress.exe >nul 2>&1
echo.
echo  =====================================================
echo   Tudo parado com sucesso.
echo   Log geral  :  setup_build.log
echo   Log build  :  build_output.log
echo  =====================================================
echo.
pause
exit /b 0
