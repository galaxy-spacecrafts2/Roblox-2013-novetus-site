using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
// using Roblox.Platform.Membership; // Platform assembly not found
// using Roblox.Platform.Roles; // Platform assembly not found
// using Roblox.Platform.Email; // Platform assembly not found

namespace Roblox.Website.Admi
{
    public partial class Test : System.Web.UI.Page
    {
        // private static MembershipDomainFactories _factories; // Not found

        // public IUser IUser { get; private set; } // IUser not found
        // public IRoleSet IRoleSet { get; private set; } // IRoleSet not found
        // public IUserEmail IUserEmail { get; private set; } // IUserEmail not found
        // public ICollection<AssetType> AssetTypes { get; private set; } // AssetType not found

        // static Test()
        // {
        //     _factories = Global.MembershipDomainFactories;
        // }

        protected void Page_Load(object sender, EventArgs e)
        {
            // IUser = _factories.UserFactory.GetCurrentUser();
            // var isPriveleged = _factories.RoleSetValidator.IsPrivilegedUser(IUser);

            // Only show this page to privileged users
            // if (!isPriveleged)
            //     Response.Redirect("~/", true);

            // GridView1.DataSource = new List<IUser> { IUser };

            // IRoleSet = _factories.RoleSetValidator.GetHighestRoleSet(IUser);
            // GridView2.DataSource = _factories.RoleSetValidator.GetRoleSets(IUser);

            // IUserEmail = Global.EmailDomainFactories.UserEmailFactory.GetCurrentVerified(IUser);
            // GridView3.DataSource = new List<IEmailAddress> { IUserEmail.EmailAddress };

            // AssetTypes = AssetType.GetAssetTypes();
            // GridView4.DataSource = AssetTypes;

            // DataBind();
        }
    }
}
