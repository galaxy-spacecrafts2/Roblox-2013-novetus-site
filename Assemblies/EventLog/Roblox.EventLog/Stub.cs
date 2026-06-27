using System;

namespace Roblox.EventLog
{
    public interface ILogger
    {
        void Error(object message);
        void Warning(object message);
        void Info(object message);
    }

    public enum LogLevel { Info, Warning, Error }

    public class Logger : ILogger
    {
        public virtual void Error(object message) { }
        public virtual void Warning(object message) { }
        public virtual void Info(object message) { }
    }

    public class ExceptionThrottlingLogger : Logger { }

    public static class StaticLoggerRegistry
    {
        public static void SetLogger(ILogger logger) { }
    }
}
