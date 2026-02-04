// Example usage of WebSocketServer
//
// This file demonstrates how to integrate WebSocketServer
// into the development server workflow.
//
// Basic usage:
//
// ```swift
// // Create and start the server
// let wsServer = WebSocketServer(port: 35729)
// try await wsServer.start()
//
// // Send reload message to all connected clients
// await wsServer.sendReload()
//
// // Send error message
// await wsServer.sendError("Compilation failed: syntax error")
//
// // Broadcast custom message
// await wsServer.broadcast("custom-event:data")
//
// // Check connected clients
// let count = await wsServer.clientCount()
// print("Connected clients: \(count)")
//
// // Stop the server
// await wsServer.stop()
// ```
//
// Client-side JavaScript (to be injected into the runtime):
//
// ```javascript
// // Connect to SSE endpoint
// const eventSource = new EventSource('http://localhost:35729/events');
//
// // Listen for messages
// eventSource.onmessage = (event) => {
//   const message = event.data;
//
//   if (message === 'reload') {
//     console.log('[Hot Reload] Reloading...');
//     window.location.reload();
//   } else if (message.startsWith('error:')) {
//     const error = message.substring(6);
//     console.error('[Hot Reload] Error:', error);
//     // Display error overlay
//   } else if (message === 'connected') {
//     console.log('[Hot Reload] Connected to dev server');
//   }
// };
//
// eventSource.onerror = (error) => {
//   console.error('[Hot Reload] Connection error:', error);
// };
// ```
//
// Integration with FileWatcher:
//
// ```swift
// let wsServer = WebSocketServer(port: 35729)
// try await wsServer.start()
//
// let watcher = FileWatcher(path: sourcePath) {
//   print("Files changed, recompiling...")
//
//   do {
//     // Recompile the project
//     try await compile()
//
//     // Notify clients to reload
//     await wsServer.sendReload()
//     print("Hot reload triggered")
//   } catch {
//     // Send error to clients
//     await wsServer.sendError(error.localizedDescription)
//     print("Compilation error: \(error)")
//   }
// }
//
// try await watcher.start()
// ```
