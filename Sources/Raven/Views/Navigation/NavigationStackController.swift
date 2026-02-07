import Foundation

/// Internal controller that manages navigation stack state for a `NavigationStack`.
///
/// Since environment propagation isn't fully implemented in the render pipeline,
/// this controller uses a static `_current` variable set during the NavigationStack's
/// render pass so that `NavigationLink` and `navigationTitle` can find their parent stack.
///
/// The controller is kept alive across re-renders via `_RenderContext.persistentState`.
@MainActor
internal final class NavigationStackController {
    // MARK: - Static Current

    /// The currently-rendering NavigationStack's controller.
    /// Set during `NavigationStack._render`, read by `NavigationLink` and `navigationTitle`.
    static var _current: NavigationStackController?

    // MARK: - State

    /// Stack of pushed destination views.
    var viewStack: [AnyView] = []

    /// Parallel stack of navigation titles for each level (index 0 = root title).
    var titleStack: [String] = [""]

    /// Navigation destinations registered during the current render pass.
    /// Cleared at the start of each render and re-populated by `navigationDestination` modifiers.
    var destinations: [NavigationDestinationInfo] = []

    /// Display mode per stack level (default: .large). Index 0 = root.
    var displayModeStack: [NavigationBarTitleDisplayMode] = [.large]

    /// Toolbar items collected during render (cleared each pass like destinations).
    var toolbarItems: [ToolbarItemInfo] = []

    /// Search bar info (set by `_SearchableView` during render).
    var searchBarInfo: SearchBarInfo?

    /// Nav bar hidden per level. Index 0 = root.
    var navBarHiddenStack: [Bool] = [false]

    /// Background customization for the toolbar (CSS color string).
    var toolbarBackground: String?

    /// Tint color for leading toolbar items (CSS color string).
    var toolbarTintColor: String?

    /// Path stack: parallel to viewStack, stores the URL path for each pushed level.
    /// `nil` means no URL change for that push.
    var pathStack: [String?] = []

    /// Whether deep linking has been handled for the initial page load.
    private var deepLinkHandled = false

    /// Weak reference to the render scheduler for triggering re-renders.
    weak var renderScheduler: (any _StateChangeReceiver)?

    /// Whether the popstate listener has been set up.
    private var popstateListenerSetup = false

    // MARK: - Computed Properties

    /// Whether the stack has views that can be popped.
    var canGoBack: Bool {
        !viewStack.isEmpty
    }

    /// The current depth (0 = root, 1 = first push, etc.)
    var depth: Int {
        viewStack.count
    }

    /// The title for the current navigation level.
    var currentTitle: String {
        if titleStack.count > depth {
            return titleStack[depth]
        }
        return ""
    }

    /// The display mode for the current navigation level.
    var currentDisplayMode: NavigationBarTitleDisplayMode {
        if displayModeStack.count > depth {
            return displayModeStack[depth]
        }
        return .large
    }

    /// Whether the nav bar is hidden at the current level.
    var isNavBarHidden: Bool {
        if navBarHiddenStack.count > depth {
            return navBarHiddenStack[depth]
        }
        return false
    }

    // MARK: - Navigation Actions

    /// Push a destination view onto the stack.
    ///
    /// - Parameters:
    ///   - view: The destination view to push.
    ///   - path: Optional URL path for this push. If non-nil, pushes to browser History API.
    ///           If nil, no URL change occurs.
    func push(_ view: AnyView, path: String? = nil) {
        viewStack.append(view)
        pathStack.append(path)

        // Ensure title stack has an entry for the new level
        if titleStack.count <= viewStack.count {
            titleStack.append("")
        }
        // Ensure display mode stack has an entry
        if displayModeStack.count <= viewStack.count {
            displayModeStack.append(.large)
        }
        // Ensure navBarHidden stack has an entry
        if navBarHiddenStack.count <= viewStack.count {
            navBarHiddenStack.append(false)
        }

        if let path = path {
            // Path-based push: update browser URL
            NavigationHistory.shared.pushState(
                path: path,
                state: ["depth": "\(viewStack.count)", "path": path]
            )
        } else {
            // Non-path push: push a generic state without changing visible URL path
            NavigationHistory.shared.pushState(
                path: NavigationHistory.shared.getCurrentPath(),
                state: ["depth": "\(viewStack.count)"]
            )
        }

        renderScheduler?.scheduleRender()
    }

