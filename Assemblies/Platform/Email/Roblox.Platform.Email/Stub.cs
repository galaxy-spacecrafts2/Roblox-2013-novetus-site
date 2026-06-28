// using Roblox.Platform.Membership;

namespace Roblox.Platform.Email
{
    public interface IEmailAddress
    {
        string Address { get; }
    }

    public interface IUserEmail
    {
        IEmailAddress EmailAddress { get; }
        bool IsValid { get; }
    }

    public interface IUserEmailFactory
    {
        // IUserEmail GetCurrentVerified(IUser user);
        object GetCurrentVerified(object user);
    }

    public class EmailDomainFactories
    {
        public IUserEmailFactory UserEmailFactory { get; set; }
        public EmailDomainFactories() { }
    }
}
