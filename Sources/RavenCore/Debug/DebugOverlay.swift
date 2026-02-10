import Foundation

#if DEBUG

/// Debug overlay that displays real-time performance metrics and diagnostics
/// Only active in DEBUG builds
@MainActor
public final class DebugOverlay: Sendable {

    /// Shared instance
    public static let shared = DebugOverlay()

    /// Whether the overlay is currently visible
    private var isVisible = false

    /// Overlay DOM element ID
    private let overlayID = "__raven_debug_overlay"

    /// Metrics update timer
    private var updateTask: Task<Void, Never>?

    /// Performance metrics
    private struct Metrics: Sendable {
        var fps: Double = 0
        var vnodeCount: Int = 0
        var domNodeCount: Int = 0
        var renderTime: Double = 0
        var memoryUsage: Double = 0
        var lastUpdateTime: Date = Date()
    }

    private var metrics = Metrics()

    private init() {
        setupKeyboardShortcut()
    }

    // MARK: - Public API

    /// Toggle the debug overlay visibility
    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    /// Show the debug overlay
    public func show() {
        guard !isVisible else { return }
        isVisible = true

        createOverlay()
        startMetricsUpdates()
    }

    /// Hide the debug overlay
    public func hide() {
        guard isVisible else { return }
        isVisible = false

        removeOverlay()
        stopMetricsUpdates()
    }

    /// Update FPS metric
    public func updateFPS(_ fps: Double) {
        metrics.fps = fps
    }

    /// Update VNode count
    public func updateVNodeCount(_ count: Int) {
        metrics.vnodeCount = count
    }

    /// Update DOM node count
    public func updateDOMNodeCount(_ count: Int) {
        metrics.domNodeCount = count
    }

    /// Update render time
    public func updateRenderTime(_ milliseconds: Double) {
        metrics.renderTime = milliseconds
    }

    /// Update memory usage
    public func updateMemoryUsage(_ megabytes: Double) {
        metrics.memoryUsage = megabytes
    }

    // MARK: - Private Implementation

    private func setupKeyboardShortcut() {
        // Register keyboard shortcut (Cmd+Shift+D)
        let script = """
        if (!window.__ravenDebugShortcutRegistered) {
            window.__ravenDebugShortcutRegistered = true;

            document.addEventListener('keydown', function(e) {
                // Cmd+Shift+D on Mac, Ctrl+Shift+D on others
                if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'D') {
                    e.preventDefault();
                    window.__ravenDebugOverlay?.toggle();
                }
            });
        }
        """

        executeJavaScript(script)
    }

    private func createOverlay() {
        let overlayHTML = generateOverlayHTML()

        let script = """
        (function() {
            // Remove existing overlay if present
            const existing = document.getElementById('\(overlayID)');
            if (existing) existing.remove();

            // Create new overlay
            const overlay = document.createElement('div');
            overlay.id = '\(overlayID)';
            overlay.innerHTML = `\(overlayHTML)`;
            document.body.appendChild(overlay);

            // Expose toggle function
            if (!window.__ravenDebugOverlay) {
                window.__ravenDebugOverlay = {
                    toggle: function() {
                        const overlay = document.getElementById('\(overlayID)');
                        if (overlay) {
                            overlay.style.display = overlay.style.display === 'none' ? 'block' : 'none';
                        }
                    },
                    update: function(metrics) {
                        const overlay = document.getElementById('\(overlayID)');
                        if (!overlay) return;

                        const updateMetric = (id, value) => {
                            const el = overlay.querySelector('#' + id);
                            if (el) el.textContent = value;
                        };

                        updateMetric('debug-fps', metrics.fps.toFixed(1) + ' FPS');
                        updateMetric('debug-vnodes', metrics.vnodeCount.toLocaleString());
                        updateMetric('debug-domnodes', metrics.domNodeCount.toLocaleString());
                        updateMetric('debug-rendertime', metrics.renderTime.toFixed(2) + ' ms');
                        updateMetric('debug-memory', metrics.memoryUsage.toFixed(2) + ' MB');

                        // Update FPS color based on performance
                        const fpsEl = overlay.querySelector('#debug-fps');
                        if (fpsEl) {
                            if (metrics.fps >= 55) {
                                fpsEl.style.color = '#4caf50';
                            } else if (metrics.fps >= 30) {
                                fpsEl.style.color = '#ff9800';
                            } else {
                                fpsEl.style.color = '#f44336';
                            }
                        }

                        // Update render time color based on frame budget
                        const renderEl = overlay.querySelector('#debug-rendertime');
                        if (renderEl) {
                            if (metrics.renderTime < 16.67) {
                                renderEl.style.color = '#4caf50';
                            } else if (metrics.renderTime < 33.33) {
                                renderEl.style.color = '#ff9800';
                            } else {
                                renderEl.style.color = '#f44336';
                            }
                        }
                    }
                };
            }
        })();
        """

        executeJavaScript(script)
    }

