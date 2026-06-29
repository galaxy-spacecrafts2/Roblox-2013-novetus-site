// host.cs - ASP.NET host library for Mono (compiled to MonoHost.dll)
// This DLL must live in RobloxWebSite/bin/ so the web AppDomain can find it.

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Collections.Generic;
using System.Threading;
using System.Web;
using System.Web.Hosting;

namespace MonoAspNetHost {

    [Serializable]
    public class RequestData {
        public string Method      = "GET";
        public string RawUrl      = "/";
        public string AbsPath     = "/";
        public string QueryString = "";
        public string RemoteAddr  = "127.0.0.1";
        public int    RemotePort  = 0;
        public string LocalAddr   = "127.0.0.1";
        public int    LocalPort   = 5000;
        public string ContentType = "";
        public long   ContentLen  = 0;
        public byte[] Body        = new byte[0];
        public string[][] Headers = new string[0][];
        public string Host        = "localhost";
    }

    [Serializable]
    public class ResponseData {
        public int    StatusCode  = 200;
        public string StatusDesc  = "OK";
        public List<string[]> Headers = new List<string[]>();
        public byte[] Body        = new byte[0];
    }

    public class AppHost : MarshalByRefObject {

        // Serialize initial requests so only one resource-compilation happens at a time
        private static readonly object _initLock = new object();
        private static volatile bool   _initialized = false;

        public override object InitializeLifetimeService() {
            return null;
        }

        public ResponseData ProcessRequest(RequestData req) {
            if (!_initialized) {
                // Serial execution until first successful full-pipeline request
                lock (_initLock) {
                    var resp = ProcessInner(req);
                    if (resp.StatusCode < 500) _initialized = true;
                    return resp;
                }
            }
            return ProcessInner(req);
        }

        private ResponseData ProcessInner(RequestData req) {
            var resp = new ResponseData();
            try {
                var wr = new AspWorkerRequest(req, resp);
                HttpRuntime.ProcessRequest(wr);
            } catch (Exception ex) {
                Console.Error.WriteLine("[ASPNET ERR] " + ex);
                resp.StatusCode = 500;
                resp.StatusDesc  = "Internal Server Error";
                resp.Body = Encoding.UTF8.GetBytes(
                    "<html><body><h1>500 Internal Server Error</h1><pre>" +
                    HttpUtility.HtmlEncode(ex.ToString()) +
                    "</pre></body></html>");
                resp.Headers.Add(new[] { "Content-Type", "text/html; charset=utf-8" });
            }
            return resp;
        }
    }

    public class AspWorkerRequest : HttpWorkerRequest {
        private readonly RequestData  _req;
        private readonly ResponseData _resp;
        private readonly MemoryStream _bodyBuf = new MemoryStream();
        private bool _ended = false;

        public AspWorkerRequest(RequestData req, ResponseData resp) {
            _req  = req;
            _resp = resp;
        }

        public override string GetUriPath()      => _req.AbsPath;
        public override string GetQueryString()  => _req.QueryString;
        public override string GetRawUrl()       => _req.RawUrl;
        public override string GetHttpVerbName() => _req.Method;
        public override string GetHttpVersion()  => "HTTP/1.1";
        public override string GetRemoteAddress()=> _req.RemoteAddr;
        public override int    GetRemotePort()   => _req.RemotePort;
        public override string GetLocalAddress() => _req.LocalAddr;
        public override int    GetLocalPort()    => _req.LocalPort;
        public override string GetUriScheme()    => "http";
        public override string GetServerName()   => _req.Host.Contains(":") ? _req.Host.Split(':')[0] : _req.Host;

        public override string GetAppPath()           => "/";
        public override string GetAppPathTranslated() =>
            AppDomain.CurrentDomain.GetData(".appPath") as string ?? ".";
        public override string GetFilePath()          => GetUriPath();
        public override string GetFilePathTranslated() {
            var appPath = GetAppPathTranslated();
            var uriPath = GetUriPath().Replace('/', Path.DirectorySeparatorChar);
            return Path.Combine(appPath, uriPath.TrimStart(Path.DirectorySeparatorChar));
        }
        public override string GetPathInfo() => "";

