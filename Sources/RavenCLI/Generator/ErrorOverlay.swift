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

                // Parse stack trace if available
                const lines = errorMessage.split('\\n');
                let mainError = errorMessage;
                let stackTrace = null;

                // Try to extract stack trace (lines starting with "at ")
                const stackIndex = lines.findIndex(line => line.trim().startsWith('at '));
                if (stackIndex > 0) {
                    mainError = lines.slice(0, stackIndex).join('\\n');
                    stackTrace = lines.slice(stackIndex).join('\\n');
                }

                const errorHTML = `
                    <div style="max-width: 1100px; margin: 0 auto;">
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
                                🔴 Build Error
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
                                transition: background 0.2s;
                            " onmouseover="this.style.background='#555'" onmouseout="this.style.background='#444'">
                                Close (ESC)
                            </button>
                        </div>

                        <div style="
                            background: #1e1e1e;
                            border: 1px solid #ff6b6b;
                            border-radius: 6px;
                            padding: 20px;
                            margin-bottom: 15px;
                        ">
                            <pre style="
                                margin: 0;
                                white-space: pre-wrap;
                                word-wrap: break-word;
                                color: #ff6b6b;
                                font-size: 13px;
                                line-height: 1.6;
                            ">${escapeHTML(mainError)}</pre>
                        </div>

                        ${stackTrace ? `
                        <details style="
                            background: #1e1e1e;
                            border: 1px solid #555;
                            border-radius: 6px;
                            padding: 15px;
                            margin-bottom: 15px;
                        ">
                            <summary style="
                                cursor: pointer;
                                color: #fff;
                                font-weight: 600;
                                user-select: none;
                            ">
                                📋 Stack Trace
                            </summary>
                            <pre style="
                                margin: 10px 0 0 0;
                                white-space: pre-wrap;
                                word-wrap: break-word;
                                color: #aaa;
                                font-size: 12px;
                                line-height: 1.5;
                            ">${escapeHTML(stackTrace)}</pre>
                        </details>
                        ` : ''}

                        <div style="
                            display: grid;
                            grid-template-columns: 1fr 1fr;
                            gap: 15px;
                            margin-bottom: 15px;
                        ">
                            <div style="
                                padding: 15px;
                                background: #2a2a2a;
                                border-radius: 6px;
                                border-left: 3px solid #4caf50;
                            ">
                                <strong style="color: #4caf50; display: block; margin-bottom: 8px;">✓ Auto-Reload</strong>
                                <span style="color: #aaa; font-size: 13px;">
                                    Page will reload automatically when the build succeeds
                                </span>
                            </div>
                            <div style="
                                padding: 15px;
                                background: #2a2a2a;
                                border-radius: 6px;
                                border-left: 3px solid #2196f3;
                            ">
                                <strong style="color: #2196f3; display: block; margin-bottom: 8px;">⌨️ Keyboard Shortcuts</strong>
                                <span style="color: #aaa; font-size: 13px;">
                                    Press <kbd style="background: #333; padding: 2px 6px; border-radius: 3px;">ESC</kbd> to dismiss
                                </span>
                            </div>
                        </div>

                        <div style="
                            padding: 15px;
                            background: #2a2a2a;
                            border-radius: 6px;
                            color: #aaa;
                            font-size: 13px;
                        ">
                            <p style="margin: 0 0 10px 0;">
                                <strong style="color: #fff;">💡 Common Solutions:</strong>
                            </p>
                            <ul style="margin: 0; padding-left: 20px; line-height: 1.8;">
                                <li>Check syntax errors in your Swift code</li>
                                <li>Verify all imports are correct (e.g., <code style="background: #333; padding: 2px 6px; border-radius: 3px;">import Raven</code>)</li>
                                <li>Ensure View protocol requirements are met</li>
                                <li>Check that async/await is used correctly</li>
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
        // Hot reload client with error overlay integration and state preservation
        (function() {
            const eventSource = new EventSource('http://localhost:\(hotReloadPort)/events');

            // State preservation system
            const statePreservation = {
                // Save current state before reload
                saveState: function() {
                    try {
                        const state = {
                            scrollPosition: {
                                x: window.scrollX,
                                y: window.scrollY
                            },
                            formData: this.captureFormData(),
                            timestamp: Date.now()
                        };
                        sessionStorage.setItem('__raven_dev_state', JSON.stringify(state));
                    } catch (e) {
                        console.warn('[Raven Dev] Could not save state:', e);
                    }
                },

                // Restore state after reload
                restoreState: function() {
                    try {
                        const saved = sessionStorage.getItem('__raven_dev_state');
                        if (!saved) return;

                        const state = JSON.parse(saved);

                        // Restore scroll position
                        if (state.scrollPosition) {
                            window.scrollTo(state.scrollPosition.x, state.scrollPosition.y);
                        }

                        // Restore form data
                        if (state.formData) {
                            this.restoreFormData(state.formData);
                        }

                        console.log('[Raven Dev] State restored from', new Date(state.timestamp).toLocaleTimeString());

                        // Clear after restoration
                        sessionStorage.removeItem('__raven_dev_state');
                    } catch (e) {
                        console.warn('[Raven Dev] Could not restore state:', e);
                    }
                },

                // Capture all form input values
                captureFormData: function() {
                    const formData = {};
                    document.querySelectorAll('input, textarea, select').forEach(el => {
                        if (el.id || el.name) {
                            const key = el.id || el.name;
                            if (el.type === 'checkbox' || el.type === 'radio') {
                                formData[key] = el.checked;
                            } else {
                                formData[key] = el.value;
                            }
                        }
                    });
                    return formData;
                },

                // Restore form input values
                restoreFormData: function(formData) {
                    Object.keys(formData).forEach(key => {
                        const el = document.getElementById(key) || document.getElementsByName(key)[0];
                        if (el) {
                            if (el.type === 'checkbox' || el.type === 'radio') {
                                el.checked = formData[key];
                            } else {
                                el.value = formData[key];
                            }
                        }
                    });
                }
            };

            // Performance metrics tracking
            let reloadMetrics = {
                totalReloads: 0,
                lastReloadTime: null,
                averageBuildTime: 0,
                buildTimes: []
            };

            // Show reload notification
            function showReloadNotification(message, duration = 3000) {
                const notification = document.createElement('div');
                notification.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    background: linear-gradient(135deg, #4caf50, #45a049);
                    color: white;
                    padding: 12px 20px;
                    border-radius: 8px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
                    font-family: 'Menlo', 'Monaco', monospace;
                    font-size: 13px;
                    z-index: 1000000;
                    opacity: 0;
                    transition: opacity 0.3s;
                    pointer-events: none;
                `;
                notification.textContent = message;
                document.body.appendChild(notification);

                // Fade in
                requestAnimationFrame(() => {
                    notification.style.opacity = '1';
                });

                // Fade out and remove
                setTimeout(() => {
                    notification.style.opacity = '0';
                    setTimeout(() => notification.remove(), 300);
                }, duration);
            }

            // Restore state on page load
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => {
                    statePreservation.restoreState();
                });
            } else {
                statePreservation.restoreState();
            }

            eventSource.addEventListener('message', function(e) {
                console.log('[Raven Dev]', e.data);

                if (e.data === 'reload') {
                    console.log('[Raven Dev] Build successful, reloading...');
                    window.__ravenErrorOverlay.hide();
                    statePreservation.saveState();
                    window.location.reload();
                } else if (e.data.startsWith('reload_metrics:')) {
                    // Parse reload with metrics: reload_metrics:buildTime:description
                    const parts = e.data.substring(15).split(':');
                    const buildTime = parseFloat(parts[0]);
                    const description = parts[1] || 'Source files';

                    // Update metrics
                    reloadMetrics.totalReloads++;
                    reloadMetrics.lastReloadTime = Date.now();
                    reloadMetrics.buildTimes.push(buildTime);
                    if (reloadMetrics.buildTimes.length > 10) {
                        reloadMetrics.buildTimes.shift();
                    }
                    reloadMetrics.averageBuildTime =
                        reloadMetrics.buildTimes.reduce((a, b) => a + b, 0) / reloadMetrics.buildTimes.length;

                    console.log('[Raven Dev] Build successful in ' + buildTime.toFixed(2) + 's, reloading...');
                    showReloadNotification(`🔄 Rebuilt in ${buildTime.toFixed(2)}s`);

                    window.__ravenErrorOverlay.hide();
                    statePreservation.saveState();

                    // Slight delay for notification visibility
                    setTimeout(() => window.location.reload(), 300);
                } else if (e.data.startsWith('error:')) {
                    const error = e.data.substring(6);
                    console.error('[Raven Dev] Build error:', error);
                    window.__ravenErrorOverlay.show(error);
                } else if (e.data.startsWith('notification:')) {
                    const message = e.data.substring(13);
                    showReloadNotification(message, 2000);
                } else if (e.data === 'connected') {
                    console.log('[Raven Dev] Connected to development server');
                    window.__ravenErrorOverlay.hide();
                    showReloadNotification('✓ Connected to dev server', 2000);
                }
            });

            eventSource.addEventListener('error', function(e) {
                console.error('[Raven Dev] Connection error:', e);
            });

            window.addEventListener('beforeunload', function() {
                eventSource.close();
            });

            // Expose metrics API
            window.__ravenReloadMetrics = {
                get: () => reloadMetrics,
                reset: () => {
                    reloadMetrics = {
                        totalReloads: 0,
                        lastReloadTime: null,
                        averageBuildTime: 0,
                        buildTimes: []
                    };
                }
            };
        })();
        </script>
        """
    }
}
