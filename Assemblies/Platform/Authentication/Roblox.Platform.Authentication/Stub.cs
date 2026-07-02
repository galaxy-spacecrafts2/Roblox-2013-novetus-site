namespace Roblox.Platform.Authentication
{
    public enum CredentialsType { Username = 0, Email = 1 }

    public class CredentialValidationResult
    {
        public bool IsValid { get; set; }
    }

    public class Credentials
    {
        public string Value { get; set; }
        public CredentialsType CredentialsType { get; set; }
        public string Password { get; set; }

        public Credentials() { }
        public Credentials(CredentialsType credentialsType, string value, string password)
        {
            CredentialsType = credentialsType;
            Value = value;
            Password = password;
        }
    }

    public interface ICredentialValidator
    {
        CredentialValidationResult ValidateCredentials(Credentials credentials);
    }

    public class AuthenticationDomainFactories
    {
        public ICredentialValidator CredentialValidator { get; set; }

        public AuthenticationDomainFactories() { }
        public AuthenticationDomainFactories(
            object logger = null,
            object securityDomainFactories = null,
            object membershipDomainFactories = null,
            object emailDomainFactories = null) { }
    }
}
