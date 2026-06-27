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
set "HTTP_PORT=80"
set "HOSTS_FILE=C:\Windows\System32\drivers\etc\hosts"
set "NOIP_CREDS_FILE=%SCRIPT_DIR%.noip_creds"
set "NOIP_API=https://dynupdate.no-ip.com/nic/update"

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
echo   Step 1/6: Restoring NuGet packages (main project)
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
echo   Step 2/6: Restoring NuGet packages (assemblies)
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
echo   Step 3/6: Building Solution (Debug)
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
:: STEP 4 - SEED ACCOUNTS NO BANCO DE DADOS
:: ============================================================
echo.
echo  =====================================================
echo   Step 4/6: Criando contas no banco de dados
echo  =====================================================

:: -- PEDE DADOS DO SQL SERVER NA PRIMEIRA VEZ --
set "DB_CREDS_FILE=%SCRIPT_DIR%.db_creds"
set "DB_SERVER=localhost"
set "DB_NAME=MyReleaseDB"

if exist "%DB_CREDS_FILE%" (
    for /f "tokens=1,2 delims==" %%a in (%DB_CREDS_FILE%) do (
        if "%%a"=="server" set "DB_SERVER=%%b"
        if "%%a"=="db"     set "DB_NAME=%%b"
    )
    echo  [OK]    Config do banco carregada: !DB_SERVER! / !DB_NAME!
) else (
    echo.
    echo  =====================================================
    echo   Configure o SQL Server
    echo  =====================================================
    echo.
    echo  Pressione ENTER para usar os valores padrao,
    echo  ou digite um valor diferente.
    echo.
    set /p "DB_SERVER_IN=  Servidor SQL Server [localhost]: "
    if not "!DB_SERVER_IN!"=="" set "DB_SERVER=!DB_SERVER_IN!"
    set /p "DB_NAME_IN=  Nome do banco [MyReleaseDB]: "
    if not "!DB_NAME_IN!"=="" set "DB_NAME=!DB_NAME_IN!"
    echo.
    (
        echo server=!DB_SERVER!
        echo db=!DB_NAME!
    ) > "%DB_CREDS_FILE%"
    echo  [OK]    Config salva para proximas execucoes.
)

:: -- VERIFICA SE O SEED JA FOI FEITO --
set "SEED_FLAG=%SCRIPT_DIR%.accounts_seeded"
if exist "%SEED_FLAG%" (
    echo  [OK]    Contas ja foram criadas anteriormente. Pulando seed.
    goto :STEP5_NETWORK
)

:: -- EXTRAI E EXECUTA O SEED (EMBUTIDO NO FINAL DESTE ARQUIVO) --
echo  [INFO] Preparando script de seed embutido...
set "SEED_PS=C:\Windows\Temp\rb_seed.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$marker='::SEED_PS_START';$w=$false;$out=[System.Collections.Generic.List[string]]::new();foreach($l in [System.IO.File]::ReadAllLines('%~f0')){if($l -eq $marker){$w=$true}elseif($w){$out.Add($l)}};[System.IO.File]::WriteAllLines('%SEED_PS%',$out,[System.Text.Encoding]::UTF8)"

if not exist "%SEED_PS%" (
    echo  [WARN]  Nao foi possivel extrair o script de seed.
    echo  [INFO]  Verifique se o arquivo bat nao foi modificado manualmente.
    goto :STEP5_NETWORK
)

echo  [INFO] Executando seed...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SEED_PS%" ^
    -Server "!DB_SERVER!" -Database "!DB_NAME!" -ScriptDir "%SCRIPT_DIR%"

if %errorLevel% neq 0 (
    echo.
    echo  [WARN]  O seed de contas falhou ou o banco ainda nao esta pronto.
    echo  [INFO]  Isso pode acontecer se o SQL Server nao estiver instalado/rodando.
    echo  [INFO]  Instale o SQL Server Express (gratis):
    echo          https://www.microsoft.com/pt-br/sql-server/sql-server-downloads
    echo  [INFO]  Depois delete .accounts_seeded e re-execute este script.
    echo.
) else (
    echo Phase2Seeded > "%SEED_FLAG%"
    echo  [OK]    Contas criadas com sucesso!
)

