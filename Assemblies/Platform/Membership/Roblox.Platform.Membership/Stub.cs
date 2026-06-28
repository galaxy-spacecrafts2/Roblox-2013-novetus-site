using System;
using System.Collections.Generic;

namespace Roblox.Platform.Membership
{
    public enum AccountStatus
    {
        Ok = 1,
        Suppressed = 2,
        Deleted = 3
    }

    public static class AccountStatusExtensions
    {
        public static int OkId { get { return (int)AccountStatus.Ok; } }
        public static byte TranslateToByte(this AccountStatus status) { return (byte)status; }
    }

    public enum AgeBracket
    {
        AgeUnder13 = 0,
        Age13OrOver = 1
    }

    public interface IRoleSet
    {
        string Name { get; }
        long Id { get; }
    }

    public interface IUser
    {
        long Id { get; }
        string Name { get; }
        long AccountId { get; }
        DateTime Created { get; }
        AccountStatus AccountStatus { get; }
        string Description { get; }
        AgeBracket AgeBracket { get; }
    }

    public interface IUserFactory
    {
        IUser GetUserByName(string username);
        IUser GetUser(long userId);
        IUser MustGetUser(long userId);
        IUser GetCurrentUser();
    }

    public interface IRoleSetValidator
    {
        IEnumerable<IRoleSet> GetRoleSets(IUser user);
        bool IsInRole(IUser user, string roleName);
        bool IsPrivilegedUser(IUser user);
    }

    public class StubUserFactory : IUserFactory
    {
        public IUser GetUserByName(string username) { return null; }
        public IUser GetUser(long userId) { return null; }
        public IUser MustGetUser(long userId) { return null; }
        public IUser GetCurrentUser() { return null; }
    }

    public class StubRoleSetValidator : IRoleSetValidator
    {
        public System.Collections.Generic.IEnumerable<IRoleSet> GetRoleSets(IUser user) { return new IRoleSet[0]; }
        public bool IsInRole(IUser user, string roleName) { return false; }
        public bool IsPrivilegedUser(IUser user) { return false; }
    }

    public class MembershipDomainFactories
    {
        public IUserFactory UserFactory { get; set; }
        public IRoleSetValidator RoleSetValidator { get; set; }

        public MembershipDomainFactories()
        {
            UserFactory = new StubUserFactory();
            RoleSetValidator = new StubRoleSetValidator();
        }

        public MembershipDomainFactories(
            object logger = null,
            object rolesDomainFactories = null,
            object emailDomainFactories = null)
        {
            UserFactory = new StubUserFactory();
            RoleSetValidator = new StubRoleSetValidator();
        }
    }
}