    /// Pop the top view from the stack.
    func pop() {
        guard canGoBack else { return }

        let poppedPath = pathStack.last ?? nil

        viewStack.removeLast()
        pathStack.removeLast()

        // Trim title stack to match
        if titleStack.count > viewStack.count + 1 {
            titleStack.removeLast()
        }
        // Trim display mode stack
        if displayModeStack.count > viewStack.count + 1 {
            displayModeStack.removeLast()
        }
        // Trim navBarHidden stack
        if navBarHiddenStack.count > viewStack.count + 1 {
            navBarHiddenStack.removeLast()
        }

        // Navigate browser back for path-based entries
        if poppedPath != nil {
            NavigationHistory.shared.back()
        }

        renderScheduler?.scheduleRender()
    }

    /// Pop all views, returning to root.
    func popToRoot() {
        // Count path-based entries for browser back navigation
        let pathEntries = pathStack.compactMap({ $0 }).count

        viewStack.removeAll()
        pathStack.removeAll()
        titleStack = [titleStack.first ?? ""]
        displayModeStack = [displayModeStack.first ?? .large]
        navBarHiddenStack = [navBarHiddenStack.first ?? false]

        // Navigate browser back for all path-based entries
        if pathEntries > 0 {
            NavigationHistory.shared.go(-pathEntries)
        }

        renderScheduler?.scheduleRender()
    }

    // MARK: - Title Management

    /// Set the title for the current navigation level.
    func setCurrentTitle(_ title: String) {
        let index = depth
        while titleStack.count <= index {
            titleStack.append("")
        }
        titleStack[index] = title
    }

    // MARK: - Display Mode Management

    /// Set the display mode for the current navigation level.
    func setCurrentDisplayMode(_ mode: NavigationBarTitleDisplayMode) {
        let index = depth
        while displayModeStack.count <= index {
            displayModeStack.append(.large)
        }
        displayModeStack[index] = mode
    }

    /// Set the nav bar hidden state for the current navigation level.
    func setCurrentNavBarHidden(_ hidden: Bool) {
        let index = depth
        while navBarHiddenStack.count <= index {
            navBarHiddenStack.append(false)
        }
        navBarHiddenStack[index] = hidden
    }

    // MARK: - Destination Resolution

    /// Look up a registered destination for a given value.
    func resolveDestination(for value: any Hashable & Sendable) -> AnyView? {
        for info in destinations {
            if type(of: value) == info.dataType {
                return info.makeDestination(value)
            }
        }
        return nil
    }

    /// Look up the path pattern for a given value type from registered destinations.
    ///
    /// Returns the resolved path with parameters substituted (e.g. "/items/123")
    /// if the destination has a `path` configured, or nil otherwise.
    func resolvePathForValue(_ value: any Hashable & Sendable) -> String? {
        for info in destinations {
            if type(of: value) == info.dataType, let pathPattern = info.path {
                // Simple parameter substitution: replace `:param` segments with the value
                // For basic usage, we just append the value's description as the last segment
                return substitutePathParameters(pattern: pathPattern, value: value)
            }
        }
        return nil
    }

    /// Substitute path parameters in a pattern with the actual value.
    ///
    /// Supports patterns like `/items/:id` where `:id` is replaced with the value.
    private func substitutePathParameters(pattern: String, value: any Hashable & Sendable) -> String {
        let segments = pattern.split(separator: "/", omittingEmptySubsequences: true)
        var result: [String] = []

        for segment in segments {
            if segment.hasPrefix(":") {
                // Replace parameter with value's description
                result.append("\(value)")
            } else {
                result.append(String(segment))
            }
        }

        return "/" + result.joined(separator: "/")
    }

    // MARK: - Deep Linking

    /// Handle deep linking on the initial page load.
    ///
    /// Called once on first render of NavigationStack. Reads the current URL path
    /// and tries to match it against registered destinations that have paths.
    func handleDeepLink() {
        guard !deepLinkHandled else { return }
        deepLinkHandled = true

        let currentPath = NavigationHistory.shared.getCurrentPath()

        // Skip if we're at root
        guard currentPath != "/" && !currentPath.isEmpty else { return }

        // Try to match against registered destinations with paths
        for info in destinations {
            guard let pathPattern = info.path else { continue }

            if let extractedValue = matchPath(currentPath, against: pathPattern, expectedType: info.dataType) {
                let destinationView = info.makeDestination(extractedValue)
                viewStack.append(destinationView)
                pathStack.append(currentPath)

                // Ensure stacks are sized
                if titleStack.count <= viewStack.count {
                    titleStack.append("")
                }
                if displayModeStack.count <= viewStack.count {
                    displayModeStack.append(.large)
                }
                if navBarHiddenStack.count <= viewStack.count {
                    navBarHiddenStack.append(false)
                }

                // Replace current history state so back works correctly
                NavigationHistory.shared.replaceState(
                    path: currentPath,
                    state: ["depth": "\(viewStack.count)", "path": currentPath]
                )

                renderScheduler?.scheduleRender()
                return
            }
        }
    }

