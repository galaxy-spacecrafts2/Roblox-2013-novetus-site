using Roblox.Platform.Membership;

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

    public interface IEmailAddressFactory
    {
        IEmailAddress GetEmailAddressByAddress(string address);
    }

    public interface IUserEmailFactory
    {
        IUserEmail GetCurrentVerified(IUser user);
    }

    public class EmailDomainFactories
    {
        public IUserEmailFactory UserEmailFactory { get; set; }
        public IEmailAddressFactory EmailAddressFactory { get; set; }

        public EmailDomainFactories() { }
        public EmailDomainFactories(object logger = null) { }
    }
}
