param(
    [Parameter(Mandatory=$true)]
    [string]$AssembliesRoot
)

$ErrorActionPreference = "Stop"

function Normalize-StubDir($dir, $name) {
    while ($true) {
        $leaf = Split-Path $dir -Leaf
        $parent = Split-Path $dir -Parent
        if ($leaf -eq $name -and (Split-Path $parent -Leaf) -eq $name) {
            $dir = $parent
            continue
        }
        break
    }
    return $dir
}

function Write-Stub($dir, $name, $content) {
    $dir = Normalize-StubDir $dir $name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $csproj = @"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props"
          Condition="Exists('`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '`$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '`$(Platform)' == '' ">AnyCPU</Platform>
    <OutputType>Library</OutputType>
    <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>
    <AssemblyName>$name</AssemblyName>
    <RootNamespace>$name</RootNamespace>
  </PropertyGroup>
  <PropertyGroup Condition=" '`$(Configuration)|`$(Platform)' == 'Debug|AnyCPU' ">
    <OutputPath>bin\Debug\</OutputPath>
  </PropertyGroup>
  <PropertyGroup Condition=" '`$(Configuration)|`$(Platform)' == 'Release|AnyCPU' ">
    <OutputPath>bin\Release\</OutputPath>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Stub.cs" />
  </ItemGroup>
  <Import Project="`$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
"@
    Set-Content (Join-Path $dir "$name.csproj") $csproj -Encoding UTF8
    Set-Content (Join-Path $dir "Stub.cs") $content -Encoding UTF8
    Write-Host "  [OK] $name"
}

