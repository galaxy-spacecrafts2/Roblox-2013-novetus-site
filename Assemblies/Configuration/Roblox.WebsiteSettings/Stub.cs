namespace Roblox.WebsiteSettings
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default { get { return _default; } }

            public bool MergeJavaScriptFiles { get; set; }
            public bool MergeCSS { get; set; }
            public bool IsGeneralLogExceptionThrottlingEnabled { get; set; }
            public int ExceptionLogCountBeforeThrottling { get; set; }
            public int ExceptionLogThrottlingInterval { get; set; }
            public string CookieConstraint_RedirectDomain { get; set; }
            public string CookieConstraint_RedirectURL { get; set; }
            public string CookieConstraint_ProtectedPageExtension { get; set; }
            public string ClientInstallHost { get; set; }

            public Settings()
            {
                MergeJavaScriptFiles = false;
                MergeCSS = false;
                IsGeneralLogExceptionThrottlingEnabled = false;
                ExceptionLogCountBeforeThrottling = 10;
                ExceptionLogThrottlingInterval = 60;
                CookieConstraint_RedirectDomain = string.Empty;
                CookieConstraint_RedirectURL = string.Empty;
                CookieConstraint_ProtectedPageExtension = string.Empty;
                ClientInstallHost = string.Empty;
            }
        }

        public class Layout
        {
            private static Layout _default = new Layout();
            public static Layout Default { get { return _default; } }

            public bool IsUpdatedInstallationInstructionsModalEnabled { get; set; }
            public bool UseMVCNavBar { get; set; }

            public Layout()
            {
                IsUpdatedInstallationInstructionsModalEnabled = false;
                UseMVCNavBar = false;
            }
        }

        public class GoogleAnalytics
        {
            private static GoogleAnalytics _default = new GoogleAnalytics();
            public static GoogleAnalytics Default { get { return _default; } }

            public string GoogleAnalyticsAccountCode { get; set; }

            public GoogleAnalytics()
            {
                GoogleAnalyticsAccountCode = string.Empty;
            }
        }

        public class WebsiteBootstrapSettings
        {
            private static WebsiteBootstrapSettings _default = new WebsiteBootstrapSettings();
            public static WebsiteBootstrapSettings Default { get { return _default; } }

            public string GeneralEventLogSource { get; set; }
            public int GeneralEventLogLevel { get; set; }

            public WebsiteBootstrapSettings()
            {
                GeneralEventLogSource = "RobloxWebsite";
                GeneralEventLogLevel = 0;
            }
        }
    }
}
