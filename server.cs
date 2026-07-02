// MonoAspNetHost - Simple ASP.NET web host for Mono (replaces xsp4)
// Compile: csc /r:System.Web.dll server.cs -out:server.exe
// Run: mono server.exe <webroot> <port>

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Collections.Generic;
using System.Web;
using System.Web.Hosting;
using System.Threading;

namespace MonoAspNetHost {

    class Program {
        static void Main(string[] args) {
            string appPath = Path.GetFullPath(args.Length > 0 ? args[0] : "RobloxWebSite");
            int port = args.Length > 1 ? int.Parse(args[1]) : 5000;
            string virtualPath = "/";

            Console.WriteLine("MonoAspNetHost starting...");
            Console.WriteLine("App path : " + appPath);
            Console.WriteLine("Port     : " + port);

            AppHost host;
            try {
                host = (AppHost)ApplicationHost.CreateApplicationHost(
                    typeof(AppHost), virtualPath, appPath);
            } catch (Exception ex) {
                Console.Error.WriteLine("Failed to create application host: " + ex);
                Environment.Exit(1);
                return;
            }

            var listener = new HttpListener();
            listener.Prefixes.Add("http://+:" + port + "/");
            try {
                listener.Start();
            } catch (HttpListenerException ex) {
                Console.Error.WriteLine("Failed to start listener: " + ex.Message);
                Environment.Exit(1);
                return;
            }

            Console.WriteLine("Listening on http://localhost:" + port + "/");
            Console.WriteLine("Press Ctrl+C to stop.");

            AppDomain.CurrentDomain.ProcessExit += (s, e) => {
                listener.Stop();
            };

            while (listener.IsListening) {
                HttpListenerContext ctx;
                try {
                    ctx = listener.GetContext();
                } catch (HttpListenerException) {
                    break;
                } catch (ObjectDisposedException) {
                    break;
                }

                ThreadPool.QueueUserWorkItem(state => {
                    var context = (HttpListenerContext)state;
                    try {
                        host.ProcessRequest(context);
                    } catch (Exception ex) {
                        Console.Error.WriteLine("[ERR] " + ex.Message);
                        try {
                            context.Response.StatusCode = 500;
                            context.Response.Close();
                        } catch { }
                    }
                }, ctx);
            }
        }
    }

    public class AppHost : MarshalByRefObject {

        public override object InitializeLifetimeService() {
            return null; // Never expire
        }

        public void ProcessRequest(HttpListenerContext ctx) {
            var response = ctx.Response;
            try {
                var wr = new AspWorkerRequest(ctx);
                HttpRuntime.ProcessRequest(wr);
            } catch (Exception ex) {
                try {
                    Console.Error.WriteLine("[ASPNET ERR] " + ex);
                    response.StatusCode = 500;
                    var body = Encoding.UTF8.GetBytes(
                        "<html><body><h1>500 Internal Server Error</h1><pre>" +
                        HttpUtility.HtmlEncode(ex.ToString()) +
                        "</pre></body></html>");
                    response.ContentType = "text/html; charset=utf-8";
                    response.ContentLength64 = body.Length;
                    response.OutputStream.Write(body, 0, body.Length);
                } catch { }
                finally {
                    try { response.Close(); } catch { }
                }
            }
        }
    }

    public class AspWorkerRequest : HttpWorkerRequest {
        private readonly HttpListenerContext _ctx;
        private readonly MemoryStream _body = new MemoryStream();
        private readonly Dictionary<string, string> _responseHeaders = 
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        private int _statusCode = 200;
        private string _statusDesc = "OK";
        private bool _ended = false;

        public AspWorkerRequest(HttpListenerContext ctx) {
            _ctx = ctx;
        }

        // ---- Request information ----

        public override string GetUriPath() {
            return _ctx.Request.Url.AbsolutePath ?? "/";
        }

        public override string GetQueryString() {
            var q = _ctx.Request.Url.Query;
            return q != null && q.StartsWith("?") ? q.Substring(1) : (q ?? "");
        }

        public override string GetRawUrl() {
            return _ctx.Request.RawUrl ?? "/";
        }

        public override string GetHttpVerbName() {
            return _ctx.Request.HttpMethod;
        }

        public override string GetHttpVersion() {
            return "HTTP/1.1";
        }

        public override string GetRemoteAddress() {
            return _ctx.Request.RemoteEndPoint?.Address?.ToString() ?? "127.0.0.1";
        }

        public override int GetRemotePort() {
            return _ctx.Request.RemoteEndPoint?.Port ?? 0;
        }

        public override string GetLocalAddress() {
            return _ctx.Request.LocalEndPoint?.Address?.ToString() ?? "127.0.0.1";
        }

        public override int GetLocalPort() {
            return _ctx.Request.LocalEndPoint?.Port ?? 5000;
        }

        public override string GetServerName() {
            return _ctx.Request.Headers["Host"]?.Split(':')[0] ?? "localhost";
        }

        public override string GetAppPath() {
            return "/";
        }

        public override string GetAppPathTranslated() {
            return AppDomain.CurrentDomain.GetData(".appPath") as string ?? ".";
        }

