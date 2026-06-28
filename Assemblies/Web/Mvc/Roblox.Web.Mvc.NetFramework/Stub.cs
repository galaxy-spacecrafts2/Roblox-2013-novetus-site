using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Web;
using System.Web.Routing;

namespace System.Web.Mvc
{
    public interface IController { }

    public interface IView
    {
        void Render(ViewContext viewContext, TextWriter writer);
    }

    public abstract class ActionResult
    {
        public abstract void ExecuteResult(ControllerContext context);
    }

    public class ControllerContext
    {
        public ControllerContext() { }
        public ControllerContext(RequestContext requestContext, IController controller) { }
    }

    public class ViewEngineResult
    {
        public IView View { get; set; }
        public ViewEngineResult(IView view, IViewEngine viewEngine) { View = view; }
        public ViewEngineResult(IEnumerable<string> searchedLocations) { }
    }

    public interface IViewEngine
    {
        ViewEngineResult FindPartialView(ControllerContext controllerContext, string partialViewName, bool useCache);
    }

    public class ViewEngineCollection : List<IViewEngine>
    {
        public ViewEngineResult FindPartialView(ControllerContext controllerContext, string partialViewName)
        {
            return new ViewEngineResult(new List<string>());
        }
    }

    public static class ViewEngines
    {
        public static ViewEngineCollection Engines { get; } = new ViewEngineCollection();
    }

    public class TempDataDictionary : Dictionary<string, object> { }

    public class ViewDataDictionary
    {
        public object Model { get; set; }
    }

    public class ViewContext
    {
        public ViewContext() { }
        public ViewContext(ControllerContext controllerContext, IView view,
            ViewDataDictionary viewData, TempDataDictionary tempData, TextWriter writer) { }
    }

    public class EmptyResult : ActionResult
    {
        public override void ExecuteResult(ControllerContext context) { }
    }

    public class RedirectResult : ActionResult
    {
        public string Url { get; }
        public RedirectResult(string url) { Url = url; }
        public override void ExecuteResult(ControllerContext context) { }
    }

    public class ViewResult : ActionResult
    {
        public object Model { get; set; }
        public override void ExecuteResult(ControllerContext context) { }
    }

    public class JsonResult : ActionResult
    {
        public object Data { get; set; }
        public JsonRequestBehavior JsonRequestBehavior { get; set; }
        public override void ExecuteResult(ControllerContext context) { }
    }

    public class HttpStatusCodeResult : ActionResult
    {
        public int StatusCode { get; }
        public string StatusDescription { get; }
        public HttpStatusCodeResult(HttpStatusCode statusCode) { StatusCode = (int)statusCode; }
        public HttpStatusCodeResult(HttpStatusCode statusCode, string statusDescription)
        {
            StatusCode = (int)statusCode;
            StatusDescription = statusDescription;
        }
        public HttpStatusCodeResult(int statusCode) { StatusCode = statusCode; }
        public override void ExecuteResult(ControllerContext context) { }
    }

    public class ContentResult : ActionResult
    {
        public string Content { get; set; }
        public string ContentType { get; set; }
        public override void ExecuteResult(ControllerContext context) { }
    }

    public enum JsonRequestBehavior { DenyGet, AllowGet }

    public class ModelStateDictionary
    {
        public bool IsValid { get; } = true;
        public void AddModelError(string key, string errorMessage) { }
    }

    public class FormCollection
    {
        private readonly Dictionary<string, string> _data = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        public string this[string key]
        {
            get { _data.TryGetValue(key, out var v); return v; }
            set { _data[key] = value; }
        }
    }

    public class SelectList
    {
        public SelectList(IEnumerable<object> items) { }
        public SelectList(System.Collections.IEnumerable items, string dataValueField, string dataTextField) { }
    }

    public class GlobalFilterCollection
    {
        private readonly List<object> _filters = new List<object>();
        public void Add(object filter) { _filters.Add(filter); }
    }

    public static class GlobalFilters
    {
        public static GlobalFilterCollection Filters { get; } = new GlobalFilterCollection();
    }