function Write-StubWithRef($dir, $name, $refs, $content) {
    $dir = Normalize-StubDir $dir $name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $refItems = ($refs | ForEach-Object { "    <Reference Include=`"$_`"><HintPath>..\..\$_\bin\Release\$_.dll</HintPath></Reference>" }) -join "`n"
    $csproj = @"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props"
          Condition="Exists('`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '`$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '`$(Platform)' == '' ">AnyCPU</Platform>
    <OutputType>Library</OutputType>
    <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>
    <AssemblyName>$name</AssemblyName>
    <RootNamespace>$name</RootNamespace>
  </PropertyGroup>
  <PropertyGroup Condition=" '`$(Configuration)|`$(Platform)' == 'Debug|AnyCPU' ">
    <OutputPath>bin\Debug\</OutputPath>
  </PropertyGroup>
  <PropertyGroup Condition=" '`$(Configuration)|`$(Platform)' == 'Release|AnyCPU' ">
    <OutputPath>bin\Release\</OutputPath>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Stub.cs" />
  </ItemGroup>
  <ItemGroup>
$refItems
  </ItemGroup>
  <Import Project="`$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
"@
    Set-Content (Join-Path $dir "$name.csproj") $csproj -Encoding UTF8
    Set-Content (Join-Path $dir "Stub.cs") $content -Encoding UTF8
    Write-Host "  [OK] $name (refs: $($refs -join ', '))"
}

Write-Host ""
Write-Host "=== Gerando stubs com tipos reais ==="
Write-Host "Destino: $AssembliesRoot"
Write-Host ""

# ─── Roblox.EventLog ───────────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\EventLog\Roblox.EventLog" `
  "Roblox.EventLog" `
@'
using System;

namespace Roblox.EventLog
{
    public interface ILogger
    {
        void Error(object message);
        void Warning(object message);
        void Info(object message);
    }

    public enum LogLevel { Info, Warning, Error }

    public class Logger : ILogger
    {
        public virtual void Error(object message) { }
        public virtual void Warning(object message) { }
        public virtual void Info(object message) { }
    }

    public class ExceptionThrottlingLogger : Logger { }

    public static class StaticLoggerRegistry
    {
        public static void SetLogger(ILogger logger) { }
    }
}
'@

# ─── Roblox.Configuration ──────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Configuration\Roblox.Configuration" `
  "Roblox.Configuration" `
@'
using System;

namespace Roblox.Configuration
{
    public static class ConfigurationLogging
    {
        public static void OverrideDefaultConfigurationLogging(
            Action<string> error,
            Action<string> warning,
            Action<string> info) { }
    }
}
'@

# ─── Roblox.Hashing ────────────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Hashing\Roblox.Hashing" `
  "Roblox.Hashing" `
@'
namespace Roblox.Hashing
{
    public static class HashGenerator
    {
        public static string HashString(string password) => string.Empty;
    }
}
'@

# ─── Roblox.Farms ──────────────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Infrastructure\Roblox.Farms" `
  "Roblox.Farms" `
@'
namespace Roblox.Farms
{
    public abstract class KeepAlive
    {
        public abstract void ProcessRequest(System.Web.HttpContext context);
        public virtual bool IsReusable => false;
    }
}
'@

# ─── Roblox.Platform.Core ──────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Core\Roblox.Platform.Core" `
  "Roblox.Platform.Core" `
@'
namespace Roblox.Platform.Core { }
'@

# ─── Roblox.Platform.Membership ────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Membership\Roblox.Platform.Membership" `
  "Roblox.Platform.Membership" `
@'
using System;
using System.Collections.Generic;

namespace Roblox.Platform.Membership
{
    public enum AccountStatus
    {
        Ok = 1,
        Suppressed = 2,
        Deleted = 3
    }

    public static class AccountStatusExtensions
    {
        public static int OkId => (int)AccountStatus.Ok;
    }

    public enum AgeBracket
    {
        AgeUnder13 = 0,
        Age13OrOver = 1
    }

    public interface IUser
    {
        long Id { get; }
        string Name { get; }
        long AccountId { get; }
        DateTime Created { get; }
        AccountStatus AccountStatus { get; }
        string Description { get; }
        AgeBracket AgeBracket { get; }
    }

    public interface IUserFactory
    {
        IUser GetUserByName(string username);
        IUser GetUser(long userId);
        IUser MustGetUser(long userId);
        IUser GetCurrentUser();
    }

    public interface IRoleSetValidator
    {
        IEnumerable<object> GetRoleSets(IUser user);
        bool IsInRole(IUser user, string roleName);
        bool IsPrivilegedUser(IUser user);
    }

    public class MembershipDomainFactories
    {
        public IUserFactory UserFactory { get; set; }
        public IRoleSetValidator RoleSetValidator { get; set; }

        public MembershipDomainFactories() { }
    }
}
'@

# ─── Roblox.Platform.Membership.Core ──────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Membership\Roblox.Platform.Membership.Core" `
  "Roblox.Platform.Membership.Core" `
@'
namespace Roblox.Platform.Membership.Core { }
'@

# ─── Roblox.Platform.Membership.Commands ──────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Membership\Roblox.Platform.Membership.Commands" `
  "Roblox.Platform.Membership.Commands" `
@'
namespace Roblox.Platform.Membership.Commands { }
'@

# ─── Roblox.Platform.Roles ─────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Roles\Roblox.Platform.Roles" `
  "Roblox.Platform.Roles" `
@'
using System.Collections.Generic;
using Roblox.Platform.Membership;

namespace Roblox.Platform.Roles
{
    public interface IRoleSet
    {
        string Name { get; }
        long Id { get; }
    }

    public interface IRoleSetReader
    {
        IRoleSet GetRoleSet(string roleName);
        IEnumerable<IRoleSet> GetAllRoleSets();
        IRoleSet GetHighestRoleSetForAccountId(long accountId);
    }

    public class RolesDomainFactories
    {
        public IRoleSetReader RoleSetReader { get; set; }
        public IRoleSetValidator RoleSetValidator { get; set; }

        public RolesDomainFactories() { }
    }
}
'@

# ─── Roblox.Platform.Roles.Core ───────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Roles\Roblox.Platform.Roles.Core" `
  "Roblox.Platform.Roles.Core" `
@'
namespace Roblox.Platform.Roles.Core { }
'@

# ─── Roblox.Platform.Roles.Entities ───────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Roles\Roblox.Platform.Roles.Entities" `
  "Roblox.Platform.Roles.Entities" `
@'
namespace Roblox.Platform.Roles.Entities { }
'@

# ─── Roblox.Platform.Email ─────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Email\Roblox.Platform.Email" `
  "Roblox.Platform.Email" `
@'
using Roblox.Platform.Membership;

namespace Roblox.Platform.Email
{
    public interface IEmailAddress
    {
        string Address { get; }
    }

    public interface IUserEmail
    {
        IEmailAddress EmailAddress { get; }
        bool IsValid { get; }
    }

    public interface IUserEmailFactory
    {
        IUserEmail GetCurrentVerified(IUser user);
    }

    public class EmailDomainFactories
    {
        public IUserEmailFactory UserEmailFactory { get; set; }
        public EmailDomainFactories() { }
    }
}
'@

# ─── Roblox.Platform.Email.Core / Entities ────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Email\Roblox.Platform.Email.Core" `
  "Roblox.Platform.Email.Core" `
@'
namespace Roblox.Platform.Email.Core { }
'@

Write-Stub `
  "$AssembliesRoot\Platform\Email\Roblox.Platform.Email.Entities" `
  "Roblox.Platform.Email.Entities" `
@'
namespace Roblox.Platform.Email.Entities { }
'@

# ─── Roblox.Platform.Authentication ───────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Authentication\Roblox.Platform.Authentication" `
  "Roblox.Platform.Authentication" `
@'
namespace Roblox.Platform.Authentication
{
    public enum CredentialsType { Username = 0, Email = 1 }

    public class Credentials
    {
        public string Value { get; set; }
        public CredentialsType CredentialsType { get; set; }
        public string Password { get; set; }
    }

    public interface ICredentialValidator
    {
        bool ValidateCredentials(Credentials credentials);
    }

    public class AuthenticationDomainFactories
    {
        public ICredentialValidator CredentialValidator { get; set; }
        public AuthenticationDomainFactories() { }
    }
}
'@

Write-Stub `
  "$AssembliesRoot\Platform\Authentication\Roblox.Platform.Authentication.Core" `
  "Roblox.Platform.Authentication.Core" `
@'
namespace Roblox.Platform.Authentication.Core { }
'@

Write-Stub `
  "$AssembliesRoot\Platform\Authentication\Roblox.Platform.Authentication.Entities" `
  "Roblox.Platform.Authentication.Entities" `
@'
namespace Roblox.Platform.Authentication.Entities { }
'@

# ─── Roblox.Platform.Security ─────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Platform\Security\Roblox.Platform.Security" `
  "Roblox.Platform.Security" `
@'
namespace Roblox.Platform.Security
{
    public class SecurityDomainFactories
    {
        public SecurityDomainFactories() { }
    }
}
'@

Write-Stub `
  "$AssembliesRoot\Platform\Security\Roblox.Platform.Security.Core" `
  "Roblox.Platform.Security.Core" `
@'
namespace Roblox.Platform.Security.Core { }
'@

# ─── Roblox.Moderation ─────────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Moderation\Roblox.Moderation" `
  "Roblox.Moderation" `
@'
using System;
using System.Collections.Generic;

namespace Roblox.Moderation
{
    public class PunishmentType
    {
        public byte ID { get; set; }
        public string Value { get; set; }
        public int? DurationInDays { get; set; }

        public static PunishmentType Get(byte id) => new PunishmentType { ID = id };
        public static IEnumerable<PunishmentType> AllPunishmentTypes => new List<PunishmentType>();

        public static PunishmentType DeleteAccount => new PunishmentType { Value = "DeleteAccount" };
        public static PunishmentType PoisonMachine => new PunishmentType { Value = "PoisonMachine" };
        public static PunishmentType Remind       => new PunishmentType { Value = "Remind" };
        public static PunishmentType Warn         => new PunishmentType { Value = "Warn" };
        public static PunishmentType None         => new PunishmentType { Value = "None" };
    }

    public class Punishment
    {
        public long ID { get; set; }
        public PunishmentType PunishmentType { get; set; }
        public long ModeratorID { get; set; }
        public string Comment { get; set; }
        public string ModeratorMessage { get; set; }
        public DateTime Created { get; set; }
        public DateTime? Expiration { get; set; }

        public static IEnumerable<Punishment> GetPunishmentsByUserIDPaged(
            int startRowIndex, int maximumRows, int userId)
            => new List<Punishment>();

        public static long GetTotalNumberOfPunishmentsByUserID(long userId) => 0;
        public static long GetTotalNumberOfActivePunishmentsByUserID(long userId) => 0;

        public static IEnumerable<Punishment> GetActivePunishmentsByUserIDPaged(
            int startRowIndex, int maximumRows, int userId)
            => new List<Punishment>();

        public static Punishment CreateNew(
            int userId, byte punishmentTypeId, int? appealId,
            int moderatorId, string comment, string message)
            => new Punishment();
    }
}
'@

# ─── Roblox.Showcases.Entities ─────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Showcases\Roblox.Showcases" `
  "Roblox.Showcases" `
@'
using System;
using System.Collections.Generic;

namespace Roblox.Showcases.Entities
{
    public interface IAsset
    {
        long Id { get; }
        string Name { get; }
    }

    public enum ShowcaseType { Places = 0 }
    public enum CreatorType   { User = 0, Group = 1 }

    public class Showcase
    {
        public long ID { get; set; }

        public static Showcase GetOrCreate(
            ShowcaseType type, CreatorType creatorType, long creatorId)
            => new Showcase();
    }

    public class ShowcaseItem
    {
        public IAsset Asset { get; set; }

        public static IEnumerable<ShowcaseItem> GetShowcaseItemsByShowcaseIDPaged(
            int startRowIndex, int maximumRows, long showcaseId)
            => new List<ShowcaseItem>();
    }
}
'@

# ─── Roblox.Users.Entities (part of Users assembly) ───────────────────────────
Write-Stub `
  "$AssembliesRoot\Users\Roblox.Users" `
  "Roblox.Users" `
@'
using System;

namespace Roblox.Users.Entities
{
    public class AccountStatus
    {
        public byte ID { get; set; }
        public string Value { get; set; }
        public static AccountStatus Ok => new AccountStatus { Value = "Ok", ID = 1 };
        public static AccountStatus MustGet(byte id) => new AccountStatus { ID = id };
    }

    public class Account
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public byte AccountStatusID { get; set; }
        public AccountStatus AccountStatus { get; set; }

        public static Account MustGet(long accountId) => new Account { ID = accountId };
        public void Save() { }
    }

    public class User
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public long AccountID { get; set; }

        public static User MustGet(long userId) => new User { ID = userId };
    }
}
'@

