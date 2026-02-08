import Foundation
#if canImport(Network)
import Network
#endif

/// Simple HTTP server for serving static files during development
actor HTTPServer {
    /// The port to listen on
    private let port: Int

    /// The directory to serve files from
    private let serveDirectory: String

    /// Whether to inject hot reload script
    private let injectHotReload: Bool

    /// Hot reload server port
    private let hotReloadPort: Int

    /// Pre-generated HTML content to serve for index.html requests
    private let generatedHTML: String?

    /// Network listener
    #if canImport(Network)
    private var listener: NWListener?
    #endif

    /// Server running state
    private var isRunning = false

    /// MIME type mapping
    private let mimeTypes: [String: String] = [
        "html": "text/html; charset=utf-8",
        "css": "text/css; charset=utf-8",
        "js": "application/javascript; charset=utf-8",
        "wasm": "application/wasm",
        "json": "application/json; charset=utf-8",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "ico": "image/x-icon",
        "txt": "text/plain; charset=utf-8"
    ]

    /// Initialize HTTP server
    /// - Parameters:
    ///   - port: Port to listen on
    ///   - serveDirectory: Directory containing files to serve
    ///   - injectHotReload: Whether to inject hot reload script into HTML
    ///   - hotReloadPort: Port of the hot reload WebSocket server
    init(port: Int, serveDirectory: String, injectHotReload: Bool = true, hotReloadPort: Int = 35729, generatedHTML: String? = nil) {
        self.port = port
        self.serveDirectory = serveDirectory
        self.injectHotReload = injectHotReload
        self.hotReloadPort = hotReloadPort
        self.generatedHTML = generatedHTML
    }

    /// Start the HTTP server
    func start() async throws {
        #if canImport(Network)
        guard !isRunning else {
            print("[HTTPServer] Already running on port \(port)")
            return
        }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(port)))

        listener?.stateUpdateHandler = { [port] state in
            switch state {
            case .ready:
                print("[HTTPServer] Server ready on port \(port)")
            case .failed(let error):
                print("[HTTPServer] Server failed: \(error)")
            case .cancelled:
                print("[HTTPServer] Server cancelled")
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task {
                await self?.handleConnection(connection)
            }
        }

        listener?.start(queue: .main)
        isRunning = true
        #else
        throw HTTPServerError.networkFrameworkUnavailable
        #endif
    }

    /// Stop the HTTP server
    func stop() {
        #if canImport(Network)
        guard isRunning else { return }

        listener?.cancel()
        listener = nil
        isRunning = false

        print("[HTTPServer] Server stopped")
        #endif
    }

    #if canImport(Network)
    /// Handle incoming connection
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)

        // Read the HTTP request
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task {
                await self?.processRequest(connection: connection, data: data, isComplete: isComplete, error: error)
            }
        }
    }

    /// Process HTTP request
    private func processRequest(connection: NWConnection, data: Data?, isComplete: Bool, error: Error?) {
        guard error == nil, let data = data else {
            connection.cancel()
            return
        }

        guard let requestString = String(data: data, encoding: .utf8) else {
            connection.cancel()
            return
        }

        // Parse request line
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            connection.cancel()
            return
        }

        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            connection.cancel()
            return
        }

        let method = components[0]
        var path = components[1]

        // Only handle GET requests
        guard method == "GET" else {
            sendResponse(connection: connection, status: 405, statusText: "Method Not Allowed", body: nil)
            return
        }

        // Remove query string if present
        if let queryIndex = path.firstIndex(of: "?") {
            path = String(path[..<queryIndex])
        }

        // Default to index.html for root
        if path == "/" {
            path = "/index.html"
        }

        // Avoid noisy browser console errors when no favicon is present in the dev output.
        if path == "/favicon.ico" {
            let headers = """
            HTTP/1.1 204 No Content\r
            Content-Length: 0\r
            Cache-Control: no-cache, no-store, must-revalidate\r
            Connection: close\r
            \r

            """
            if let headerData = headers.data(using: .utf8) {
                connection.send(content: headerData, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            } else {
                connection.cancel()
            }
            return
        }

        // Serve generated HTML for index.html if available
        if path == "/index.html", let html = generatedHTML {
            let contentType = "text/html; charset=utf-8"
            guard let bodyData = html.data(using: .utf8) else {
                sendResponse(connection: connection, status: 500, statusText: "Internal Server Error", body: nil)
                return
            }

            let headers = """
            HTTP/1.1 200 OK\r
            Content-Type: \(contentType)\r
            Content-Length: \(bodyData.count)\r
            Cache-Control: no-cache, no-store, must-revalidate\r
            Connection: close\r
            \r

            """

            guard let headerData = headers.data(using: .utf8) else { return }

            var fullResponse = Data()
            fullResponse.append(headerData)
            fullResponse.append(bodyData)

            connection.send(content: fullResponse, completion: .contentProcessed { _ in
                connection.cancel()
            })
            return
        }

        // Construct file path
        let filePath = (serveDirectory as NSString).appendingPathComponent(path)

        // Security check: ensure file is within serve directory
        guard filePath.hasPrefix(serveDirectory) else {
            sendResponse(connection: connection, status: 403, statusText: "Forbidden", body: nil)
            return
        }

        // Check if file exists, with fallback for .wasm files from build output
        let fileManager = FileManager.default
        var resolvedFilePath = filePath
        if !fileManager.fileExists(atPath: resolvedFilePath) {
            // Fallback: check build output directory for .wasm files
            let pathExtension = (path as NSString).pathExtension
            if pathExtension == "wasm" {
                let fileName = (path as NSString).lastPathComponent
                let projectRoot = (serveDirectory as NSString).deletingLastPathComponent
                let candidatePaths = [
                    (projectRoot as NSString).appendingPathComponent(".build/wasm32-unknown-wasip1/debug/\(fileName)"),
                    (projectRoot as NSString).appendingPathComponent(".build/wasm32-unknown-wasip1/release/\(fileName)"),
                    (projectRoot as NSString).appendingPathComponent(".build/debug/\(fileName)"),
                    (projectRoot as NSString).appendingPathComponent(".build/release/\(fileName)"),
                ]

                if let found = candidatePaths.first(where: { fileManager.fileExists(atPath: $0) }) {
                    resolvedFilePath = found
                } else {
                    sendResponse(connection: connection, status: 404, statusText: "Not Found", body: nil)
                    return
                }
            } else {
                sendResponse(connection: connection, status: 404, statusText: "Not Found", body: nil)
                return
            }
        }

        // Read file
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: resolvedFilePath)) else {
            sendResponse(connection: connection, status: 500, statusText: "Internal Server Error", body: nil)
            return
        }

        // Determine content type
        let pathExtension = (path as NSString).pathExtension
        let contentType = mimeTypes[pathExtension] ?? "application/octet-stream"

        // Inject hot reload script for HTML files
        var responseData = fileData
        if injectHotReload && pathExtension == "html" {
            if let htmlString = String(data: fileData, encoding: .utf8) {
                let hotReloadScript = """

                <script>
                // Hot reload client
                (function() {
                    const eventSource = new EventSource('http://localhost:\(hotReloadPort)/events');

                    eventSource.addEventListener('message', function(e) {
                        console.log('[Hot Reload]', e.data);

                        if (e.data === 'reload' || e.data.startsWith('reload_metrics:')) {
                            console.log('[Hot Reload] Reloading page...');
                            window.location.reload();
                        } else if (e.data.startsWith('error:')) {
                            const error = e.data.substring(6);
                            console.error('[Hot Reload] Build error:', error);
                        } else if (e.data === 'connected') {
                            console.log('[Hot Reload] Connected to dev server');
                        }
                    });

                    eventSource.addEventListener('error', function(e) {
                        console.error('[Hot Reload] Connection error:', e);
                    });

                    window.addEventListener('beforeunload', function() {
                        eventSource.close();
                    });
                })();
                </script>
                """

                // Inject before closing </body> tag
                let injectedHTML = htmlString.replacingOccurrences(
                    of: "</body>",
                    with: "\(hotReloadScript)\n</body>"
                )

                if let injectedData = injectedHTML.data(using: .utf8) {
                    responseData = injectedData
                }
            }
        }

        // Send response
        let headers = """
        HTTP/1.1 200 OK\r
        Content-Type: \(contentType)\r
        Content-Length: \(responseData.count)\r
        Cache-Control: no-cache, no-store, must-revalidate\r
        Connection: close\r
        \r

        """

        guard let headerData = headers.data(using: .utf8) else {
            return
        }

        var fullResponse = Data()
        fullResponse.append(headerData)
        fullResponse.append(responseData)

        connection.send(content: fullResponse, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    /// Send HTTP response
    private func sendResponse(connection: NWConnection, status: Int, statusText: String, body: String?) {
        let bodyData = body?.data(using: .utf8) ?? Data()
        let contentLength = bodyData.count

        let headers = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: text/plain; charset=utf-8\r
        Content-Length: \(contentLength)\r
        Connection: close\r
        \r

        """

        guard let headerData = headers.data(using: .utf8) else {
            connection.cancel()
            return
        }

        var fullResponse = Data()
        fullResponse.append(headerData)
        if contentLength > 0 {
            fullResponse.append(bodyData)
        }

        connection.send(content: fullResponse, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    #endif
}

// MARK: - Errors

enum HTTPServerError: Error, LocalizedError {
    case networkFrameworkUnavailable

    var errorDescription: String? {
        switch self {
        case .networkFrameworkUnavailable:
            return "Network framework not available on this platform"
        }
    }
}
