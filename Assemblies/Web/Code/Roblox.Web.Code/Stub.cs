namespace Roblox.Web.Code
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default { get { return _default; } }

            public bool IsCookieConstraintEnabled { get; set; }
            public string CookieConstraintCookieName { get; set; }
            public string CookieConstraintPassword { get; set; }
            public string CookieConstraint_AllowedButtonValuesCSV { get; set; }

            public Settings()
            {
                IsCookieConstraintEnabled = false;
                CookieConstraintCookieName = string.Empty;
                CookieConstraintPassword = string.Empty;
                CookieConstraint_AllowedButtonValuesCSV = string.Empty;
            }
        }
    }

    namespace Util
    {
        public static class Abbreviate
        {
            public static string GetTruncValue(int value) { return value.ToString(); }
        }
    }
}
