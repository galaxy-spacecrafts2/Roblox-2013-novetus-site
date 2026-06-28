#!/bin/bash

WORKSPACE="/home/runner/workspace"
WEBROOT="$WORKSPACE/RobloxWebSite"
PORT=5000
TEMP_DIR="$WORKSPACE/.aspnet_temp"

echo "=== RetroBlox Web Server ==="

# Build main ASP.NET project if DLL is missing
if [ ! -f "$WEBROOT/bin/Roblox.Website.dll" ]; then
    echo "[BUILD] Building project..."
    cd "$WORKSPACE"
    dotnet msbuild RobloxWebSite/Roblox.Website.csproj /t:Build /nologo /verbosity:minimal
    if [ $? -ne 0 ]; then echo "[BUILD] FAILED"; exit 1; fi
fi

# Clear stale ASP.NET temp dirs to avoid sharing violations on resx compilation
echo "[TEMP] Clearing ASP.NET temp dirs..."
rm -rf /tmp/runner-temp-aspnet-* "$TEMP_DIR" 2>/dev/null || true
mkdir -p "$TEMP_DIR"

# Pre-compile App_GlobalResources so ASP.NET runtime doesn't deadlock on them
echo "[RES] Pre-compiling App_GlobalResources..."
RESDIR="$TEMP_DIR/res"
mkdir -p "$RESDIR"
RESARGS=""
for resx in "$WEBROOT/App_GlobalResources/"*.resx; do
    base=$(basename "$resx" .resx)
    outfile="$RESDIR/${base}.resources"
    resgen "$resx" "$outfile" > /dev/null 2>&1
    RESARGS="$RESARGS /res:$outfile"
done
csc /t:library $RESARGS -out:"$WEBROOT/bin/App_GlobalResources.dll" > /dev/null 2>&1
echo "[RES] App_GlobalResources.dll built."

# Always recompile host library and server exe
echo "[HOST] Compiling MonoHost.dll..."
cd "$WORKSPACE"
csc /r:System.Web.dll /r:System.Net.dll /target:library host.cs -out:MonoHost.dll > /dev/null 2>&1

echo "[HOST] Compiling server.exe..."
csc /r:System.Web.dll /r:System.Net.dll /r:MonoHost.dll program.cs -out:server.exe > /dev/null 2>&1

# Deploy host DLL into web app bin/ for the web AppDomain to find
cp MonoHost.dll "$WEBROOT/bin/MonoHost.dll"
echo "[HOST] MonoHost.dll deployed."

echo "[SERVER] Starting on port $PORT..."
exec mono server.exe "$WEBROOT" "$PORT"