        public override string GetFilePath() {
            return GetUriPath();
        }

        public override string GetFilePathTranslated() {
            var appPath = GetAppPathTranslated();
            var uriPath = GetUriPath().Replace('/', Path.DirectorySeparatorChar);
            return Path.Combine(appPath, uriPath.TrimStart(Path.DirectorySeparatorChar));
        }

        public override string GetPathInfo() {
            return "";
        }

        public override string GetKnownRequestHeader(int index) {
            string name = GetKnownRequestHeaderName(index);
            return _ctx.Request.Headers[name] ?? "";
        }

        public override string GetUnknownRequestHeader(string name) {
            return _ctx.Request.Headers[name] ?? "";
        }

        public override string[][] GetUnknownRequestHeaders() {
            var list = new List<string[]>();
            foreach (string key in _ctx.Request.Headers.Keys) {
                list.Add(new[] { key, _ctx.Request.Headers[key] ?? "" });
            }
            return list.ToArray();
        }

        public override byte[] GetPreloadedEntityBody() {
            if (!_ctx.Request.HasEntityBody)
                return Array.Empty<byte>();
            var ms = new MemoryStream();
            _ctx.Request.InputStream.CopyTo(ms);
            return ms.ToArray();
        }

        public override bool IsEntireEntityBodyIsPreloaded() {
            return true;
        }

        public override int ReadEntityBody(byte[] buffer, int size) {
            return 0;
        }

        public override string GetServerVariable(string name) {
            switch (name.ToUpperInvariant()) {
                case "HTTP_HOST":        return _ctx.Request.Headers["Host"] ?? "localhost";
                case "SERVER_NAME":      return GetServerName();
                case "SERVER_PORT":      return GetLocalPort().ToString();
                case "REQUEST_METHOD":   return _ctx.Request.HttpMethod;
                case "QUERY_STRING":     return GetQueryString();
                case "CONTENT_TYPE":     return _ctx.Request.ContentType ?? "";
                case "CONTENT_LENGTH":   return _ctx.Request.ContentLength64.ToString();
                case "PATH_INFO":        return GetUriPath();
                case "SCRIPT_NAME":      return GetUriPath();
                case "PATH_TRANSLATED":  return GetFilePathTranslated();
                case "SERVER_PROTOCOL":  return "HTTP/1.1";
                case "HTTPS":            return "off";
                case "REMOTE_ADDR":      return GetRemoteAddress();
                case "REMOTE_HOST":      return GetRemoteAddress();
                case "REMOTE_PORT":      return GetRemotePort().ToString();
                case "SERVER_SOFTWARE":  return "MonoAspNetHost/1.0";
                case "APPL_PHYSICAL_PATH": return GetAppPathTranslated();
                default:                 return "";
            }
        }

        // ---- Response ----

        public override void SendStatus(int statusCode, string statusDescription) {
            _statusCode = statusCode;
            _statusDesc = statusDescription ?? "OK";
        }

        public override void SendKnownResponseHeader(int index, string value) {
            _responseHeaders[GetKnownResponseHeaderName(index)] = value;
        }

        public override void SendUnknownResponseHeader(string name, string value) {
            _responseHeaders[name] = value;
        }

        public override void SendResponseFromMemory(byte[] data, int length) {
            _body.Write(data, 0, length);
        }

        public override void SendResponseFromFile(string filename, long offset, long length) {
            try {
                using (var f = File.OpenRead(filename)) {
                    if (offset > 0) f.Seek(offset, SeekOrigin.Begin);
                    var buf = new byte[65536];
                    long remaining = length >= 0 ? length : long.MaxValue;
                    while (remaining > 0) {
                        int toRead = (int)Math.Min(buf.Length, remaining);
                        int read = f.Read(buf, 0, toRead);
                        if (read <= 0) break;
                        _body.Write(buf, 0, read);
                        remaining -= read;
                    }
                }
            } catch (Exception ex) {
                Console.Error.WriteLine("[FILE] " + ex.Message);
            }
        }

        public override void SendResponseFromFile(IntPtr handle, long offset, long length) {
            // Not implemented for IntPtr handle
        }

        public override void FlushResponse(bool finalFlush) {
            if (_ended) return;
            if (finalFlush) {
                _ended = true;
                var data = _body.ToArray();
                try {
                    _ctx.Response.StatusCode = _statusCode;
                    _ctx.Response.StatusDescription = _statusDesc;
                    foreach (var kv in _responseHeaders) {
                        try {
                            _ctx.Response.Headers[kv.Key] = kv.Value;
                        } catch { }
                    }
                    if (!_responseHeaders.ContainsKey("Content-Length")) {
                        _ctx.Response.ContentLength64 = data.Length;
                    }
                    _ctx.Response.OutputStream.Write(data, 0, data.Length);
                } catch (Exception ex) {
                    Console.Error.WriteLine("[FLUSH] " + ex.Message);
                } finally {
                    try { _ctx.Response.Close(); } catch { }
                }
            }
        }

        public override void EndOfRequest() {
            FlushResponse(true);
        }
    }
}
