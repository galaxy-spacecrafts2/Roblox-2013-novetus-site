using System;

namespace Roblox.Configuration
{
    public static class ConfigurationLogging
    {
        public static void OverrideDefaultConfigurationLogging(
            Action<string> error,
            Action<string> warning,
            Action<string> info) { }
    }
}
