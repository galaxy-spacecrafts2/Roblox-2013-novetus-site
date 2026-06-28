using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Roblox.Web.Mvc;

namespace Roblox.Website.Controllers
{
    [RoutePrefix("Tracker")]
    [Route("{action}.aspx")]
    [CookieConstraintAttributeWithRedirect]
    public class TrackerController : Controller
    {
        // GET: Tracker/GoogleAnalytics
        public ActionResult GoogleAnalytics()
        {
            return View();
        }
    }
}