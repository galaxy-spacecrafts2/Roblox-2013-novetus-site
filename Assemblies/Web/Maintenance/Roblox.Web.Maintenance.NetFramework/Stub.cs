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