        public override string MapPath(string virtualPath) {
            string appPath = GetAppPathTranslated();
            if (string.IsNullOrEmpty(virtualPath))
                return appPath;
            // Strip leading "/" so we can combine with the physical root
            string rel = virtualPath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
            return string.IsNullOrEmpty(rel) ? appPath : Path.Combine(appPath, rel);
        }

        public override string GetKnownRequestHeader(int index) {
            string name = GetKnownRequestHeaderName(index);
            foreach (var h in _req.Headers)
                if (string.Equals(h[0], name, StringComparison.OrdinalIgnoreCase))
                    return h[1];
            return "";
        }

        public override string GetUnknownRequestHeader(string name) {
            foreach (var h in _req.Headers)
                if (string.Equals(h[0], name, StringComparison.OrdinalIgnoreCase))
                    return h[1];
            return "";
        }

        public override string[][] GetUnknownRequestHeaders() => _req.Headers;

        public override byte[] GetPreloadedEntityBody() => _req.Body ?? new byte[0];
        public override bool   IsEntireEntityBodyIsPreloaded() => true;
        public override int    ReadEntityBody(byte[] buffer, int size) => 0;

        public override string GetServerVariable(string name) {
            switch (name.ToUpperInvariant()) {
                case "HTTP_HOST":          return _req.Host;
                case "SERVER_NAME":        return _req.Host.Split(':')[0];
                case "SERVER_PORT":        return _req.LocalPort.ToString();
                case "REQUEST_METHOD":     return _req.Method;
                case "QUERY_STRING":       return _req.QueryString;
                case "CONTENT_TYPE":       return _req.ContentType;
                case "CONTENT_LENGTH":     return _req.ContentLen.ToString();
                case "PATH_INFO":          return _req.AbsPath;
                case "SCRIPT_NAME":        return _req.AbsPath;
                case "PATH_TRANSLATED":    return GetFilePathTranslated();
                case "SERVER_PROTOCOL":    return "HTTP/1.1";
                case "HTTPS":             return "off";
                case "REMOTE_ADDR":        return _req.RemoteAddr;
                case "REMOTE_HOST":        return _req.RemoteAddr;
                case "REMOTE_PORT":        return _req.RemotePort.ToString();
                case "SERVER_SOFTWARE":    return "MonoAspNetHost/1.0";
                case "APPL_PHYSICAL_PATH": return GetAppPathTranslated();
                default:                   return "";
            }
        }

        public override void SendStatus(int statusCode, string statusDescription) {
            _resp.StatusCode = statusCode;
            _resp.StatusDesc  = statusDescription ?? "OK";
        }

        public override void SendKnownResponseHeader(int index, string value) {
            _resp.Headers.Add(new[] { GetKnownResponseHeaderName(index), value });
        }

        public override void SendUnknownResponseHeader(string name, string value) {
            _resp.Headers.Add(new[] { name, value });
        }

        public override void SendResponseFromMemory(byte[] data, int length) {
            _bodyBuf.Write(data, 0, length);
        }

        public override void SendResponseFromFile(string filename, long offset, long length) {
            try {
                using (var f = File.OpenRead(filename)) {
                    if (offset > 0) f.Seek(offset, SeekOrigin.Begin);
                    var buf = new byte[65536];
                    long rem = length >= 0 ? length : long.MaxValue;
                    while (rem > 0) {
                        int n = f.Read(buf, 0, (int)Math.Min(buf.Length, rem));
                        if (n <= 0) break;
                        _bodyBuf.Write(buf, 0, n);
                        rem -= n;
                    }
                }
            } catch (Exception ex) {
                Console.Error.WriteLine("[FILE] " + ex.Message);
            }
        }

        public override void SendResponseFromFile(IntPtr handle, long offset, long length) { }

        public override void FlushResponse(bool finalFlush) {
            if (_ended) return;
            if (finalFlush) {
                _ended = true;
                _resp.Body = _bodyBuf.ToArray();
            }
        }

        public override void EndOfRequest() {
            FlushResponse(true);
        }
    }
}
