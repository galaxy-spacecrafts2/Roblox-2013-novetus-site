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
