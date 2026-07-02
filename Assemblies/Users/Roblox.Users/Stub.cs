using System;

namespace Roblox.Users.Entities
{
    public class AccountStatus
    {
        public byte ID { get; set; }
        public string Value { get; set; }
        public static AccountStatus Ok => new AccountStatus { Value = "Ok", ID = 1 };
        public static AccountStatus MustGet(byte id) => new AccountStatus { ID = id };
    }

    public class Account
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public byte AccountStatusID { get; set; }
        public AccountStatus AccountStatus { get; set; }

        public static Account MustGet(long accountId) => new Account { ID = accountId };
        public void Save() { }
    }

    public class User
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public long AccountID { get; set; }

        public static User MustGet(long userId) => new User { ID = userId };
    }
}
