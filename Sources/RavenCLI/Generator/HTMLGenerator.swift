import Foundation

/// Generates HTML index files for Raven builds
struct HTMLGenerator: Sendable {
    /// Generates an HTML index file from the given HTML configuration
    /// - Parameter config: The HTML configuration containing project settings
    /// - Returns: A complete HTML document as a string
    func generate(config: HTMLConfig) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="\(escapeHTML(config.language))">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        """

        // Add optional meta tags
        for (name, content) in config.metaTags.sorted(by: { $0.key < $1.key }) {
            html += "\n    <meta name=\"\(escapeHTML(name))\" content=\"\(escapeHTML(content))\">"
        }

        // Add title
        html += "\n    <title>\(escapeHTML(config.title))</title>"

        // Add CSS links
        for cssFile in config.cssFiles {
            html += "\n    <link rel=\"stylesheet\" href=\"\(escapeHTML(cssFile))\">"
        }

        html += """

        </head>
        <body>
            <!-- Loading indicator shown before WASM initializes -->
            <div id="loading" style="display:flex;align-items:center;justify-content:center;min-height:100vh;font-family:system-ui,sans-serif;color:#666;">
                <p>Loading \(escapeHTML(config.title))...</p>
            </div>

            <!-- Root element for Raven to mount to -->
            <div id="\(escapeHTML(config.mountElementID))" style="display:none;"></div>

        """

        // JavaScriptKit runtime — inlined if available, external fallback otherwise
        if let runtimeSource = config.javaScriptKitRuntimeSource {
            html += "    <script>\n\(runtimeSource)\n    </script>\n\n"
        } else {
            html += "    <script src=\"runtime.js\"></script>\n\n"
        }

        // Raven event handler helpers
        html += """
            <script>
                window.__ravenEvents = [];
                window.__ravenAddEventListener = function(element, eventName, handler) {
                    window.__ravenEvents.push({
                        element: element ? element.tagName : 'null',
                        eventName: eventName,
                        handlerType: typeof handler
                    });
                    if (element && typeof element.addEventListener === 'function' && typeof handler === 'function') {
                        var wrappedHandler = function(event) {
                            try {
                                return handler(event);
                            } catch (error) {
                                console.error('[RAVEN] Handler error:', error);
                                throw error;
                            }
                        };
                        element.addEventListener(eventName, wrappedHandler);
                        return true;
                    }
                    return false;
                };
                window.__ravenRemoveEventListener = function(element, eventName, handler) {
                    if (element && typeof element.removeEventListener === 'function') {
                        element.removeEventListener(eventName, handler);
                        return true;
                    }
                    return false;
                };
            </script>

