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
