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
        public Logger() { }
        public Logger(string source, Func<LogLevel> getLogLevel, bool removeLineBreaks = false) { }
        public Logger(string source, Func<int> getLogLevel, bool removeLineBreaks = false) { }

        public virtual void Error(object message) { }
        public virtual void Warning(object message) { }
        public virtual void Info(object message) { }

        protected virtual void Log(LogLevel logLevel, string format, params object[] args) { }
    }

    public class ExceptionThrottlingLogger : Logger
    {
        public ExceptionThrottlingLogger() { }
        public ExceptionThrottlingLogger(ILogger inner, Func<int> getMaxCount, Func<TimeSpan> getInterval) { }
        public ExceptionThrottlingLogger(ILogger inner, Func<int> getMaxCount, Func<int> getIntervalSeconds) { }
    }

    public static class StaticLoggerRegistry
    {
        public static void SetLogger(ILogger logger) { }
    }
}
