using System;
// using System.Web.Mvc;

namespace Roblox.Web.Mvc
{
    // [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    // public class CookieConstraintAttributeWithRedirect : ActionFilterAttribute
    // {
    //     public override void OnActionExecuting(ActionExecutingContext filterContext) { }
    // }
    
    public class CookieConstraintAttributeWithRedirect : Attribute
    {
        public CookieConstraintAttributeWithRedirect() { }
    }
}
