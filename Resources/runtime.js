/**
 * Raven Runtime
 * JavaScript runtime for SwiftUI to DOM cross-compilation
 *
 * This runtime provides the bridge between SwiftWasm and the browser DOM,
 * handling WASM loading, event delegation, and DOM manipulation helpers.
 */

(function() {
  'use strict';

  // =============================================================================
  // WASM Loading & Initialization
  // =============================================================================

  let swiftInstance = null;
  let swiftExports = null;
  let isInitialized = false;

  /**
   * Initialize the Swift WASM runtime
   * @param {string} wasmPath - Path to the .wasm file
   * @param {Object} options - Configuration options
   * @returns {Promise<Object>} Initialized Swift instance
   */
  async function initializeSwiftRuntime(wasmPath, options = {}) {
    if (isInitialized) {
      console.warn('Raven: Swift runtime already initialized');
      return swiftInstance;
    }

    try {
      console.log('Raven: Loading Swift WASM module...');

      // Load the WASM module
      const response = await fetch(wasmPath);
      const wasmBytes = await response.arrayBuffer();

      // Import objects that Swift runtime may need
      const importObject = {
        env: {
          // Memory configuration
          memory: new WebAssembly.Memory({
            initial: options.initialMemory || 256,
            maximum: options.maximumMemory || 16384
          }),

          // Console logging functions
          _console_log: (ptr, len) => {
            const message = readString(ptr, len);
            console.log(message);
          },

          _console_error: (ptr, len) => {
            const message = readString(ptr, len);
            console.error(message);
          },

          // Performance timing
          _get_time: () => performance.now(),
        },

        // JavaScript interop for JavaScriptKit
        javascript_kit: createJavaScriptKitHost()
      };

      // Compile and instantiate the WASM module
      const wasmModule = await WebAssembly.instantiate(wasmBytes, importObject);
      swiftInstance = wasmModule.instance;
      swiftExports = swiftInstance.exports;

      // Initialize Swift runtime if it has an initialization function
      if (swiftExports._initialize) {
        swiftExports._initialize();
      }

      isInitialized = true;
      console.log('Raven: Swift WASM runtime initialized successfully');

      return swiftInstance;
    } catch (error) {
      console.error('Raven: Failed to initialize Swift runtime:', error);
      throw error;
    }
  }

  /**
   * Create JavaScriptKit host object for Swift-JS interop
   * @returns {Object} JavaScriptKit import object
   */
  function createJavaScriptKitHost() {
    const objectRegistry = new Map();
    let nextObjectId = 1;

    return {
      // Register a JavaScript object and return an ID
      _register_object: (obj) => {
        const id = nextObjectId++;
        objectRegistry.set(id, obj);
        return id;
      },

      // Release an object from the registry
      _release_object: (id) => {
        objectRegistry.delete(id);
      },

      // Get an object by ID
      _get_object: (id) => {
        return objectRegistry.get(id);
      },

      // Call a method on a registered object
      _call_method: (objectId, methodNamePtr, methodNameLen, argsPtr, argsLen) => {
        const obj = objectRegistry.get(objectId);
        const methodName = readString(methodNamePtr, methodNameLen);
        const args = JSON.parse(readString(argsPtr, argsLen));

        if (obj && typeof obj[methodName] === 'function') {
          return obj[methodName](...args);
        }
      },

      // Get a property from a registered object
      _get_property: (objectId, propNamePtr, propNameLen) => {
        const obj = objectRegistry.get(objectId);
        const propName = readString(propNamePtr, propNameLen);
        return obj ? obj[propName] : undefined;
      },

      // Set a property on a registered object
      _set_property: (objectId, propNamePtr, propNameLen, value) => {
        const obj = objectRegistry.get(objectId);
        const propName = readString(propNamePtr, propNameLen);
        if (obj) {
          obj[propName] = value;
        }
      }
    };
  }

  /**
   * Read a UTF-8 string from WASM memory
   * @param {number} ptr - Memory pointer
   * @param {number} len - String length
   * @returns {string}
   */
  function readString(ptr, len) {
    if (!swiftInstance || !swiftInstance.exports.memory) {
      return '';
    }
    const memory = new Uint8Array(swiftInstance.exports.memory.buffer);
    const bytes = memory.slice(ptr, ptr + len);
    return new TextDecoder('utf-8').decode(bytes);
  }

  // =============================================================================
  // Event Delegation System
  // =============================================================================

  const eventHandlers = new Map(); // uuid -> callback function
  const eventTypes = [
    'click', 'dblclick', 'mousedown', 'mouseup', 'mousemove', 'mouseover', 'mouseout',
    'input', 'change', 'submit', 'focus', 'blur',
    'keydown', 'keyup', 'keypress',
    'touchstart', 'touchend', 'touchmove',
    'dragstart', 'drag', 'dragend', 'dragover', 'drop'
  ];

  let rootContainer = null;

  /**
   * Initialize event delegation on a root container
   * @param {HTMLElement} container - Root DOM element
   */
  function initializeEventDelegation(container) {
    rootContainer = container;

    // Set up delegated event listeners for all event types
    eventTypes.forEach(eventType => {
      container.addEventListener(eventType, handleDelegatedEvent, true);
    });

    console.log('Raven: Event delegation initialized');
  }

  /**
   * Handle delegated events and route to Swift callbacks
   * @param {Event} event - DOM event
   */
  function handleDelegatedEvent(event) {
    // Walk up the DOM tree to find elements with event handlers
    let element = event.target;

    while (element && element !== rootContainer) {
      // Check for data-raven-event-* attributes
      const eventAttr = `data-raven-event-${event.type}`;
      const handlerUuid = element.getAttribute(eventAttr);

      if (handlerUuid && eventHandlers.has(handlerUuid)) {
        const handler = eventHandlers.get(handlerUuid);

        // Serialize event data for Swift
        const eventData = serializeEvent(event);

        // Call the Swift handler
        try {
          handler(eventData);
        } catch (error) {
          console.error(`Raven: Error in event handler for ${event.type}:`, error);
        }

        // Check if we should stop propagation
        if (element.hasAttribute('data-raven-stop-propagation')) {
          event.stopPropagation();
        }

        // Check if we should prevent default
        if (element.hasAttribute('data-raven-prevent-default')) {
          event.preventDefault();
        }

        break;
      }

      element = element.parentElement;
    }
  }

  /**
   * Serialize DOM event to a plain object for Swift
   * @param {Event} event - DOM event
   * @returns {Object} Serialized event data
   */
  function serializeEvent(event) {
    const baseData = {
      type: event.type,
      timestamp: event.timeStamp,
      target: {
        id: event.target.id,
        tagName: event.target.tagName,
        className: event.target.className,
        value: event.target.value
      }
    };

    // Add event-specific data
    if (event instanceof MouseEvent) {
      return {
        ...baseData,
        mouse: {
          clientX: event.clientX,
          clientY: event.clientY,
          screenX: event.screenX,
          screenY: event.screenY,
          button: event.button,
          buttons: event.buttons,
          ctrlKey: event.ctrlKey,
          shiftKey: event.shiftKey,
          altKey: event.altKey,
          metaKey: event.metaKey
        }
      };
    }

    if (event instanceof KeyboardEvent) {
      return {
        ...baseData,
        keyboard: {
          key: event.key,
          code: event.code,
          keyCode: event.keyCode,
          ctrlKey: event.ctrlKey,
          shiftKey: event.shiftKey,
          altKey: event.altKey,
          metaKey: event.metaKey,
          repeat: event.repeat
        }
      };
    }

    if (event instanceof InputEvent) {
      return {
        ...baseData,
        input: {
          data: event.data,
          inputType: event.inputType,
          isComposing: event.isComposing
        }
      };
    }

    if (event instanceof TouchEvent) {
      return {
        ...baseData,
        touch: {
          touches: Array.from(event.touches).map(t => ({
            identifier: t.identifier,
            clientX: t.clientX,
            clientY: t.clientY,
            screenX: t.screenX,
            screenY: t.screenY
          }))
        }
      };
    }

    return baseData;
  }

  /**
   * Register an event handler with a UUID
   * @param {string} uuid - Unique identifier for the handler
   * @param {Function} callback - Handler function
   */
  function registerEventHandler(uuid, callback) {
    eventHandlers.set(uuid, callback);
  }

  /**
   * Unregister an event handler
   * @param {string} uuid - Handler identifier
   */
  function unregisterEventHandler(uuid) {
    eventHandlers.delete(uuid);
  }

  // =============================================================================
  // DOM Helpers
  // =============================================================================

  /**
   * Query selector helper with error handling
   * @param {string} selector - CSS selector
   * @param {HTMLElement} context - Search context (default: document)
   * @returns {HTMLElement|null}
   */
  function querySelector(selector, context = document) {
    try {
      return context.querySelector(selector);
    } catch (error) {
      console.error(`Raven: Invalid selector "${selector}":`, error);
      return null;
    }
  }

  /**
   * Query selector all helper with error handling
   * @param {string} selector - CSS selector
   * @param {HTMLElement} context - Search context (default: document)
   * @returns {NodeList}
   */
  function querySelectorAll(selector, context = document) {
    try {
      return context.querySelectorAll(selector);
    } catch (error) {
      console.error(`Raven: Invalid selector "${selector}":`, error);
      return [];
    }
  }

  /**
   * Create an element with attributes
   * @param {string} tag - Element tag name
   * @param {Object} attributes - Element attributes
   * @param {Array} children - Child elements or text
   * @returns {HTMLElement}
   */
  function createElement(tag, attributes = {}, children = []) {
    const element = document.createElement(tag);

    // Set attributes
    Object.entries(attributes).forEach(([key, value]) => {
      if (key === 'className') {
        element.className = value;
      } else if (key === 'style' && typeof value === 'object') {
        Object.assign(element.style, value);
      } else if (key.startsWith('data-')) {
        element.setAttribute(key, value);
      } else {
        element[key] = value;
      }
    });

    // Add children
    children.forEach(child => {
      if (typeof child === 'string') {
        element.appendChild(document.createTextNode(child));
      } else if (child instanceof Node) {
        element.appendChild(child);
      }
    });

    return element;
  }

  /**
   * Request animation frame with fallback
   * @param {Function} callback - Frame callback
   * @returns {number} Frame ID
   */
  function requestFrame(callback) {
    return requestAnimationFrame(callback);
  }

  /**
   * Cancel animation frame
   * @param {number} frameId - Frame ID to cancel
   */
  function cancelFrame(frameId) {
    cancelAnimationFrame(frameId);
  }

  /**
   * Batch DOM updates for better performance
   * @param {Function} callback - Update function
   */
  function batchUpdate(callback) {
    requestAnimationFrame(() => {
      callback();
    });
  }

  // =============================================================================
  // Raven Integration API
  // =============================================================================

  /**
   * Mount a Raven application to a DOM element
   * @param {string} containerId - Container element ID
   * @param {Object} options - Mount options
   * @returns {Promise<Object>} Mount result
   */
  async function mount(containerId, options = {}) {
    const container = document.getElementById(containerId);

    if (!container) {
      throw new Error(`Raven: Container element #${containerId} not found`);
    }

    console.log(`Raven: Mounting application to #${containerId}`);

    // Initialize event delegation
    initializeEventDelegation(container);

    // Load and initialize Swift WASM
    if (!isInitialized) {
      const wasmPath = options.wasmPath || './main.wasm';
      await initializeSwiftRuntime(wasmPath, options);
    }

    // Call Swift entry point if available
    if (swiftExports && swiftExports._start) {
      swiftExports._start();
    }

    console.log('Raven: Application mounted successfully');

    return {
      container,
      unmount: () => unmount(container)
    };
  }

  /**
   * Unmount a Raven application
   * @param {HTMLElement} container - Container element
   */
  function unmount(container) {
    // Remove all event listeners
    eventTypes.forEach(eventType => {
      container.removeEventListener(eventType, handleDelegatedEvent, true);
    });

    // Clear event handlers
    eventHandlers.clear();

    // Clear container
    container.innerHTML = '';

    console.log('Raven: Application unmounted');
  }

  // =============================================================================
  // Hot Reload Support (Development Mode)
  // =============================================================================

  let hotReloadWebSocket = null;
  let hotReloadEnabled = false;

  /**
   * Initialize hot reload WebSocket connection
   * @param {Object} options - Hot reload options
   */
  function initializeHotReload(options = {}) {
    const wsUrl = options.wsUrl || `ws://${location.hostname}:${options.port || 8080}/ws`;

    console.log('Raven: Connecting to hot reload server...');

    hotReloadWebSocket = new WebSocket(wsUrl);

    hotReloadWebSocket.onopen = () => {
      console.log('Raven: Hot reload connected');
      hotReloadEnabled = true;
    };

    hotReloadWebSocket.onmessage = async (event) => {
      const message = JSON.parse(event.data);

      switch (message.type) {
        case 'reload':
          console.log('Raven: Reloading application...');
          await reloadModule();
          break;

        case 'update':
          console.log('Raven: Hot update received');
          await hotUpdateModule(message.data);
          break;

        default:
          console.warn('Raven: Unknown hot reload message type:', message.type);
      }
    };

    hotReloadWebSocket.onerror = (error) => {
      console.error('Raven: Hot reload WebSocket error:', error);
    };

    hotReloadWebSocket.onclose = () => {
      console.log('Raven: Hot reload disconnected');
      hotReloadEnabled = false;

      // Attempt to reconnect after 2 seconds
      setTimeout(() => {
        if (!hotReloadEnabled) {
          initializeHotReload(options);
        }
      }, 2000);
    };
  }

  /**
   * Reload the entire WASM module
   */
  async function reloadModule() {
    try {
      // Save current state if possible
      const state = swiftExports && swiftExports._save_state
        ? swiftExports._save_state()
        : null;

      // Reset initialization flag
      isInitialized = false;
      swiftInstance = null;
      swiftExports = null;

      // Clear cache and reload
      const wasmPath = './main.wasm?t=' + Date.now();
      await initializeSwiftRuntime(wasmPath);

      // Restore state if possible
      if (state && swiftExports && swiftExports._restore_state) {
        swiftExports._restore_state(state);
      }

      console.log('Raven: Module reloaded successfully');
    } catch (error) {
      console.error('Raven: Failed to reload module:', error);
    }
  }

  /**
   * Apply a hot update to the module (placeholder for future implementation)
   * @param {Object} updateData - Update data
   */
  async function hotUpdateModule(updateData) {
    // TODO: Implement incremental hot updates
    // For now, fall back to full reload
    console.log('Raven: Hot update not yet implemented, performing full reload');
    await reloadModule();
  }

  // =============================================================================
  // Hot Reload Client (Development Mode)
  // =============================================================================

  /**
   * Initialize hot reload client using Server-Sent Events
   * Only active when running on localhost
   */
  function initializeHotReloadClient() {
    // Only enable on localhost
    if (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
      return;
    }

    let eventSource = null;
    let reconnectAttempts = 0;
    const maxReconnectAttempts = 10;
    const baseReconnectDelay = 1000;

    function connect() {
      try {
        eventSource = new EventSource('http://localhost:35729/events');

        eventSource.onopen = () => {
          console.log('🔥 Hot reload connected');
          reconnectAttempts = 0;
          updateIndicator('connected');
        };

        eventSource.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);

            if (data.type === 'reload') {
              console.log('🔄 Reloading...');
              window.location.reload();
            } else if (data.type === 'error') {
              console.error('Build error:', data.message);
              showError(data.message);
            }
          } catch (error) {
            console.error('Failed to parse hot reload message:', error);
          }
        };

        eventSource.onerror = () => {
          console.log('Hot reload disconnected, retrying...');
          eventSource.close();
          updateIndicator('disconnected');

          // Exponential backoff for reconnection
          if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            const delay = Math.min(baseReconnectDelay * Math.pow(2, reconnectAttempts - 1), 30000);
            setTimeout(() => {
              connect();
            }, delay);
          } else {
            console.log('Max reconnection attempts reached. Please refresh the page.');
            updateIndicator('failed');
          }
        };
      } catch (error) {
        console.error('Failed to create EventSource:', error);
      }
    }

    // Start connection
    connect();
    addConnectionIndicator();
    console.log('🔥 Hot reload enabled');
  }

  /**
   * Add a visual connection indicator
   */
  function addConnectionIndicator() {
    const indicator = document.createElement('div');
    indicator.id = 'hot-reload-indicator';
    indicator.textContent = '🔥';
    indicator.style.cssText = 'position:fixed;bottom:10px;right:10px;background:#4ade80;color:white;padding:8px;border-radius:50%;font-size:16px;z-index:9999;cursor:pointer;transition:background 0.3s;';
    indicator.title = 'Hot reload connected';

    // Add click handler to manually reload
    indicator.addEventListener('click', () => {
      window.location.reload();
    });

    document.body.appendChild(indicator);
  }

  /**
   * Update connection indicator status
   * @param {string} status - Connection status ('connected', 'disconnected', 'failed')
   */
  function updateIndicator(status) {
    const indicator = document.getElementById('hot-reload-indicator');
    if (!indicator) return;

    switch (status) {
      case 'connected':
        indicator.style.background = '#4ade80';
        indicator.title = 'Hot reload connected';
        break;
      case 'disconnected':
        indicator.style.background = '#fbbf24';
        indicator.title = 'Hot reload disconnected, retrying...';
        break;
      case 'failed':
        indicator.style.background = '#ef4444';
        indicator.title = 'Hot reload failed. Click to refresh.';
        break;
    }
  }

  /**
   * Show error overlay
   * @param {string} error - Error message
   */
  function showError(error) {
    // Remove existing overlay
    const existing = document.getElementById('error-overlay');
    if (existing) existing.remove();

    // Create error overlay
    const overlay = document.createElement('div');
    overlay.id = 'error-overlay';
    overlay.innerHTML = `
      <div style="position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.9);color:white;padding:40px;overflow:auto;z-index:10000;font-family:monospace;">
        <div style="max-width:1200px;margin:0 auto;">
          <h2 style="color:#ef4444;margin-bottom:20px;">Build Error</h2>
          <pre style="background:#1a1a1a;padding:20px;border-radius:8px;overflow:auto;white-space:pre-wrap;word-wrap:break-word;">${escapeHtml(error)}</pre>
          <button onclick="document.getElementById('error-overlay').remove()" style="margin-top:20px;padding:10px 20px;background:#4ade80;color:white;border:none;border-radius:4px;cursor:pointer;font-size:14px;">Dismiss</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
  }

  /**
   * Escape HTML to prevent XSS
   * @param {string} text - Text to escape
   * @returns {string} Escaped text
   */
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Auto-initialize hot reload client on page load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeHotReloadClient);
  } else {
    initializeHotReloadClient();
  }

  // =============================================================================
  // Export Raven API
  // =============================================================================

  window.Raven = {
    // Core API
    mount,
    unmount,

    // Event system
    registerEventHandler,
    unregisterEventHandler,

    // DOM helpers
    querySelector,
    querySelectorAll,
    createElement,
    requestFrame,
    cancelFrame,
    batchUpdate,

    // Hot reload (development)
    initializeHotReload,

    // Low-level access (advanced usage)
    internal: {
      initializeSwiftRuntime,
      getSwiftInstance: () => swiftInstance,
      getSwiftExports: () => swiftExports,
      isInitialized: () => isInitialized
    },

    // Version info
    version: '0.1.0'
  };

  console.log('Raven runtime loaded (v0.1.0)');

})();
