import Foundation

/// Generates JavaScript for displaying compilation errors in the browser during development
public struct ErrorOverlay: Sendable {
    public init() {}

    /// Generates the error overlay JavaScript code that can be injected into HTML
    /// - Returns: JavaScript code for error overlay functionality
    public func generateScript() -> String {
        return """
        <script>
        // Raven Error Overlay
        (function() {
            let overlay = null;

            // Create overlay element
            function createOverlay() {
                if (overlay) return;

                overlay = document.createElement('div');
                overlay.id = 'raven-error-overlay';
                overlay.style.cssText = `
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(0, 0, 0, 0.9);
                    color: #fff;
                    font-family: 'Menlo', 'Monaco', 'Courier New', monospace;
                    font-size: 14px;
                    line-height: 1.5;
                    overflow: auto;
                    z-index: 999999;
                    padding: 20px;
                    box-sizing: border-box;
                `;

                document.body.appendChild(overlay);
            }

            // Show error in overlay
            function showError(errorMessage) {
                createOverlay();

                const errorHTML = `
                    <div style="max-width: 900px; margin: 0 auto;">
                        <div style="
                            display: flex;
                            justify-content: space-between;
                            align-items: center;
                            margin-bottom: 20px;
                            padding-bottom: 15px;
                            border-bottom: 2px solid #ff6b6b;
                        ">
                            <h1 style="
                                margin: 0;
                                color: #ff6b6b;
                                font-size: 24px;
                                font-weight: 600;
                            ">
                                Build Error
                            </h1>
                            <button onclick="document.getElementById('raven-error-overlay').remove(); overlay = null;" style="
                                background: #444;
                                color: #fff;
                                border: none;
                                padding: 8px 16px;
                                border-radius: 4px;
                                cursor: pointer;
                                font-size: 14px;
                                font-family: inherit;
                            ">
                                Close (ESC)
                            </button>
                        </div>

                        <div style="
                            background: #1e1e1e;
                            border: 1px solid #ff6b6b;
                            border-radius: 6px;
                            padding: 20px;
                        ">
                            <pre style="
                                margin: 0;
                                white-space: pre-wrap;
                                word-wrap: break-word;
                                color: #ff6b6b;
                            ">${escapeHTML(errorMessage)}</pre>
                        </div>

                        <div style="
                            margin-top: 20px;
                            padding: 15px;
                            background: #2a2a2a;
                            border-radius: 6px;
                            color: #aaa;
                            font-size: 13px;
                        ">
                            <p style="margin: 0 0 10px 0;">
                                <strong style="color: #fff;">Tips:</strong>
                            </p>
                            <ul style="margin: 0; padding-left: 20px;">
                                <li>Fix the error in your Swift code</li>
                                <li>The page will automatically reload when the build succeeds</li>
                                <li>Press ESC or click Close to dismiss this overlay</li>
                            </ul>
                        </div>
                    </div>
                `;

                overlay.innerHTML = errorHTML;
            }

            // Hide overlay
            function hideOverlay() {
                if (overlay) {
                    overlay.remove();
                    overlay = null;
                }
            }

            // Escape HTML special characters
            function escapeHTML(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }

            // Listen for ESC key to close overlay
            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape' && overlay) {
                    hideOverlay();
                }
            });

            // Expose functions globally for hot reload integration
            window.__ravenErrorOverlay = {
                show: showError,
                hide: hideOverlay
            };
        })();
        </script>
        """
    }

    /// Generates a complete error overlay script with integrated hot reload client
    /// - Parameter hotReloadPort: Port number for the hot reload WebSocket server
    /// - Returns: JavaScript code for both error overlay and hot reload client
    public func generateWithHotReload(hotReloadPort: Int) -> String {
        return """
        \(generateScript())

        <script>
        // Hot reload client with error overlay integration
        (function() {
            const eventSource = new EventSource('http://localhost:\(hotReloadPort)/events');

            eventSource.addEventListener('message', function(e) {
                console.log('[Raven Dev]', e.data);

                if (e.data === 'reload') {
                    console.log('[Raven Dev] Build successful, reloading...');
                    window.__ravenErrorOverlay.hide();
                    window.location.reload();
                } else if (e.data.startsWith('error:')) {
                    const error = e.data.substring(6);
                    console.error('[Raven Dev] Build error:', error);
                    window.__ravenErrorOverlay.show(error);
                } else if (e.data === 'connected') {
                    console.log('[Raven Dev] Connected to development server');
                    window.__ravenErrorOverlay.hide();
                }
            });

            eventSource.addEventListener('error', function(e) {
                console.error('[Raven Dev] Connection error:', e);
            });

            window.addEventListener('beforeunload', function() {
                eventSource.close();
            });
        })();
        </script>
        """
    }
}