Write-Stub `
  "$AssembliesRoot\Users\Roblox.Users.Old" `
  "Roblox.Users.Old" `
@'
namespace Roblox.Users.Old { }
'@

# ─── Roblox Server Class Library (Account, User, Signup) ──────────────────────
New-Item -ItemType Directory -Force -Path "$AssembliesRoot\Server Class Library\Roblox Class Library" | Out-Null
$sclCsproj = @'
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props"
          Condition="Exists('$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <OutputType>Library</OutputType>
    <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>
    <AssemblyName>Roblox Server Class Library</AssemblyName>
    <RootNamespace>Roblox</RootNamespace>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <OutputPath>bin\Debug\</OutputPath>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <OutputPath>bin\Release\</OutputPath>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Stub.cs" />
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
'@
Set-Content "$AssembliesRoot\Server Class Library\Roblox Class Library\Roblox Server Class Library.csproj" $sclCsproj -Encoding UTF8
Set-Content "$AssembliesRoot\Server Class Library\Roblox Class Library\Stub.cs" @'
using System;
using System.Collections.Generic;

namespace Roblox
{
    public class Account
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }

        public static Account Get(string username) => null;
        public static Account Get(int accountId) => null;
        public static IEnumerable<Account> GetAccountsByEmailAddress(string email) => new List<Account>();
        public static Account GetCurrent() => null;
    }

    public class User
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public long RobloxAccountID { get; set; }
        public Account RobloxAccount { get; set; }

        public static User GetByAccountID(long accountId) => null;
        public static IEnumerable<User> FindUsers(
            int? userId, string userName, string emailAddress, int? ipAddress)
            => new List<User>();
    }

    public static class Signup
    {
        public static bool ValidateUserName(string username) => true;
        public static bool ValidateEmail(string email) => true;
        public static bool CheckEmailUsability(string email) => true;
        public static Account CreateNew(string username, string passwordHash, string email) => new Account();
    }
}
'@ -Encoding UTF8
Write-Host "  [OK] Roblox Server Class Library"

# ─── Roblox.Web.Code ───────────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Web\Code\Roblox.Web.Code" `
  "Roblox.Web.Code" `
@'
namespace Roblox.Web.Code
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default => _default;

            public bool IsCookieConstraintEnabled { get; set; } = false;
            public string CookieConstraintCookieName { get; set; } = string.Empty;
            public string CookieConstraintPassword { get; set; } = string.Empty;
            public string CookieConstraint_AllowedButtonValuesCSV { get; set; } = string.Empty;
        }
    }

    namespace Util
    {
        public static class Abbreviate
        {
            public static string GetTruncValue(int value) => value.ToString();
        }
    }
}
'@

# ─── Roblox.Web.Maintenance ────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Web\Maintenance\Roblox.Web.Maintenance.NetFramework" `
  "Roblox.Web.Maintenance.NetFramework" `
@'
using System;

namespace Roblox.Web.Maintenance
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default => _default;
            public string CookieConstraintIpBypassRangeCsv { get; set; } = string.Empty;
        }
    }

    public static class CookieConstraintSettings
    {
        public static void SetCookieConstraintSettings(
            bool isEnabled,
            string cookieName,
            string password,
            string allowedButtonValuesCsv,
            string ipBypassRangeCsv) { }
    }
}
'@

# ─── Roblox.Web.Mvc ────────────────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Web\Mvc\Roblox.Web.Mvc.NetFramework" `
  "Roblox.Web.Mvc.NetFramework" `
@'
using System;
using System.Web.Mvc;

namespace Roblox.Web.Mvc
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class CookieConstraintAttributeWithRedirect : ActionFilterAttribute
    {
        public override void OnActionExecuting(ActionExecutingContext filterContext) { }
    }
}
'@

# ─── Roblox.Web.StaticContent ──────────────────────────────────────────────────
Write-Stub `
  "$AssembliesRoot\Web\StaticContent\Roblox.Web.StaticContent" `
  "Roblox.Web.StaticContent" `
