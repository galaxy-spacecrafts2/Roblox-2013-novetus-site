# ============================================================
# RetroBlox - Account Seeder
# Cria tabelas e contas iniciais no SQL Server
# Chamado automaticamente pelo setup_and_build.bat
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

# ── Localiza BCrypt.Net DLL nos packages restaurados ────────
$bcryptDll = Get-ChildItem -Path "$ScriptDir\packages" -Recurse `
    -Filter "BCrypt.Net-Next.dll" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*net47*" -or $_.FullName -like "*net4*" } |
    Select-Object -First 1

if (-not $bcryptDll) {
    # fallback: qualquer versao
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

# ── Conexao SQL Server ───────────────────────────────────────
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

# ── Cria tabelas se nao existirem ───────────────────────────
Write-Host "  [INFO] Criando tabelas se nao existirem..." -ForegroundColor Yellow

Invoke-Sql @"
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AccountStatus')
BEGIN
    CREATE TABLE [dbo].[AccountStatus] (
        [ID]    TINYINT      NOT NULL PRIMARY KEY,
        [Value] NVARCHAR(50) NOT NULL
    );
    INSERT INTO [dbo].[AccountStatus] VALUES (1,'Ok'),(2,'Suppressed'),(3,'Deleted');
END
"@

Invoke-Sql @"
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Accounts')
BEGIN
    CREATE TABLE [dbo].[Accounts] (
        [ID]              BIGINT        NOT NULL PRIMARY KEY IDENTITY(1,1),
        [Name]            NVARCHAR(50)  NOT NULL UNIQUE,
        [Email]           NVARCHAR(200) NULL,
        [PasswordHash]    NVARCHAR(200) NOT NULL,
        [AccountStatusID] TINYINT       NOT NULL DEFAULT 1
                          REFERENCES [AccountStatus]([ID]),
        [Description]     NVARCHAR(500) NULL,
        [AgeBracket]      TINYINT       NOT NULL DEFAULT 1,
        [IsAdmin]         BIT           NOT NULL DEFAULT 0,
        [IsMythAccount]   BIT           NOT NULL DEFAULT 0,
        [Created]         DATETIME      NOT NULL DEFAULT GETUTCDATE()
    );
END
"@

Invoke-Sql @"
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [ID]        BIGINT       NOT NULL PRIMARY KEY IDENTITY(1,1),
        [Name]      NVARCHAR(50) NOT NULL UNIQUE,
        [AccountID] BIGINT       NOT NULL REFERENCES [Accounts]([ID]),
        [Created]   DATETIME     NOT NULL DEFAULT GETUTCDATE()
    );
END
"@

Write-Host "  [OK]  Tabelas prontas." -ForegroundColor Green

# ── Funcao auxiliar para inserir conta ──────────────────────
function Add-Account($name, $password, $email, $description, $isAdmin, $isMythAccount, $statusId, $createdDate, $ageBracket) {
    $exists = Invoke-SqlScalar "SELECT COUNT(1) FROM [Accounts] WHERE [Name] = '$name'"
    if ($exists -gt 0) {
        Write-Host "  [SKIP] Conta '$name' ja existe." -ForegroundColor DarkGray
        return
    }

    $hash        = Hash-Password $password
    $hash        = $hash.Replace("'","''")
    $description = if ($description) { $description.Replace("'","''") } else { $null }
    $descVal     = if ($description) { "'$description'" } else { "NULL" }
    $emailVal    = if ($email)       { "'$email'"       } else { "NULL" }
    $dateVal     = if ($createdDate) { "'$createdDate'" } else { "GETUTCDATE()" }

    $sql = @"
SET IDENTITY_INSERT [Accounts] OFF;
INSERT INTO [Accounts]
    ([Name],[Email],[PasswordHash],[AccountStatusID],[Description],[AgeBracket],[IsAdmin],[IsMythAccount],[Created])
VALUES
    ('$name',$emailVal,'$hash',$statusId,$descVal,$ageBracket,$isAdmin,$isMythAccount,$dateVal);

DECLARE @accId BIGINT = SCOPE_IDENTITY();
INSERT INTO [Users] ([Name],[AccountID],[Created])
VALUES ('$name', @accId, $dateVal);
"@
    Invoke-Sql $sql
    Write-Host "  [OK]  Conta criada: $name" -ForegroundColor Green
}

function Add-AccountWithId($id, $name, $password, $email, $description, $isAdmin, $isMythAccount, $statusId, $createdDate, $ageBracket) {
    $exists = Invoke-SqlScalar "SELECT COUNT(1) FROM [Accounts] WHERE [Name] = '$name'"
    if ($exists -gt 0) {
        Write-Host "  [SKIP] Conta '$name' ja existe." -ForegroundColor DarkGray
        return
    }

    $hash        = Hash-Password $password
    $hash        = $hash.Replace("'","''")
    $description = if ($description) { $description.Replace("'","''") } else { $null }
    $descVal     = if ($description) { "'$description'" } else { "NULL" }
    $emailVal    = if ($email)       { "'$email'"       } else { "NULL" }
    $dateVal     = if ($createdDate) { "'$createdDate'" } else { "GETUTCDATE()" }

    $sql = @"
SET IDENTITY_INSERT [Accounts] ON;
INSERT INTO [Accounts]
    ([ID],[Name],[Email],[PasswordHash],[AccountStatusID],[Description],[AgeBracket],[IsAdmin],[IsMythAccount],[Created])
VALUES
    ($id,'$name',$emailVal,'$hash',$statusId,$descVal,$ageBracket,$isAdmin,$isMythAccount,$dateVal);
SET IDENTITY_INSERT [Accounts] OFF;

INSERT INTO [Users] ([Name],[AccountID],[Created])
VALUES ('$name', $id, $dateVal);
"@
    Invoke-Sql $sql
    Write-Host "  [OK]  Conta criada: $name (ID=$id)" -ForegroundColor Green
}

# ============================================================
# CONTA 1 - builderman (voce, admin, ID=1)
# ============================================================
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

# ============================================================
# CONTA 2 - noli (conta lenda/mito, deletada, 2007)
# Baseado em: conta glitchada documentada em fev/2010,
# associada a Void Stars, sem dados de avatar, redireciona
# para homepage ao clicar no perfil. Considerada deletada
# cujos dados foram completamente apagados do sistema.
# ============================================================
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

# ============================================================
# 12 CONTAS BOT
# ============================================================
Write-Host ""
Write-Host "  [INFO] Criando 12 contas bot de teste..." -ForegroundColor Yellow

$bots = @(
    @{ Name="Player1";    Desc="Hey! I love building things on RetroBlox!" },
    @{ Name="Player2";    Desc="Scripting enthusiast and game developer." },
    @{ Name="Player3";    Desc="Just here to have fun and play games." },
    @{ Name="Player4";    Desc="RetroBlox is the best platform ever!" },
    @{ Name="Player5";    Desc="Explorer and adventure seeker." },
    @{ Name="Player6";    Desc="I like to make obstacle courses." },
    @{ Name="Player7";    Desc="Sword fighter and ninja warrior." },
    @{ Name="Player8";    Desc="Collector of rare items and hats." },
    @{ Name="Player9";    Desc="I run the fastest on the server!" },
    @{ Name="Player10";   Desc="Builder, scripter, and team player." },
    @{ Name="Player11";   Desc="Game tester and bug reporter." },
    @{ Name="Player12";   Desc="I joined RetroBlox on day one!" }
)

foreach ($bot in $bots) {
    # Data de criacao espalhada entre 2008 e 2012 para parecer real
    $year  = Get-Random -Minimum 2008 -Maximum 2013
    $month = Get-Random -Minimum 1    -Maximum 13
    $day   = Get-Random -Minimum 1    -Maximum 28
    $date  = "{0}-{1:D2}-{2:D2} 00:00:00" -f $year, $month, $day

    Add-Account `
        -name          $bot.Name `
        -password      "BotPass@$($bot.Name)1" `
        -email         $null `
        -description   $bot.Desc `
        -isAdmin       0 `
        -isMythAccount 0 `
        -statusId      1 `
        -createdDate   $date `
        -ageBracket    1
}

# ── Resumo final ─────────────────────────────────────────────
Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host "   Contas criadas com sucesso!" -ForegroundColor Cyan
Write-Host "" 
Write-Host "   builderman  senha: Admin@RetroBlox1  (MUDE ISSO!)" -ForegroundColor Yellow
Write-Host "   noli        conta deletada/glitchada (mito)" -ForegroundColor DarkGray
Write-Host "   Player1-12  bots de teste" -ForegroundColor Green
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host ""
