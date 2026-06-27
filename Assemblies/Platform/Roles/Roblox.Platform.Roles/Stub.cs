using System.Collections.Generic;
using Roblox.Platform.Membership;

namespace Roblox.Platform.Roles
{
    public interface IRoleSet
    {
        string Name { get; }
        long Id { get; }
    }

    public interface IRoleSetReader
    {
        IRoleSet GetRoleSet(string roleName);
        IEnumerable<IRoleSet> GetAllRoleSets();
        IRoleSet GetHighestRoleSetForAccountId(long accountId);
    }

    public class RolesDomainFactories
    {
        public IRoleSetReader RoleSetReader { get; set; }
        public IRoleSetValidator RoleSetValidator { get; set; }

        public RolesDomainFactories() { }
    }
}