@'
using System.Collections.Generic;

namespace Roblox.Web.StaticContent
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default => _default;
            public bool MinifyJavascript { get; set; } = false;
            public bool MinifyCss { get; set; } = false;
        }
    }

    public static class StaticContentV1
    {
        public static string GetUrl(string fileName) => "/" + fileName;
    }

    public static class RobloxScripts
    {
        public static List<string> PageScripts { get; } = new List<string>();
        public static object CreateBundle(string name, IEnumerable<string> files, bool minify) => null;
    }

    public static class RobloxCSS
    {
        public static List<string> PageCSS { get; } = new List<string>();
        public static object CreateBundle(string name, IEnumerable<string> files, bool minify) => null;
    }
}
'@

# ─── Roblox.Web.Code (remaining sub-assemblies) ───────────────────────────────
Write-Stub "$AssembliesRoot\Web\HttpModules\Roblox.Web.HttpModules" "Roblox.Web.HttpModules" `
  "namespace Roblox.Web.HttpModules { }"

Write-Stub "$AssembliesRoot\Core\Roblox.Web.Core" "Roblox.Web.Core" `
  "namespace Roblox.Web.Core { }"

Write-Stub "$AssembliesRoot\UI\Roblox.Controls" "Roblox.Controls" `
  "namespace Roblox.Controls { }"

Write-Stub "$AssembliesRoot\UI\Roblox.Thumbs" "Roblox.Thumbs" `
  "namespace Roblox.Thumbs { }"

