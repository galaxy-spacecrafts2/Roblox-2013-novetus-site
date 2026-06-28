using System;
using System.Collections.Generic;
using System.Web.Security;

namespace Roblox
{
    public interface IAsset
    {
        long Id { get; }
        string Name { get; }
    }

    public interface IExceptionHandlerListener
    {
        void exceptionLogged();
    }

    public class RobloxResourceSet
    {
        public RobloxResourceSet(string resourceName) { }
        public string GetString(string key) { return string.Empty; }
    }

    public static class ExceptionHandler
    {
        public static void LogException(Exception ex) { }
    }

    public static class StaticDomainFactoriesRegistry
    {
        public static void SetDomainFactories(object emailDomainFactories) { }
    }

    public class Account
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string UserName { get; set; }
        public string Email { get; set; }

        public static MembershipUser Get(string username) { return null; }
        public static MembershipUser Get(int accountId) { return null; }

        public static IEnumerable<Account> GetAccountsByEmailAddress(string email)
        {
            return new List<Account>();
        }

        public static Account GetCurrent() { return null; }
    }

    public class User
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public long RobloxAccountID { get; set; }
        public Account RobloxAccount { get; set; }

        public static User GetCurrent() { return null; }

        public static User GetByAccountID(long accountId) { return null; }

        public static IEnumerable<User> FindUsers(int? userId, string userName, string emailAddress, int? ipAddress)
        {
            return new List<User>();
        }
    }

    public static class Signup
    {
        public static bool ValidateUserName(string username) { return true; }
        public static bool ValidateEmail(string email) { return true; }
        public static bool CheckEmailUsability(string email) { return true; }
        public static Account CreateNew(string username, string passwordHash, string email) { return new Account(); }
    }
}

namespace Roblox.Users
{
    public class UserInfo
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }

        public static UserInfo Get(long userId) { return null; }
        public static UserInfo GetByName(string name) { return null; }
    }
}
