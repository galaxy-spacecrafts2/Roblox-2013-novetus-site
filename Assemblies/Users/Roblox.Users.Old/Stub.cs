namespace Roblox.Users.Old { }

namespace Roblox.Users
{
    public class UserInfo
    {
        public long ID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }

        public static UserInfo Get(long userId) { return null; }
        public static UserInfo GetByName(string name) { return null; }
        public static System.Collections.Generic.IEnumerable<UserInfo> GetAll() { return new System.Collections.Generic.List<UserInfo>(); }
    }
}
