import Foundation
#if canImport(Network)
import Network
#endif

/// Simple Server-Sent Events (SSE) server for hot reload communication.
/// Uses HTTP with SSE protocol for one-way server-to-client messaging.
actor WebSocketServer {
    /// Server port
    private let port: Int

    /// Network listener
    #if canImport(Network)
    private var listener: NWListener?
    #endif

    /// Connected clients
    private var clients: [Client] = []

    /// Client identifier counter
    private var nextClientID: Int = 0

    /// Server running state
    private var isRunning = false

    /// Represents a connected SSE client
    private struct Client: Sendable {
        let id: Int
        #if canImport(Network)
        let connection: NWConnection
        #endif
    }

    /// Initialize the WebSocket server (using SSE)
    /// - Parameter port: Port to listen on (default: 35729 - LiveReload standard)
    init(port: Int = 35729) {
        self.port = port
    }

    /// Start the SSE server
    func start() async throws {
        #if canImport(Network)
        guard !isRunning else {
            print("[WebSocketServer] Already running on port \(port)")
            return
        }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(port)))

        listener?.stateUpdateHandler = { [port] state in
            switch state {
            case .ready:
                print("[WebSocketServer] Server ready on port \(port)")
            case .failed(let error):
                print("[WebSocketServer] Server failed: \(error)")
            case .cancelled:
                print("[WebSocketServer] Server cancelled")
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task {
                await self?.handleNewConnection(connection)
            }
        }

        listener?.start(queue: .main)
        isRunning = true
        print("[WebSocketServer] Started SSE server on port \(port)")
        #else
        throw NSError(domain: "WebSocketServer", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Network framework not available on this platform"
        ])
        #endif
    }

    /// Stop the SSE server
    func stop() {
        #if canImport(Network)
        guard isRunning else { return }

        // Close all client connections
        for client in clients {
            client.connection.cancel()
        }
        clients.removeAll()

        // Stop listener
        listener?.cancel()
        listener = nil
        isRunning = false

        print("[WebSocketServer] Server stopped")
        #endif
    }

    #if canImport(Network)
    /// Handle a new client connection
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .main)

        // Read the HTTP request
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            Task {
                await self?.processHTTPRequest(connection: connection, data: data, isComplete: isComplete, error: error)
            }
        }
    }

    /// Process incoming HTTP request
    private func processHTTPRequest(connection: NWConnection, data: Data?, isComplete: Bool, error: Error?) {
        guard error == nil, let data = data else {
            connection.cancel()
            return
        }

        guard let request = String(data: data, encoding: .utf8) else {
            connection.cancel()
            return
        }

        // Check if this is a GET request to /events (SSE endpoint)
        if request.starts(with: "GET /events") || request.starts(with: "GET / ") {
            // Send SSE headers
            let headers = """
            HTTP/1.1 200 OK\r
            Content-Type: text/event-stream\r
            Cache-Control: no-cache\r
            Connection: keep-alive\r
            Access-Control-Allow-Origin: *\r
            \r

            """

            guard let headerData = headers.data(using: .utf8) else {
                connection.cancel()
                return
            }

            connection.send(content: headerData, completion: .contentProcessed { error in
                if let error = error {
                    print("[WebSocketServer] Failed to send headers: \(error)")
                    connection.cancel()
                    return
                }

                // Add client to list
                Task {
                    await self.addClient(connection)
                }
            })
        } else if request.starts(with: "GET /health") {
            // Health check endpoint
            let response = """
            HTTP/1.1 200 OK\r
            Content-Type: text/plain\r
            Content-Length: 2\r
            \r
            OK
            """

            if let responseData = response.data(using: .utf8) {
                connection.send(content: responseData, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        } else {
            // Unknown request
            let response = """
            HTTP/1.1 404 Not Found\r
            Content-Length: 0\r
            \r

            """

            if let responseData = response.data(using: .utf8) {
                connection.send(content: responseData, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    /// Add a new client connection
    private func addClient(_ connection: NWConnection) {
        let clientID = nextClientID
        nextClientID += 1

        let client = Client(id: clientID, connection: connection)
        clients.append(client)

        print("[WebSocketServer] Client \(clientID) connected (total: \(clients.count))")

        // Send initial connection message
        Task {
            await sendToClient(client, message: "connected")
        }

        // Monitor connection state
        connection.stateUpdateHandler = { [weak self] state in
            Task {
                await self?.handleConnectionStateChange(clientID: clientID, state: state)
            }
        }
    }

    /// Handle connection state changes
    private func handleConnectionStateChange(clientID: Int, state: NWConnection.State) {
        switch state {
        case .cancelled, .failed:
            removeClient(clientID: clientID)
        default:
            break
        }
    }

    /// Remove a client connection
    private func removeClient(clientID: Int) {
        clients.removeAll { $0.id == clientID }
        print("[WebSocketServer] Client \(clientID) disconnected (total: \(clients.count))")
    }

    /// Send a message to a specific client
    private func sendToClient(_ client: Client, message: String) {
        let sseMessage = "data: \(message)\n\n"
        guard let data = sseMessage.data(using: .utf8) else { return }

        client.connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("[WebSocketServer] Failed to send to client \(client.id): \(error)")
            }
        })
    }
    #endif

    /// Broadcast a message to all connected clients
    /// - Parameter message: Message to broadcast
    func broadcast(_ message: String) async {
        #if canImport(Network)
        guard isRunning else { return }

        print("[WebSocketServer] Broadcasting to \(clients.count) clients: \(message)")

        for client in clients {
            sendToClient(client, message: message)
        }
        #endif
    }

    /// Send reload message to all clients
    func sendReload() async {
        await broadcast("reload")
    }

    /// Send reload notification with metadata
    /// - Parameters:
    ///   - buildTime: Time taken to build in seconds
    ///   - changeDescription: Description of what changed
    func sendReloadWithMetrics(buildTime: Double, changeDescription: String = "Source files") async {
        let message = "reload_metrics:\(buildTime):\(changeDescription)"
        await broadcast(message)
    }

    /// Send error message to all clients
    /// - Parameter error: Error message to send
    func sendError(_ error: String) async {
        // Escape newlines and quotes for JSON-like format
        let escapedError = error
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        await broadcast("error:\(escapedError)")
    }

    /// Send notification message to clients
    /// - Parameter message: Notification message
    func sendNotification(_ message: String) async {
        await broadcast("notification:\(message)")
    }

    /// Get the number of connected clients
    func clientCount() -> Int {
        return clients.count
    }
}
