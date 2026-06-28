// using Roblox.Farms; // Farms assembly not found
using System.Web;

namespace Roblox.Website.KeepAlives
{
    /// <summary>
    /// KeepAlive for WWW
    /// </summary>
    // public class WWW : KeepAlive
    public class WWW : IHttpHandler
    {
        public bool IsReusable => false;

        public void ProcessRequest(HttpContext context)
        {
            // Implement keep-alive response
            context.Response.ContentType = "text/plain";
            context.Response.Write("OK");
        }
    }
}
