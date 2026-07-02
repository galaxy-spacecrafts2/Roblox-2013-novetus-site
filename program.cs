// program.cs - Entry point (main AppDomain); bridges HttpListener to the ASP.NET AppDomain

using System;
using System.IO;
using System.Net;
using System.Text;
using System.Collections.Generic;
using System.Threading;
using System.Web.Hosting;
using MonoAspNetHost;

class Program {
    static void Main(string[] args) {
        string appPath   = Path.GetFullPath(args.Length > 0 ? args[0] : "RobloxWebSite");
        int    port      = args.Length > 1 ? int.Parse(args[1]) : 5000;
        string virtPath  = "/";

        Console.WriteLine("MonoAspNetHost starting...");
        Console.WriteLine("App path : " + appPath);
        Console.WriteLine("Port     : " + port);

        AppHost host;
        try {
            host = (AppHost)ApplicationHost.CreateApplicationHost(
                typeof(AppHost), virtPath, appPath);
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
                HandleRequest(host, context);
            }, ctx);
        }
    }

    static bool IsValidHost(string host) {
        if (string.IsNullOrEmpty(host)) return false;
        // Host must not contain spaces, null bytes, or control characters
        foreach (char c in host) {
            if (char.IsControl(c) || char.IsSurrogate(c)) return false;
        }
        // Basic format: host or host:port
        int colonIdx = host.LastIndexOf(':');
        string hostname;
        if (colonIdx >= 0) {
            string portStr = host.Substring(colonIdx + 1);
            int port;
            if (!int.TryParse(portStr, out port) || port < 1 || port > 65535) return false;
            hostname = host.Substring(0, colonIdx);
        } else {
            hostname = host;
        }
        // Hostname must not be empty and must not contain invalid characters
        if (string.IsNullOrEmpty(hostname)) return false;
        // Allow simple hostnames and IPs (CheckHostName returns >= 0 for valid, -1 for unknown)
        return Uri.CheckHostName(hostname) >= 0;
    }

    static void HandleRequest(AppHost host, HttpListenerContext ctx) {
        try {
            // Build serializable request snapshot in the main AppDomain
            var req = new RequestData();
            var httpReq = ctx.Request;

            req.Method       = httpReq.HttpMethod;
            req.RawUrl       = httpReq.RawUrl ?? "/";
            req.AbsPath      = httpReq.Url?.AbsolutePath ?? "/";

            // Ensure Host header is valid - critical for ASP.NET processing
            string hostHeader = httpReq.Headers["Host"];
            if (string.IsNullOrEmpty(hostHeader)) {
                // Construct host from local endpoint
                var localAddr = httpReq.LocalEndPoint?.Address?.ToString() ?? "127.0.0.1";
                var localPort = httpReq.LocalEndPoint?.Port ?? 80;
                hostHeader = (localPort == 80) ? localAddr : localAddr + ":" + localPort;
            }
            // Validate host format - it must be parseable as a URI authority
            // Replace invalid characters and ensure proper format
            if (!IsValidHost(hostHeader)) {
                var localAddr = httpReq.LocalEndPoint?.Address?.ToString() ?? "127.0.0.1";
                var localPort = httpReq.LocalEndPoint?.Port ?? 80;
                hostHeader = (localPort == 80) ? localAddr : localAddr + ":" + localPort;
            }
            req.Host = hostHeader;

            // Headers - override Host header to ensure it's valid
            var hdrList = new List<string[]>();
            foreach (string k in httpReq.Headers.Keys) {
                if (k.Equals("Host", StringComparison.OrdinalIgnoreCase)) continue; // Skip original Host
                hdrList.Add(new[] { k, httpReq.Headers[k] ?? "" });
            }
            hdrList.Add(new[] { "Host", hostHeader }); // Add validated Host header
            req.Headers = hdrList.ToArray();

            // Request body
            if (httpReq.HasEntityBody) {
                using (var ms = new MemoryStream()) {
                    httpReq.InputStream.CopyTo(ms);
                    req.Body = ms.ToArray();
                }
            }

            // Dispatch to ASP.NET AppDomain
            ResponseData resp = host.ProcessRequest(req);

            // Write response back to HttpListener
            var httpResp = ctx.Response;
            httpResp.StatusCode        = resp.StatusCode;
            httpResp.StatusDescription = resp.StatusDesc ?? "OK";

            foreach (var h in resp.Headers) {
                if (h == null || h.Length < 2) continue;
                try {
                    switch (h[0].ToLowerInvariant()) {
                        case "content-type":   httpResp.ContentType = h[1]; break;
                        case "content-length": break; // set below
                        case "transfer-encoding": break; // skip chunked etc.
                        default:
                            httpResp.Headers[h[0]] = h[1];
                            break;
                    }
                } catch { }
            }

            var body = resp.Body ?? new byte[0];
            httpResp.ContentLength64 = body.Length;
            if (body.Length > 0)
                httpResp.OutputStream.Write(body, 0, body.Length);

            httpResp.Close();

            Console.WriteLine(resp.StatusCode + " " + req.Method + " " + req.RawUrl);
        } catch (Exception ex) {
            Console.Error.WriteLine("[REQ ERR] " + ex.Message);
            try {
                ctx.Response.StatusCode = 500;
                ctx.Response.Close();
            } catch { }
        }
    }
}
