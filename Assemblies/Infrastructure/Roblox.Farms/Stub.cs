namespace Roblox.Farms
{
    public abstract class KeepAlive
    {
        public abstract void ProcessRequest(System.Web.HttpContext context);
        public virtual bool IsReusable => false;
    }
}