        """

        // WASM bootstrap with inlined WASI polyfill
        html += """
            <script type="module">
                let wasmMemory;
                const wasiPolyfill = {
                    args_get: () => 0,
                    args_sizes_get: () => 0,
                    environ_get: () => 0,
                    environ_sizes_get: () => 0,
                    clock_res_get: () => 0,
                    clock_time_get: () => 0,
                    fd_advise: () => 0,
                    fd_allocate: () => 0,
                    fd_close: () => 0,
                    fd_datasync: () => 0,
                    fd_fdstat_get: () => 0,
                    fd_fdstat_set_flags: () => 0,
                    fd_fdstat_set_rights: () => 0,
                    fd_filestat_get: () => 0,
                    fd_filestat_set_size: () => 0,
                    fd_filestat_set_times: () => 0,
                    fd_pread: () => 0,
                    fd_prestat_get: () => 0,
                    fd_prestat_dir_name: () => 0,
                    fd_pwrite: () => 0,
                    fd_read: () => 0,
                    fd_readdir: () => 0,
                    fd_renumber: () => 0,
                    fd_seek: () => 0,
                    fd_sync: () => 0,
                    fd_tell: () => 0,
                    fd_write: (fd, iov, iovcnt, nwritten) => {
                        if ((fd === 1 || fd === 2) && wasmMemory) {
                            try {
                                const buffers = new Uint32Array(wasmMemory.buffer, iov, iovcnt * 2);
                                let output = '';
                                for (let i = 0; i < iovcnt; i++) {
                                    const ptr = buffers[i * 2];
                                    const len = buffers[i * 2 + 1];
                                    const buffer = new Uint8Array(wasmMemory.buffer, ptr, len);
                                    output += new TextDecoder().decode(buffer);
                                }
                                if (fd === 1) console.log('[Swift]', output);
                                else console.error('[Swift Error]', output);
                                if (nwritten) new Uint32Array(wasmMemory.buffer, nwritten, 1)[0] = output.length;
                                return 0;
                            } catch (e) {
                                console.error('fd_write error:', e);
                                return -1;
                            }
                        }
                        return 0;
                    },
                    path_create_directory: () => 0,
                    path_filestat_get: () => 0,
                    path_filestat_set_times: () => 0,
                    path_link: () => 0,
                    path_open: () => 0,
                    path_readlink: () => 0,
                    path_remove_directory: () => 0,
                    path_rename: () => 0,
                    path_symlink: () => 0,
                    path_unlink_file: () => 0,
                    poll_oneoff: () => 0,
                    proc_exit: (code) => { console.log('[WASM] Exit code:', code); },
                    proc_raise: () => 0,
                    sched_yield: () => 0,
                    random_get: () => 0,
                    sock_recv: () => 0,
                    sock_send: () => 0,
                    sock_shutdown: () => 0,
                };

                async function loadWASM() {
                    try {
                        const response = await fetch('\(escapeHTML(config.wasmFile))?t=' + Date.now());
                        if (!response.ok) throw new Error('Failed to fetch WASM: ' + response.status);
                        const bytes = await response.arrayBuffer();
                        console.log('Loaded ' + (bytes.byteLength / 1024 / 1024).toFixed(2) + ' MB');

                        const { SwiftRuntime } = JavaScriptKit;
                        const swift = new SwiftRuntime();
                        const { instance } = await WebAssembly.instantiate(bytes, {
                            wasi_snapshot_preview1: wasiPolyfill,
                            javascript_kit: swift.importObjects(),
                        });

                        wasmMemory = instance.exports.memory;
                        swift.setInstance(instance);

                        if (instance.exports._initialize) instance.exports._initialize();

                        // Call the Swift @main entry point (reactor ABI doesn't auto-call main)
                        if (instance.exports.main) {
                            instance.exports.main();
                        } else if (instance.exports.__main_argc_argv) {
                            instance.exports.__main_argc_argv(0, 0);
                        }

                        document.getElementById('loading').style.display = 'none';
                        document.getElementById('\(escapeHTML(config.mountElementID))').style.display = 'block';
                    } catch (error) {
                        console.error('Failed to load WASM:', error);
                        document.getElementById('loading').textContent = 'Failed to load: ' + error.message;
                    }
                }

                if (typeof JavaScriptKit !== 'undefined') loadWASM();
                else console.error('JavaScriptKit runtime not loaded!');
            </script>
        """

        // Inject error overlay and hot reload client in development mode
        if config.isDevelopment {
            let errorOverlay = ErrorOverlay()
            html += errorOverlay.generateWithHotReload(hotReloadPort: config.hotReloadPort)
        }

        html += """

        </body>
        </html>
        """

        return html
    }

    /// Writes the generated HTML to a file at the specified path
    /// - Parameters:
    ///   - config: The HTML configuration
    ///   - path: The file path where the HTML should be written
    /// - Throws: File system errors if writing fails
    func writeToFile(config: HTMLConfig, path: String) throws {
        let html = generate(config: config)
        let url = URL(fileURLWithPath: path)

        // Create parent directory if it doesn't exist
        let parentDirectory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parentDirectory,
            withIntermediateDirectories: true
        )

        try html.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Escapes HTML special characters to prevent injection
    /// - Parameter text: The text to escape
    /// - Returns: The escaped text safe for HTML output
    private func escapeHTML(_ text: String) -> String {
        var escaped = text
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&#x27;")
        return escaped
    }
}
