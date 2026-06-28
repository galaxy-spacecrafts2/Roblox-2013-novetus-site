using System.Collections.Generic;
using System.Web;

namespace Roblox.Web.StaticContent
{
    namespace Properties
    {
        public class Settings
        {
            private static Settings _default = new Settings();
            public static Settings Default { get { return _default; } }
            public bool MinifyJavascript { get; set; }
            public bool MinifyCss { get; set; }
            public Settings() { MinifyJavascript = false; MinifyCss = false; }
        }
    }

    public class RobloxScriptBundle
    {
        public string Name { get; set; }
    }

    public class RobloxCSSBundle
    {
        public string Name { get; set; }
    }

    public static class StaticContentV1
    {
        public static string GetUrl(string fileName) { return "/" + fileName; }
    }

    public static class RobloxScripts
    {
        private static readonly List<string> _pageScripts = new List<string>();
        public static List<string> PageScripts { get { return _pageScripts; } }
        public static bool MergeFiles { get; set; }

        public static HtmlString RenderBundle(string name)
        {
            return new HtmlString(string.Empty);
        }

        public static HtmlString Render(RobloxScriptBundle bundle)
        {
            return new HtmlString(string.Empty);
        }

        public static RobloxScriptBundle CreateBundle(string name, IEnumerable<string> files, bool minify)
        {
            return new RobloxScriptBundle { Name = name };
        }
    }

    public static class RobloxCSS
    {
        private static readonly List<string> _pageCSS = new List<string>();
        public static List<string> PageCSS { get { return _pageCSS; } }
        public static bool MergeFiles { get; set; }

        public static HtmlString RenderBundle(string name)
        {
            return new HtmlString(string.Empty);
        }

        public static HtmlString Render(RobloxCSSBundle bundle)
        {
            return new HtmlString(string.Empty);
        }

        public static RobloxCSSBundle CreateBundle(string name, IEnumerable<string> files, bool minify)
        {
            return new RobloxCSSBundle { Name = name };
        }
    }
}