    public abstract class AreaRegistration
    {
        public static void RegisterAllAreas() { }
        public abstract string AreaName { get; }
        public abstract void RegisterArea(AreaRegistrationContext context);
    }

    public class AreaRegistrationContext
    {
        public RouteCollection Routes { get; }
    }

    public abstract class ViewUserControl : System.Web.UI.UserControl { }

    public abstract class ActionFilterAttribute : Attribute
    {
        public virtual void OnActionExecuting(ActionExecutingContext filterContext) { }
    }

    public class ActionExecutingContext { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class HandleErrorAttribute : ActionFilterAttribute { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class AuthorizeAttribute : ActionFilterAttribute { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class HttpPostAttribute : ActionFilterAttribute { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class HttpGetAttribute : ActionFilterAttribute { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class HttpDeleteAttribute : ActionFilterAttribute { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class HttpPutAttribute : ActionFilterAttribute { }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class RoutePrefixAttribute : Attribute
    {
        public string Prefix { get; }
        public RoutePrefixAttribute(string prefix) { Prefix = prefix; }
    }

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
    public class RouteAttribute : Attribute
    {
        public string Template { get; }
        public RouteAttribute() { }
        public RouteAttribute(string template) { Template = template; }
    }

    public abstract class Controller : IController
    {
        public HttpRequestBase Request => null;
        public HttpServerUtilityBase Server => null;
        public ModelStateDictionary ModelState { get; } = new ModelStateDictionary();
        public dynamic ViewBag { get; } = new System.Dynamic.ExpandoObject();

        protected ActionResult Redirect(string url) => new RedirectResult(url);
        protected ViewResult View() => new ViewResult();
        protected ViewResult View(object model) => new ViewResult { Model = model };
        protected JsonResult Json(object data) => new JsonResult { Data = data };
        protected JsonResult Json(object data, JsonRequestBehavior behavior) => new JsonResult { Data = data, JsonRequestBehavior = behavior };
        protected ContentResult Content(string content) => new ContentResult { Content = content };
        protected ContentResult Content(string content, string contentType) => new ContentResult { Content = content, ContentType = contentType };
    }

    public static class RouteCollectionExtensions
    {
        public static void IgnoreRoute(this RouteCollection routes, string url) { }
        public static void IgnoreRoute(this RouteCollection routes, string url, object constraints) { }
        public static void MapMvcAttributeRoutes(this RouteCollection routes) { }
        public static Route MapRoute(this RouteCollection routes, string name, string url) { return null; }
        public static Route MapRoute(this RouteCollection routes, string name, string url, object defaults) { return null; }
        public static Route MapRoute(this RouteCollection routes, string name, string url, object defaults, object constraints) { return null; }
        public static Route MapRoute(this RouteCollection routes, string name, string url, string[] namespaces) { return null; }
        public static Route MapRoute(this RouteCollection routes, string name, string url, object defaults, string[] namespaces) { return null; }
    }
}

namespace System.Web.Optimization
{
    public class Bundle
    {
        public string VirtualPath { get; }
        public Bundle(string virtualPath) { VirtualPath = virtualPath; }
        public Bundle(string virtualPath, string cdnPath) { VirtualPath = virtualPath; }
        public Bundle Include(params string[] virtualPaths) { return this; }
    }

    public class ScriptBundle : Bundle
    {
        public ScriptBundle(string virtualPath) : base(virtualPath) { }
        public ScriptBundle(string virtualPath, string cdnPath) : base(virtualPath, cdnPath) { }
    }

    public class StyleBundle : Bundle
    {
        public StyleBundle(string virtualPath) : base(virtualPath) { }
        public StyleBundle(string virtualPath, string cdnPath) : base(virtualPath, cdnPath) { }
    }

    public class BundleCollection
    {
        private readonly List<Bundle> _bundles = new List<Bundle>();
        public bool UseCdn { get; set; }
        public void Add(Bundle bundle) { _bundles.Add(bundle); }
    }

    public static class BundleTable
    {
        public static bool EnableOptimizations { get; set; }
        public static BundleCollection Bundles { get; } = new BundleCollection();
    }
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