# ─── Remaining stubs (minimal) ─────────────────────────────────────────────────
$minimalStubs = @{
    "Agents\Roblox.Agents\Roblox.Agents"                                           = "Roblox.Agents"
    "ApiControlPlane\Roblox.ApiControlPlane\Roblox.ApiControlPlane"               = "Roblox.ApiControlPlane"
    "Assets\Roblox.Assets\Roblox.Assets"                                           = "Roblox.Assets"
    "Caching\Emcaster\Emcaster"                                                    = "Emcaster"
    "Caching\MemCachedClient"                                                    = "Roblox.MemcachedClient"
    "Caching\Roblox.Caching\Roblox.Caching"                                        = "Roblox.Caching"
    "Caching\Roblox.MultiCastToMemcached\Roblox.MultiCastToMemcached"             = "Roblox.MultiCastToMemcached"
    "Common\Roblox.Common.NetStandard\Roblox.Common.NetStandard"                  = "Roblox.Common.NetStandard"
    "Common\Roblox.Common\Roblox.Common"                                           = "Roblox.Common"
    "Common\Roblox.Common.Web\Roblox.Common.Web"                                   = "Roblox.Common.Web"
    "Configuration\Roblox.WebsiteSettings\Roblox.WebsiteSettings"                 = "Roblox.WebsiteSettings"
    "Data\Roblox.Data\Roblox.Data"                                                 = "Roblox.Data"
    "Databases\Roblox.Databases\Roblox.Databases"                                  = "Roblox.Databases"
    "DataV2\Core\Roblox.DataV2.Core\Roblox.DataV2.Core"                            = "Roblox.DataV2.Core"
    "Economy\Roblox.Economy.Common\Roblox.Economy.Common"                          = "Roblox.Economy.Common"
    "Entities\Roblox.Entities.Mssql\Roblox.Entities.Mssql"                        = "Roblox.Entities.Mssql"
    "EntityFrameworkCore\Roblox.EntityFrameworkCore\Roblox.EntityFrameworkCore"    = "Roblox.EntityFrameworkCore"
    "EventLog\Roblox.EventLog.Extended\Roblox.EventLog.Extended"                   = "Roblox.EventLog.Extended"
    "Files\Roblox.Files\Roblox.Files"                                              = "Roblox.Files"
    "Grid\Arbiter\Roblox.Grid.Arbiter.Common\Roblox.Grid.Arbiter.Common"          = "Roblox.Grid.Arbiter.Common"
    "Grid\Roblox.Grid.Client\Roblox.Grid.Client"                                   = "Roblox.Grid.Client"
    "Grid\Roblox.Grid.Common\Roblox.Grid.Common"                                   = "Roblox.Grid.Common"
    "Http\Roblox.Http.Client.Monitoring\Roblox.Http.Client.Monitoring"            = "Roblox.Http.Client.Monitoring"
    "Http\Roblox.Http.Client\Roblox.Http.Client"                                   = "Roblox.Http.Client"
    "Http\Roblox.Http\Roblox.Http"                                                 = "Roblox.Http"
    "Http\Roblox.Http.ServiceClient\Roblox.Http.ServiceClient"                    = "Roblox.Http.ServiceClient"
    "Instrumentation\Roblox.Instrumentation\Roblox.Instrumentation"               = "Roblox.Instrumentation"
    "IpAddresses\Roblox.IpAddresses\Roblox.IpAddresses"                           = "Roblox.IpAddresses"
    "LightUtils\Redis\Roblox.LightUtils.Redis\Roblox.LightUtils.Redis"            = "Roblox.LightUtils.Redis"
    "LightUtils\Roblox.LightUtils\Roblox.LightUtils"                               = "Roblox.LightUtils"
    "Marketing\Roblox.Marketing\Roblox.Marketing"                                  = "Roblox.Marketing"
    "Mssql\Roblox.MssqlDatabases\Roblox.MssqlDatabases"                           = "Roblox.MssqlDatabases"
    "Mssql\Roblox.Mssql\Roblox.Mssql"                                             = "Roblox.Mssql"
    "Pipeline\Roblox.Pipeline\Roblox.Pipeline"                                     = "Roblox.Pipeline"
    "Redis\Roblox.Redis\Roblox.Redis"                                              = "Roblox.Redis"
    "RequestContext\Roblox.RequestContext\Roblox.RequestContext"                   = "Roblox.RequestContext"
    "Sentinels\Roblox.Sentinels\Roblox.Sentinels"                                  = "Roblox.Sentinels"
    "Tracing\Roblox.Tracing.Core\Roblox.Tracing.Core"                             = "Roblox.Tracing.Core"
}

foreach ($entry in $minimalStubs.GetEnumerator()) {
    $ns = $entry.Value -replace '\.', '_' -replace '-', '_'
    Write-Stub `
        "$AssembliesRoot\$($entry.Key)" `
        $entry.Value `
        "namespace $($entry.Value) { }"
}

Write-Host ""
Write-Host "=== Concluído! Todos os stubs gerados. ==="