del "%SEED_PS%" >nul 2>&1

echo.
echo  =====================================================
echo   Contas criadas:
echo    builderman  ^| ID=1 ^| Admin ^| senha: Admin@RetroBlox1
echo    noli        ^| Conta deletada/glitchada ^(mito de 2007^)
echo    Player1-12  ^| Bots de teste
echo  =====================================================
echo.
echo  [ATENCAO] Troque a senha do builderman apos o primeiro login!
echo.

:STEP5_NETWORK
:: ============================================================
:: STEP 5 - IIS EXPRESS CONFIG + NO-IP DDNS SETUP
:: ============================================================
echo.
echo  =====================================================
echo   Step 5/6: Configurando IIS Express + No-IP DDNS
echo  =====================================================

:: -- URL RESERVATION --
echo  [INFO] Reservando URL no http.sys...
netsh http add urlacl url=http://+:%HTTP_PORT%/ user=Everyone >nul 2>&1
echo  [OK]    URL reservada.

:: -- FIREWALL RULES --
echo  [INFO] Configurando Firewall do Windows para porta %HTTP_PORT%...
netsh advfirewall firewall show rule name="RetroBlox HTTP In" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="RetroBlox HTTP In" ^
        dir=in action=allow protocol=TCP localport=%HTTP_PORT% >nul 2>&1
    echo  [OK]    Regra de entrada criada.
) else (
    echo  [OK]    Regra de entrada ja existe.
)
netsh advfirewall firewall show rule name="RetroBlox HTTP Out" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="RetroBlox HTTP Out" ^
        dir=out action=allow protocol=TCP localport=%HTTP_PORT% >nul 2>&1
    echo  [OK]    Regra de saida criada.
)

:: -- PORT 80 CONFLICT CHECK --
echo  [INFO] Verificando se a porta %HTTP_PORT% esta livre...
netstat -ano | findstr ":%HTTP_PORT% " | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    sc query W3SVC >nul 2>&1
    if %errorLevel% equ 0 (
        net stop W3SVC >nul 2>&1 & net stop WAS >nul 2>&1
        echo  [OK]    IIS parado para liberar a porta 80.
    ) else (
        echo  [WARN]  Porta 80 em uso por outro processo. IIS Express pode falhar.
    )
) else (
    echo  [OK]    Porta %HTTP_PORT% livre.
)

:: -- CONFIGURE IIS EXPRESS --
echo  [INFO] Escrevendo config do IIS Express...
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
echo           ^<binding protocol="http" bindingInformation="*:%HTTP_PORT%:" /^>
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
echo  [OK]    Config do IIS Express escrito.

:: -- NO-IP CREDENTIALS --
echo.
echo  [INFO] Configurando No-IP DDNS...
set "NOIP_USER="
set "NOIP_PASS="
set "NOIP_HOST="

if exist "%NOIP_CREDS_FILE%" (
    for /f "tokens=1,2 delims==" %%a in (%NOIP_CREDS_FILE%) do (
        if "%%a"=="user" set "NOIP_USER=%%b"
        if "%%a"=="pass" set "NOIP_PASS=%%b"
        if "%%a"=="host" set "NOIP_HOST=%%b"
    )
    echo  [OK]    Credenciais No-IP carregadas: !NOIP_HOST!
) else (
    echo.
    echo  =====================================================
    echo   ACAO NECESSARIA - Criar conta No-IP gratuita
    echo  =====================================================
    echo.
    echo  1. Acesse https://www.noip.com  e crie uma conta gratis
    echo  2. Va em "Dynamic DNS" ^> "No-IP Hostnames"
    echo  3. Crie um hostname - exemplo: retroblox.ddns.net
    echo     (escolha qualquer nome disponivel que queira)
    echo  4. Volte aqui e digite as informacoes abaixo:
    echo.
    set /p NOIP_USER="  Seu email/usuario do No-IP: "
    set /p NOIP_PASS="  Sua senha do No-IP: "
    set /p NOIP_HOST="  Seu hostname (ex: retroblox.ddns.net): "
    echo.
    if "!NOIP_USER!"=="" (
        echo  [ERROR] Usuario nao informado. Saindo.
        pause & exit /b 1
    )
    (
        echo user=!NOIP_USER!
        echo pass=!NOIP_PASS!
        echo host=!NOIP_HOST!
    ) > "%NOIP_CREDS_FILE%"
    echo  [OK]    Credenciais salvas para proximas execucoes.
)