    /// Try to match a URL path against a path pattern and extract a typed value.
    ///
    /// - Parameters:
    ///   - path: The actual URL path (e.g. "/items/42")
    ///   - pattern: The path pattern (e.g. "/items/:id")
    ///   - expectedType: The expected Swift type for the extracted value
    /// - Returns: The extracted value if the path matches, or nil
    private func matchPath(_ path: String, against pattern: String, expectedType: Any.Type) -> (any Hashable & Sendable)? {
        let pathSegments = path.split(separator: "/", omittingEmptySubsequences: true)
        let patternSegments = pattern.split(separator: "/", omittingEmptySubsequences: true)

        guard pathSegments.count == patternSegments.count else { return nil }

        var extractedValue: String?

        for (pathSeg, patternSeg) in zip(pathSegments, patternSegments) {
            if patternSeg.hasPrefix(":") {
                // This is a parameter — extract its value
                extractedValue = String(pathSeg)
            } else if pathSeg != patternSeg {
                // Static segment doesn't match
                return nil
            }
        }

        guard let valueString = extractedValue else { return nil }

        // Try to convert the string value to the expected type
        if expectedType == String.self {
            return valueString
        } else if expectedType == Int.self, let intValue = Int(valueString) {
            return intValue
        } else if expectedType == Double.self, let doubleValue = Double(valueString) {
            return doubleValue
        } else if expectedType == Bool.self {
            if valueString == "true" { return true }
            if valueString == "false" { return false }
        }

        // Fallback: return the string value, the makeDestination closure will attempt cast
        return valueString
    }

    // MARK: - Per-Render Cleanup

    /// Clear transient state that is re-populated each render pass.
    func clearRenderState() {
        destinations.removeAll()
        toolbarItems.removeAll()
        searchBarInfo = nil
        toolbarBackground = nil
        toolbarTintColor = nil
    }

    // MARK: - Browser History Integration

    /// Set up the popstate listener to sync browser back/forward with the stack.
    func setupPopstateListenerIfNeeded() {
        guard !popstateListenerSetup else { return }
        popstateListenerSetup = true

        NavigationHistory.shared.onPopState { [weak self] state in
            guard let self = self else { return }

            // Parse the depth from the state
            if let depthStr = state.data["depth"], let targetDepth = Int(depthStr) {
                // Sync the view stack to match the target depth
                while self.viewStack.count > targetDepth {
                    self.viewStack.removeLast()
                    if !self.pathStack.isEmpty {
                        self.pathStack.removeLast()
                    }
                    if self.titleStack.count > self.viewStack.count + 1 {
                        self.titleStack.removeLast()
                    }
                    if self.displayModeStack.count > self.viewStack.count + 1 {
                        self.displayModeStack.removeLast()
                    }
                    if self.navBarHiddenStack.count > self.viewStack.count + 1 {
                        self.navBarHiddenStack.removeLast()
                    }
                }
            } else {
                // No depth info — pop to root
                self.viewStack.removeAll()
                self.pathStack.removeAll()
                self.titleStack = [self.titleStack.first ?? ""]
                self.displayModeStack = [self.displayModeStack.first ?? .large]
                self.navBarHiddenStack = [self.navBarHiddenStack.first ?? false]
            }
            self.renderScheduler?.scheduleRender()
        }
    }
}

// MARK: - Toolbar Item Info

/// Pre-rendered toolbar item with its placement information.
@MainActor
internal struct ToolbarItemInfo {
    /// Where this item should be placed in the navigation bar.
    let placement: ToolbarItemPlacement

    /// The pre-rendered VNode for this toolbar item's content.
    let node: VNode
}

// MARK: - Search Bar Info

/// Pre-rendered search bar information for placement in the navigation bar.
@MainActor
internal struct SearchBarInfo {
    /// The pre-rendered VNode for the search input.
    let node: VNode

    /// Where the search bar should be placed.
    let placement: SearchFieldPlacement
}
