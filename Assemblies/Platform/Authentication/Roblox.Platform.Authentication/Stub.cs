namespace Roblox.Platform.Authentication
{
    public enum CredentialsType { Username = 0, Email = 1 }

    public class Credentials
    {
        public string Value { get; set; }
        public CredentialsType CredentialsType { get; set; }
        public string Password { get; set; }
    }

    public interface ICredentialValidator
    {
        bool ValidateCredentials(Credentials credentials);
    }

    public class AuthenticationDomainFactories
    {
        public ICredentialValidator CredentialValidator { get; set; }
        public AuthenticationDomainFactories() { }
    }
}
