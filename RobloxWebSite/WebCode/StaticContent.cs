using System;
using System.Collections.Generic;
using System.Web;
using Roblox.Web.StaticContent;

namespace Roblox.Website
{
    /// <summary>
    /// Acts as a wrapper for all things static content.
    /// </summary>
    public class StaticContent
    {
        public static string GetUrl(string fileName)
        {
            return StaticContentV1.GetUrl(fileName);
        }


        // ROBLOX JavaScript //

        public static void CreateScriptBundle(string name, params string[] files)
        {
        }

        public static void CreateCSSBundle(string name, params string[] files)
        {
        }
    }
}