    private func removeOverlay() {
        let script = """
        const overlay = document.getElementById('\(overlayID)');
        if (overlay) overlay.remove();
        """

        executeJavaScript(script)
    }

    private func generateOverlayHTML() -> String {
        return """
        <div style="
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(10px);
            color: white;
            font-family: 'SF Mono', 'Menlo', 'Monaco', monospace;
            font-size: 12px;
            padding: 16px;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
            z-index: 999998;
            min-width: 200px;
            user-select: none;
            border: 1px solid rgba(255, 255, 255, 0.1);
        ">
            <div style="
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 12px;
                padding-bottom: 8px;
                border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            ">
                <div style="
                    font-weight: 600;
                    font-size: 13px;
                    color: #64b5f6;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                ">
                    <span style="font-size: 16px;">🔍</span>
                    <span>Raven Debug</span>
                </div>
                <button onclick="window.__ravenDebugOverlay.toggle()" style="
                    background: rgba(255, 255, 255, 0.1);
                    border: none;
                    color: white;
                    cursor: pointer;
                    padding: 4px 8px;
                    border-radius: 4px;
                    font-size: 11px;
                    transition: background 0.2s;
                " onmouseover="this.style.background='rgba(255,255,255,0.2)'" onmouseout="this.style.background='rgba(255,255,255,0.1)'">
                    ×
                </button>
            </div>

            <div style="display: flex; flex-direction: column; gap: 10px;">
                <div style="display: grid; grid-template-columns: auto 1fr; gap: 8px 12px; align-items: center;">
                    <div style="color: rgba(255, 255, 255, 0.6);">FPS:</div>
                    <div id="debug-fps" style="text-align: right; font-weight: 600; color: #4caf50;">60.0 FPS</div>

                    <div style="color: rgba(255, 255, 255, 0.6);">VNodes:</div>
                    <div id="debug-vnodes" style="text-align: right; font-weight: 500;">0</div>

                    <div style="color: rgba(255, 255, 255, 0.6);">DOM Nodes:</div>
                    <div id="debug-domnodes" style="text-align: right; font-weight: 500;">0</div>

                    <div style="color: rgba(255, 255, 255, 0.6);">Render:</div>
                    <div id="debug-rendertime" style="text-align: right; font-weight: 600; color: #4caf50;">0.00 ms</div>

                    <div style="color: rgba(255, 255, 255, 0.6);">Memory:</div>
                    <div id="debug-memory" style="text-align: right; font-weight: 500;">0.00 MB</div>
                </div>

                <div style="
                    margin-top: 4px;
                    padding-top: 8px;
                    border-top: 1px solid rgba(255, 255, 255, 0.1);
                    font-size: 10px;
                    color: rgba(255, 255, 255, 0.5);
                    text-align: center;
                ">
                    ⌘⇧D to toggle
                </div>
            </div>
        </div>
        """
    }

    private func startMetricsUpdates() {
        // Update metrics every 100ms using Task.sleep instead of Timer
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isVisible else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }
                self.updateMetricsDisplay()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func stopMetricsUpdates() {
        updateTask?.cancel()
        updateTask = nil
    }

    private func updateMetricsDisplay() {
        let script = """
        if (window.__ravenDebugOverlay) {
            window.__ravenDebugOverlay.update({
                fps: \(metrics.fps),
                vnodeCount: \(metrics.vnodeCount),
                domNodeCount: \(metrics.domNodeCount),
                renderTime: \(metrics.renderTime),
                memoryUsage: \(metrics.memoryUsage)
            });
        }
        """

        executeJavaScript(script)
    }

    private func executeJavaScript(_ script: String) {
        // This would be implemented by the DOMBridge or similar
        // For now, we'll use a placeholder that can be filled in later
        #if canImport(JavaScriptCore)
        // Implementation would go here
        #else
        // For WebAssembly, this would be bridged via the JS runtime
        #endif
    }
}

#else

// Empty implementation for non-DEBUG builds
@MainActor
public final class DebugOverlay: Sendable {
    public static let shared = DebugOverlay()
    private init() {}

    public func toggle() {}
    public func show() {}
    public func hide() {}
    public func updateFPS(_ fps: Double) {}
    public func updateVNodeCount(_ count: Int) {}
    public func updateDOMNodeCount(_ count: Int) {}
    public func updateRenderTime(_ milliseconds: Double) {}
    public func updateMemoryUsage(_ megabytes: Double) {}
}

#endif