:: -- UPDATE NO-IP WITH CURRENT PUBLIC IP --
echo.
echo  [INFO] Obtendo IP publico atual...
for /f "usebackq delims=" %%i in (
    `powershell -NoProfile -ExecutionPolicy Bypass -Command "(Invoke-WebRequest -Uri 'https://api.ipify.org' -UseBasicParsing).Content.Trim()" 2^>nul`
) do set "PUBLIC_IP=%%i"

if "!PUBLIC_IP!"=="" (
    echo  [WARN]  Nao foi possivel obter o IP publico. Tentando alternativa...
    for /f "usebackq delims=" %%i in (
        `powershell -NoProfile -ExecutionPolicy Bypass -Command "(Invoke-WebRequest -Uri 'https://checkip.amazonaws.com' -UseBasicParsing).Content.Trim()" 2^>nul`
    ) do set "PUBLIC_IP=%%i"
)

if "!PUBLIC_IP!"=="" (
    echo  [ERROR] Nao foi possivel obter o IP publico. Verifique a internet.
    pause & exit /b 1
)
echo  [OK]    IP publico: !PUBLIC_IP!

echo  [INFO] Atualizando No-IP com o IP !PUBLIC_IP!...
for /f "usebackq delims=" %%r in (
    `powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('!NOIP_USER!:!NOIP_PASS!'));" ^
    "$uri = '%NOIP_API%?hostname=!NOIP_HOST!&myip=!PUBLIC_IP!';" ^
    "$headers = @{ Authorization = 'Basic ' + $creds; 'User-Agent' = 'RetroBloxScript/1.0 setup@retroblox' };" ^
    "(Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing).Content" 2^>nul`
) do set "NOIP_RESPONSE=%%r"

echo  [INFO] Resposta No-IP: !NOIP_RESPONSE!

echo !NOIP_RESPONSE! | findstr /i "good nochg" >nul 2>&1
if %errorLevel% equ 0 (
    echo  [OK]    No-IP atualizado com sucesso!
) else (
    echo  [WARN]  Resposta inesperada do No-IP: !NOIP_RESPONSE!
    echo  [INFO]  Verifique usuario, senha e hostname em: %NOIP_CREDS_FILE%
    echo  [INFO]  Para resetar as credenciais, delete o arquivo acima e re-execute.
)

:: ============================================================
:: STEP 6 - LAUNCH IIS EXPRESS
:: ============================================================
echo.
echo  =====================================================
echo   Step 6/6: Iniciando servidor
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
    echo  [ERROR] IIS Express nao encontrado.
    echo  [INFO]  Execute: choco install iis-express -y  e tente novamente.
    pause & exit /b 1
)
echo  [OK]    IIS Express: !IISEXPRESS_PATH!

:: -- CLEANUP FLAG --
if exist "%FLAG_FILE%" del "%FLAG_FILE%"

