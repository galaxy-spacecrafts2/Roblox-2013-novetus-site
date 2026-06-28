using System;

namespace System.Web.Mvc
{
    public abstract class ActionFilterAttribute : Attribute
    {
        public virtual void OnActionExecuting(ActionExecutingContext filterContext) { }
    }

    public class ActionExecutingContext { }

    public abstract class Controller { }
}

namespace Roblox.Web.Mvc
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class CookieConstraintAttributeWithRedirectAttribute : System.Web.Mvc.ActionFilterAttribute
    {
        public override void OnActionExecuting(System.Web.Mvc.ActionExecutingContext filterContext) { }
    }

    public class BaseActionFilterAttribute : System.Web.Mvc.ActionFilterAttribute
    {
        public override void OnActionExecuting(System.Web.Mvc.ActionExecutingContext filterContext) { }
    }

    public class ReplicatedCssControllerBase : System.Web.Mvc.Controller { }
}
