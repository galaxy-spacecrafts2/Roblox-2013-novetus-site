using System;
using System.Collections.Generic;

namespace Roblox
{
    public class Account
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }

        public static Account Get(string username) => null;
        public static Account Get(int accountId) => null;
        public static IEnumerable<Account> GetAccountsByEmailAddress(string email) => new List<Account>();
        public static Account GetCurrent() => null;
    }

    public class User
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public long RobloxAccountID { get; set; }
        public Account RobloxAccount { get; set; }

        public static User GetByAccountID(long accountId) => null;
        public static IEnumerable<User> FindUsers(
            int? userId, string userName, string emailAddress, int? ipAddress)
            => new List<User>();
    }

    public static class Signup
    {
        public static bool ValidateUserName(string username) => true;
        public static bool ValidateEmail(string email) => true;
        public static bool CheckEmailUsability(string email) => true;
        public static Account CreateNew(string username, string passwordHash, string email) => new Account();
    }
}
