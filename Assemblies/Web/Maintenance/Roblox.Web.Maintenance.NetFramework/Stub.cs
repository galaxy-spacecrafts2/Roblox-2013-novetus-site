using System;

namespace Roblox.Web.Maintenance
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default { get { return _default; } }
            public string CookieConstraintIpBypassRangeCsv { get; set; }

            public Settings() { CookieConstraintIpBypassRangeCsv = string.Empty; }
        }
    }

    public static class CookieConstraintSettings
    {
        public static void SetCookieConstraintSettings(
            Func<bool> getIsEnabled,
            Func<string> getCookieName,
            Func<string> getPassword,
            Func<string> getRedirectDomain,
            Func<string> getRedirectUrl,
            Func<string> getProtectedPageExtension,
            Func<string> getIpBypassRangeCsv,
            Func<string> getAllowedButtonValuesCsv) { }
    }
}