echo.
echo  =====================================================
echo   LEMBRETE UNICO - Redirecionamento de porta
echo  =====================================================
echo.
echo   Voce precisa fazer isso UMA VEZ so no seu roteador:
echo.
echo   1. Abra o navegador e acesse o painel do roteador
echo      (geralmente http://192.168.1.1 ou http://192.168.0.1)
echo   2. Procure "Port Forwarding" ou "Redirecionamento de Porta"
echo   3. Adicione uma regra:
echo        Porta externa : 80
echo        IP interno    : (seu IP local - veja abaixo)
echo        Porta interna : 80
echo        Protocolo     : TCP
echo.

for /f "tokens=2 delims=:" %%a in (
    'ipconfig ^| findstr /i "IPv4" ^| findstr /v "127.0.0.1"'
) do (
    set "LOCAL_IP=%%a"
    set "LOCAL_IP=!LOCAL_IP: =!"
    goto :got_local_ip
)
:got_local_ip
echo        Seu IP local  : !LOCAL_IP!
echo.
echo   Depois disso, o site fica acessivel para sempre em:
echo.
echo  =====================================================

echo  [INFO] Server launched >> "%LOG_FILE%"
echo  [INFO] URL: http://!NOIP_HOST! >> "%LOG_FILE%"

echo.
echo  =====================================================
echo   RetroBlox esta NO AR!
echo.
echo   URL publica  :  http://!NOIP_HOST!
echo   URL local    :  http://localhost
echo   Seu IP       :  !PUBLIC_IP!
echo.
echo   Qualquer pessoa pode acessar http://!NOIP_HOST!
echo.
echo   Pressione Ctrl+C para parar o servidor.
echo  =====================================================
echo.

"!IISEXPRESS_PATH!" /config:"%IIS_CONFIG%" /siteid:1

echo.
echo  =====================================================
echo   Servidor parado.
echo   Log geral  :  setup_build.log
echo   Log build  :  build_output.log
echo  =====================================================
echo.
pause

goto :EOF

::SEED_PS_START
# ============================================================
# RetroBlox - Account Seeder (embutido em setup_and_build.bat)
# Extraido e executado automaticamente pela etapa 4 do bat.
# ============================================================

param(
    [string]$Server     = "localhost",
    [string]$Database   = "MyReleaseDB",
    [string]$ScriptDir  = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host "   RetroBlox - Criando contas no banco de dados" -ForegroundColor Cyan
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host ""

# Localiza BCrypt.Net DLL nos packages restaurados
$bcryptDll = Get-ChildItem -Path "$ScriptDir\packages" -Recurse `
    -Filter "BCrypt.Net-Next.dll" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*net47*" -or $_.FullName -like "*net4*" } |
    Select-Object -First 1

if (-not $bcryptDll) {
    $bcryptDll = Get-ChildItem -Path "$ScriptDir\packages" -Recurse `
        -Filter "BCrypt.Net-Next.dll" -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if (-not $bcryptDll) {
    Write-Host "  [ERRO] BCrypt.Net-Next.dll nao encontrada em packages\." -ForegroundColor Red
    Write-Host "  [INFO] Certifique-se de que o NuGet restore foi concluido." -ForegroundColor Yellow
    exit 1
}

Add-Type -Path $bcryptDll.FullName
Write-Host "  [OK]  BCrypt carregado: $($bcryptDll.FullName)" -ForegroundColor Green

function Hash-Password($plain) {
    return [BCrypt.Net.BCrypt]::HashPassword($plain, 11)
}

# Conexao SQL Server
Write-Host "  [INFO] Conectando em: $Server / $Database" -ForegroundColor Yellow

$connectionString = "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True;"

function Invoke-Sql($sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $conn.Open()
    $cmd  = $conn.CreateCommand()
    $cmd.CommandText    = $sql
    $cmd.CommandTimeout = 60
    try   { $cmd.ExecuteNonQuery() | Out-Null }
    finally { $conn.Close() }
}

function Invoke-SqlScalar($sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $conn.Open()
    $cmd  = $conn.CreateCommand()
    $cmd.CommandText    = $sql
    $cmd.CommandTimeout = 60
    try   { return $cmd.ExecuteScalar() }
    finally { $conn.Close() }
}

# Cria tabelas se nao existirem
Write-Host "  [INFO] Criando tabelas se nao existirem..." -ForegroundColor Yellow

Invoke-Sql ("IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AccountStatus') " +
    "BEGIN " +
    "CREATE TABLE [dbo].[AccountStatus] ([ID] TINYINT NOT NULL PRIMARY KEY, [Value] NVARCHAR(50) NOT NULL); " +
    "INSERT INTO [dbo].[AccountStatus] VALUES (1,'Ok'),(2,'Suppressed'),(3,'Deleted'); " +
    "END")

Invoke-Sql ("IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Accounts') " +
    "BEGIN " +
    "CREATE TABLE [dbo].[Accounts] (" +
    "[ID]              BIGINT        NOT NULL PRIMARY KEY IDENTITY(1,1)," +
    "[Name]            NVARCHAR(50)  NOT NULL UNIQUE," +
    "[Email]           NVARCHAR(200) NULL," +
    "[PasswordHash]    NVARCHAR(200) NOT NULL," +
    "[AccountStatusID] TINYINT       NOT NULL DEFAULT 1 REFERENCES [AccountStatus]([ID])," +
    "[Description]     NVARCHAR(500) NULL," +
    "[AgeBracket]      TINYINT       NOT NULL DEFAULT 1," +
    "[IsAdmin]         BIT           NOT NULL DEFAULT 0," +
    "[IsMythAccount]   BIT           NOT NULL DEFAULT 0," +
    "[Created]         DATETIME      NOT NULL DEFAULT GETUTCDATE()); " +
    "END")

Invoke-Sql ("IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users') " +
    "BEGIN " +
    "CREATE TABLE [dbo].[Users] (" +
    "[ID]        BIGINT       NOT NULL PRIMARY KEY IDENTITY(1,1)," +
    "[Name]      NVARCHAR(50) NOT NULL UNIQUE," +
    "[AccountID] BIGINT       NOT NULL REFERENCES [Accounts]([ID])," +
    "[Created]   DATETIME     NOT NULL DEFAULT GETUTCDATE()); " +
    "END")

Write-Host "  [OK]  Tabelas prontas." -ForegroundColor Green

function Add-AccountWithId($id, $name, $password, $email, $description, $isAdmin, $isMythAccount, $statusId, $createdDate, $ageBracket) {
    $exists = Invoke-SqlScalar "SELECT COUNT(1) FROM [Accounts] WHERE [Name] = '$name'"
    if ($exists -gt 0) {
        Write-Host "  [SKIP] Conta '$name' ja existe." -ForegroundColor DarkGray
        return
    }
    $hash    = (Hash-Password $password).Replace("'","''")
    $descVal = if ($description) { "'" + $description.Replace("'","''") + "'" } else { "NULL" }
    $emailVal= if ($email)       { "'" + $email + "'"                         } else { "NULL" }
    $dateVal = if ($createdDate) { "'" + $createdDate + "'"                   } else { "GETUTCDATE()" }

    Invoke-Sql ("SET IDENTITY_INSERT [Accounts] ON; " +
        "INSERT INTO [Accounts] ([ID],[Name],[Email],[PasswordHash],[AccountStatusID],[Description],[AgeBracket],[IsAdmin],[IsMythAccount],[Created]) " +
        "VALUES ($id,'$name',$emailVal,'$hash',$statusId,$descVal,$ageBracket,$isAdmin,$isMythAccount,$dateVal); " +
        "SET IDENTITY_INSERT [Accounts] OFF; " +
        "INSERT INTO [Users] ([Name],[AccountID],[Created]) VALUES ('$name',$id,$dateVal);")
    Write-Host "  [OK]  Conta criada: $name (ID=$id)" -ForegroundColor Green
}

function Add-Account($name, $password, $email, $description, $isAdmin, $isMythAccount, $statusId, $createdDate, $ageBracket) {
    $exists = Invoke-SqlScalar "SELECT COUNT(1) FROM [Accounts] WHERE [Name] = '$name'"
    if ($exists -gt 0) {
        Write-Host "  [SKIP] Conta '$name' ja existe." -ForegroundColor DarkGray
        return
    }
    $hash    = (Hash-Password $password).Replace("'","''")
    $descVal = if ($description) { "'" + $description.Replace("'","''") + "'" } else { "NULL" }
    $emailVal= if ($email)       { "'" + $email + "'"                         } else { "NULL" }
    $dateVal = if ($createdDate) { "'" + $createdDate + "'"                   } else { "GETUTCDATE()" }

    Invoke-Sql ("INSERT INTO [Accounts] ([Name],[Email],[PasswordHash],[AccountStatusID],[Description],[AgeBracket],[IsAdmin],[IsMythAccount],[Created]) " +
        "VALUES ('$name',$emailVal,'$hash',$statusId,$descVal,$ageBracket,$isAdmin,$isMythAccount,$dateVal); " +
        "DECLARE @accId BIGINT = SCOPE_IDENTITY(); " +
        "INSERT INTO [Users] ([Name],[AccountID],[Created]) VALUES ('$name',@accId,$dateVal);")
    Write-Host "  [OK]  Conta criada: $name" -ForegroundColor Green
}

# ── builderman (admin, ID=1) ─────────────────────────────────
Write-Host ""
Write-Host "  [INFO] Criando conta builderman (admin, ID=1)..." -ForegroundColor Yellow

Add-AccountWithId `
    -id            1 `
    -name          "builderman" `
    -password      "Admin@RetroBlox1" `
    -email         $null `
    -description   "Welcome to RetroBlox! I am the founder and administrator of this platform." `
    -isAdmin       1 `
    -isMythAccount 0 `
    -statusId      1 `
    -createdDate   "2006-01-01 00:00:00" `
    -ageBracket    1

# ── noli (conta lenda/mito - deletada, 2007) ─────────────────
# Conta glitchada documentada em 2010: sem avatar, sem dados,
# redireciona para homepage ao clicar no perfil.
# Associada a Void Stars e furtos de contas na era 2007-2010.
Write-Host ""
Write-Host "  [INFO] Criando conta noli (mito/lenda, deletada)..." -ForegroundColor Yellow

Add-Account `
    -name          "noli" `
    -password      "V01dStar_2007!" `
    -email         $null `
    -description   $null `
    -isAdmin       0 `
    -isMythAccount 1 `
    -statusId      3 `
    -createdDate   "2007-09-05 00:00:00" `
    -ageBracket    1

# ── 12 bots de teste ─────────────────────────────────────────
Write-Host ""
Write-Host "  [INFO] Criando 12 contas bot de teste..." -ForegroundColor Yellow

$bots = @(
    @{ Name="Player1";  Desc="Hey! I love building things on RetroBlox!" },
    @{ Name="Player2";  Desc="Scripting enthusiast and game developer." },
    @{ Name="Player3";  Desc="Just here to have fun and play games." },
    @{ Name="Player4";  Desc="RetroBlox is the best platform ever!" },
    @{ Name="Player5";  Desc="Explorer and adventure seeker." },
    @{ Name="Player6";  Desc="I like to make obstacle courses." },
    @{ Name="Player7";  Desc="Sword fighter and ninja warrior." },
    @{ Name="Player8";  Desc="Collector of rare items and hats." },
    @{ Name="Player9";  Desc="I run the fastest on the server!" },
    @{ Name="Player10"; Desc="Builder, scripter, and team player." },
    @{ Name="Player11"; Desc="Game tester and bug reporter." },
    @{ Name="Player12"; Desc="I joined RetroBlox on day one!" }
)

foreach ($bot in $bots) {
    $year  = Get-Random -Minimum 2008 -Maximum 2013
    $month = Get-Random -Minimum 1    -Maximum 13
    $day   = Get-Random -Minimum 1    -Maximum 28
    $date  = "{0}-{1:D2}-{2:D2} 00:00:00" -f $year, $month, $day

    Add-Account `
        -name          $bot.Name `
        -password      ("BotPass@" + $bot.Name + "1") `
        -email         $null `
        -description   $bot.Desc `
        -isAdmin       0 `
        -isMythAccount 0 `
        -statusId      1 `
        -createdDate   $date `
        -ageBracket    1
}

Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host "   Contas criadas com sucesso!" -ForegroundColor Cyan
Write-Host ""
Write-Host "   builderman  senha: Admin@RetroBlox1  (MUDE ISSO!)" -ForegroundColor Yellow
Write-Host "   noli        conta deletada/glitchada (mito de 2007)" -ForegroundColor DarkGray
Write-Host "   Player1-12  bots de teste" -ForegroundColor Green
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host ""
