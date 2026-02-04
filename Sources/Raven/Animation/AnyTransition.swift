import Foundation

/// A type-erased transition that can animate view insertion and removal.
///
/// Transitions define how views animate when they appear or disappear from the
/// view hierarchy. They work seamlessly with conditional view rendering and
/// can be combined to create sophisticated entrance and exit effects.
///
/// ## Basic Transitions
///
/// Raven provides several built-in transitions:
///
/// ```swift
/// if showDetails {
///     DetailView()
///         .transition(.opacity)  // Fade in and out
/// }
///
/// if showMenu {
///     MenuView()
///         .transition(.scale)  // Scale from 0 to 1
/// }
///
/// if showSidebar {
///     SidebarView()
///         .transition(.move(edge: .leading))  // Slide from leading edge
/// }
/// ```
///
/// ## Combining Transitions
///
/// Combine multiple transitions to create more complex effects:
///
/// ```swift
/// if showNotification {
///     NotificationView()
///         .transition(
///             .opacity.combined(with: .scale)
///         )
/// }
/// ```
///
/// ## Asymmetric Transitions
///
/// Use different transitions for insertion and removal:
///
/// ```swift
/// if showCard {
///     CardView()
///         .transition(
///             .asymmetric(
///                 insertion: .move(edge: .trailing),
///                 removal: .opacity
///             )
///         )
/// }
/// ```
///
/// ## CSS Implementation
///
/// Transitions in Raven are implemented using CSS animations and transforms.
/// Each transition type generates appropriate CSS keyframe animations and
/// applies them during view insertion and removal.
///
/// For example, `.opacity` generates:
/// ```css
/// @keyframes fadeIn {
///     from { opacity: 0; }
///     to { opacity: 1; }
/// }
///
/// @keyframes fadeOut {
///     from { opacity: 1; }
///     to { opacity: 0; }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Transitions
/// - ``identity``
/// - ``opacity``
/// - ``scale(scale:anchor:)``
/// - ``slide``
/// - ``move(edge:)``
/// - ``offset(x:y:)``
/// - ``push(from:)``
/// - ``modifier(active:identity:)``
///
/// ### Combining Transitions
/// - ``combined(with:)``
/// - ``asymmetric(insertion:removal:)``
///
/// - Note: Transitions are only visible when views are inserted or removed
///   from the view hierarchy. Use them with conditional view rendering
///   (if statements) or navigation transitions.
///
/// ## See Also
/// - ``Animation``
/// - ``withAnimation(_:_:)``
/// - ``View/transition(_:)``
public struct AnyTransition: Sendable, Hashable {
    /// The internal representation of the transition behavior.
    internal let storage: Storage

    internal indirect enum Storage: Sendable, Hashable {
        /// No transition effect.
        case identity

        /// Opacity transition (fade in/out).
        case opacity

        /// Scale transition with anchor point.
        case scale(scale: Double, anchor: UnitPoint)

        /// Slide from bottom edge.
        case slide

        /// Move from specified edge.
        case move(edge: Edge)

        /// Offset by x and y.
        case offset(x: Double, y: Double)

        /// Push transition (slide while staying opaque).
        case push(edge: Edge)

        /// Custom modifier transition.
        case modifier(active: String, identity: String)

        /// Combined transition (both effects simultaneously).
        case combined(AnyTransition, AnyTransition)

        /// Asymmetric transition (different insertion and removal).
        case asymmetric(insertion: AnyTransition, removal: AnyTransition)
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    // MARK: - Basic Transitions

    /// A transition that doesn't animate.
    ///
    /// Use this transition when you want views to appear or disappear
    /// immediately without any animation effect.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if showContent {
    ///     ContentView()
    ///         .transition(.identity)  // No animation
    /// }
    /// ```
    public static let identity = AnyTransition(storage: .identity)

    /// A transition that fades the view in and out.
    ///
    /// The opacity transition animates the view's opacity from 0 to 1 when
    /// inserted, and from 1 to 0 when removed.
    ///
    /// ## CSS Implementation
    ///
    /// Generates CSS animations:
    /// ```css
    /// @keyframes fadeIn {
    ///     from { opacity: 0; }
    ///     to { opacity: 1; }
    /// }
    ///
    /// @keyframes fadeOut {
    ///     from { opacity: 1; }
    ///     to { opacity: 0; }
    /// }
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// if showDetails {
    ///     DetailView()
    ///         .transition(.opacity)
    /// }
    /// ```
    ///
    /// - Note: This is one of the most commonly used transitions for
    ///   smooth, subtle view changes.
    public static let opacity = AnyTransition(storage: .opacity)

    /// A transition that scales the view during insertion and removal.
    ///
    /// The scale transition animates the view's scale from the specified
    /// value to 1.0 when inserted, and from 1.0 to the specified value
    /// when removed. The transformation is anchored at the specified point.
    ///
    /// ## CSS Implementation
    ///
    /// Generates CSS animations:
    /// ```css
    /// @keyframes scaleIn {
    ///     from { transform: scale(0); }
    ///     to { transform: scale(1); }
    /// }
    ///
    /// @keyframes scaleOut {
    ///     from { transform: scale(1); }
    ///     to { transform: scale(0); }
    /// }
    /// ```
    ///
    /// The `transform-origin` CSS property is set based on the anchor point.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Scale from center (default)
    /// if showPopup {
    ///     PopupView()
    ///         .transition(.scale())
    /// }
    ///
    /// // Scale from top-leading corner
    /// if showMenu {
    ///     MenuView()
    ///         .transition(.scale(scale: 0.5, anchor: .topLeading))
    /// }
    ///
    /// // Scale from bottom
    /// if showSheet {
    ///     SheetView()
    ///         .transition(.scale(scale: 0.8, anchor: .bottom))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scale: The initial/final scale factor. Defaults to 0.0.
    ///   - anchor: The anchor point for the scale transformation. Defaults to `.center`.
    ///
    /// - Note: A scale of 0.0 makes the view invisible, while 1.0 is the
    ///   normal size. Values greater than 1.0 make the view larger.
    public static func scale(scale: Double = 0.0, anchor: UnitPoint = .center) -> AnyTransition {
        AnyTransition(storage: .scale(scale: scale, anchor: anchor))
    }

    /// A transition that slides the view from the bottom edge.
    ///
    /// The slide transition is equivalent to `.move(edge: .bottom)` and
    /// animates the view sliding up from below when inserted, and down
    /// out of view when removed.
    ///
    /// ## CSS Implementation
    ///
    /// Generates CSS animations:
    /// ```css
    /// @keyframes slideIn {
    ///     from { transform: translateY(100%); }
    ///     to { transform: translateY(0); }
    /// }
    ///
    /// @keyframes slideOut {
    ///     from { transform: translateY(0); }
    ///     to { transform: translateY(100%); }
    /// }
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// if showSheet {
    ///     SheetView()
    ///         .transition(.slide)
    /// }
    /// ```
    ///
    /// - Note: For more control over the slide direction, use `.move(edge:)`.
    public static let slide = AnyTransition(storage: .slide)

    /// A transition that moves the view from the specified edge.
    ///
    /// The move transition slides the view in from the specified edge when
    /// inserted, and slides it out to that edge when removed.
    ///
    /// ## CSS Implementation
    ///
    /// Generates CSS animations based on the edge:
    /// - `.top`: `translateY(-100%)` to `translateY(0)`
    /// - `.bottom`: `translateY(100%)` to `translateY(0)`
    /// - `.leading`: `translateX(-100%)` to `translateX(0)`
    /// - `.trailing`: `translateX(100%)` to `translateX(0)`
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Slide from leading edge (left in LTR)
    /// if showSidebar {
    ///     SidebarView()
    ///         .transition(.move(edge: .leading))
    /// }
    ///
    /// // Slide from top
    /// if showBanner {
    ///     BannerView()
    ///         .transition(.move(edge: .top))
    /// }
    ///
    /// // Slide from trailing edge
    /// if showDetailPanel {
    ///     DetailPanel()
    ///         .transition(.move(edge: .trailing))
    /// }
    /// ```
    ///
    /// - Parameter edge: The edge from which to slide the view.
    ///
    /// - Note: The leading and trailing edges automatically adapt to the
    ///   current layout direction (LTR or RTL).
    public static func move(edge: Edge) -> AnyTransition {
        AnyTransition(storage: .move(edge: edge))
    }

    /// A transition that offsets the view by the specified amounts.
    ///
    /// The offset transition translates the view by the specified x and y
    /// values when inserted or removed. Positive x moves right, positive y
    /// moves down.
    ///
    /// ## CSS Implementation
    ///
    /// Generates CSS animations:
    /// ```css
    /// @keyframes offsetIn {
    ///     from { transform: translate(50px, 100px); }
    ///     to { transform: translate(0, 0); }
    /// }
    ///
    /// @keyframes offsetOut {
    ///     from { transform: translate(0, 0); }
    ///     to { transform: translate(50px, 100px); }
    /// }
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Offset from top-right
    /// if showNotification {
    ///     NotificationView()
    ///         .transition(.offset(x: 100, y: -50))
    /// }
    ///
    /// // Offset horizontally only
    /// if showTooltip {
    ///     TooltipView()
    ///         .transition(.offset(x: 20, y: 0))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - x: The horizontal offset in pixels. Defaults to 0.
    ///   - y: The vertical offset in pixels. Defaults to 0.
    ///
    /// - Note: For edge-based sliding, prefer `.move(edge:)` which uses
    ///   percentage-based offsets that adapt to the view's size.
    public static func offset(x: Double = 0, y: Double = 0) -> AnyTransition {
        AnyTransition(storage: .offset(x: x, y: y))
    }

    /// A transition that slides the view from the specified edge while maintaining opacity.
    ///
    /// The push transition is similar to `.move(edge:)` but keeps the view fully opaque
    /// throughout the animation. This creates a more solid, "pushing" effect compared to
    /// the standard move which may have transparency changes.
    ///
    /// ## CSS Implementation
    ///
    /// Generates CSS animations that only animate transform, keeping opacity at 1:
    /// ```css
    /// @keyframes pushIn {
    ///     from { transform: translateX(100%); opacity: 1; }
    ///     to { transform: translateX(0); opacity: 1; }
    /// }
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Push from trailing edge
    /// if showPanel {
    ///     PanelView()
    ///         .transition(.push(from: .trailing))
    /// }
    ///
    /// // Push from bottom (sheet-like)
    /// if showSheet {
    ///     SheetView()
    ///         .transition(.push(from: .bottom))
    /// }
    /// ```
    ///
    /// - Parameter edge: The edge from which to push the view.
    ///
    /// - Note: This transition is particularly useful for navigation-style transitions
    ///   where you want a solid, opaque slide effect.
    public static func push(from edge: Edge) -> AnyTransition {
        AnyTransition(storage: .push(edge: edge))
    }

    /// Creates a transition that applies custom view modifiers for active and identity states.
    ///
    /// The modifier transition allows you to create completely custom transition effects
    /// by specifying two different view modifiers: one for the "active" state (when the
    /// view is being inserted or removed) and one for the "identity" state (the normal state).
    ///
    /// ## How It Works
    ///
    /// During insertion:
    /// - View starts with the `active` modifier applied
    /// - Animates to the `identity` modifier
    ///
    /// During removal:
    /// - View starts with the `identity` modifier
    /// - Animates to the `active` modifier
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct BlurModifier: ViewModifier {
    ///     let amount: Double
    ///
    ///     func body(content: Content) -> some View {
    ///         content.blur(radius: amount)
    ///     }
    /// }
    ///
    /// // Create a transition that fades and blurs
    /// let blurTransition = AnyTransition.modifier(
    ///     active: BlurModifier(amount: 10),
    ///     identity: BlurModifier(amount: 0)
    /// )
    ///
    /// if showDetails {
    ///     DetailView()
    ///         .transition(blurTransition)
    /// }
    /// ```
    ///
    /// ## Complex Example
    ///
    /// ```swift
    /// struct RotateScaleModifier: ViewModifier {
    ///     let rotation: Double
    ///     let scale: Double
    ///
    ///     func body(content: Content) -> some View {
    ///         content
    ///             .rotationEffect(.degrees(rotation))
    ///             .scaleEffect(scale)
    ///     }
    /// }
    ///
    /// let spinTransition = AnyTransition.modifier(
    ///     active: RotateScaleModifier(rotation: 360, scale: 0),
    ///     identity: RotateScaleModifier(rotation: 0, scale: 1)
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - active: The modifier to apply in the active state (insertion start/removal end).
    ///   - identity: The modifier to apply in the identity state (normal/final state).
    /// - Returns: A transition that animates between the two modifier states.
    ///
    /// - Note: The modifiers must have animatable properties for smooth transitions.
    ///   Properties like opacity, scale, rotation, offset, and color work well.
    public static func modifier<M: ViewModifier>(
        active: M,
        identity: M
    ) -> AnyTransition {
        // For now, we store string descriptions of the modifiers
        // In a full implementation, we would need to serialize the modifiers to CSS
        let activeDesc = String(describing: active)
        let identityDesc = String(describing: identity)
        return AnyTransition(storage: .modifier(active: activeDesc, identity: identityDesc))
    }

    // MARK: - Composition

    /// Combines this transition with another transition.
    ///
    /// The combined transition applies both effects simultaneously during
    /// insertion and removal. This allows you to create more complex
    /// animations by layering multiple transition effects.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Fade and scale together
    /// if showDialog {
    ///     DialogView()
    ///         .transition(.opacity.combined(with: .scale))
    /// }
    ///
    /// // Scale and slide together
    /// if showCard {
    ///     CardView()
    ///         .transition(
    ///             .scale(scale: 0.5)
    ///                 .combined(with: .move(edge: .bottom))
    ///         )
    /// }
    ///
    /// // Multiple combinations
    /// if showPanel {
    ///     PanelView()
    ///         .transition(
    ///             .opacity
    ///                 .combined(with: .scale)
    ///                 .combined(with: .offset(x: 0, y: 20))
    ///         )
    /// }
    /// ```
    ///
    /// - Parameter other: The transition to combine with this one.
    /// - Returns: A new transition that applies both effects.
    ///
    /// - Note: Combined transitions apply all effects simultaneously with
    ///   the same timing and animation curve.
    public func combined(with other: AnyTransition) -> AnyTransition {
        AnyTransition(storage: .combined(self, other))
    }

    /// Creates a transition with different effects for insertion and removal.
    ///
    /// Asymmetric transitions allow you to specify different animations for
    /// when a view appears versus when it disappears. This is useful for
    /// creating more dynamic and contextual animations.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Slide in from trailing, fade out
    /// if showNotification {
    ///     NotificationView()
    ///         .transition(
    ///             .asymmetric(
    ///                 insertion: .move(edge: .trailing),
    ///                 removal: .opacity
    ///             )
    ///         )
    /// }
    ///
    /// // Scale in, slide out to bottom
    /// if showModal {
    ///     ModalView()
    ///         .transition(
    ///             .asymmetric(
    ///                 insertion: .scale,
    ///                 removal: .move(edge: .bottom)
    ///             )
    ///         )
    /// }
    ///
    /// // Complex asymmetric with combinations
    /// if showPanel {
    ///     PanelView()
    ///         .transition(
    ///             .asymmetric(
    ///                 insertion: .opacity.combined(with: .scale),
    ///                 removal: .move(edge: .leading)
    ///             )
    ///         )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - insertion: The transition to use when the view is inserted.
    ///   - removal: The transition to use when the view is removed.
    /// - Returns: A new transition with asymmetric behavior.
    ///
    /// - Note: Asymmetric transitions are particularly useful for
    ///   notifications, tooltips, and contextual overlays where the
    ///   entrance and exit should have different visual characteristics.
    public static func asymmetric(
        insertion: AnyTransition,
        removal: AnyTransition
    ) -> AnyTransition {
        AnyTransition(storage: .asymmetric(insertion: insertion, removal: removal))
    }
}

// MARK: - CSS Generation

extension AnyTransition {
    /// Generates CSS animation name for insertion.
    ///
    /// This is used internally by the rendering system to generate
    /// appropriate CSS keyframe animations.
    ///
    /// - Returns: The CSS animation name for insertion.
    internal func cssInsertionAnimation() -> String {
        switch storage {
        case .identity:
            return "none"
        case .opacity:
            return "fadeIn"
        case .scale:
            return "scaleIn"
        case .slide, .move:
            return "slideIn"
        case .offset:
            return "offsetIn"
        case .push:
            return "pushIn"
        case .modifier:
            return "modifierIn"
        case .combined(let first, let second):
            return "\(first.cssInsertionAnimation()), \(second.cssInsertionAnimation())"
        case .asymmetric(let insertion, _):
            return insertion.cssInsertionAnimation()
        }
    }

    /// Generates CSS animation name for removal.
    ///
    /// This is used internally by the rendering system to generate
    /// appropriate CSS keyframe animations.
    ///
    /// - Returns: The CSS animation name for removal.
    internal func cssRemovalAnimation() -> String {
        switch storage {
        case .identity:
            return "none"
        case .opacity:
            return "fadeOut"
        case .scale:
            return "scaleOut"
        case .slide, .move:
            return "slideOut"
        case .offset:
            return "offsetOut"
        case .push:
            return "pushOut"
        case .modifier:
            return "modifierOut"
        case .combined(let first, let second):
            return "\(first.cssRemovalAnimation()), \(second.cssRemovalAnimation())"
        case .asymmetric(_, let removal):
            return removal.cssRemovalAnimation()
        }
    }

    /// Generates CSS keyframe definitions for this transition.
    ///
    /// This is used internally by the rendering system to inject
    /// keyframe animations into the page's stylesheet.
    ///
    /// - Returns: CSS keyframe definitions.
    internal func cssKeyframes() -> String {
        switch storage {
        case .identity:
            return ""

        case .opacity:
            return """
            @keyframes fadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
            }
            @keyframes fadeOut {
                from { opacity: 1; }
                to { opacity: 0; }
            }
            """

        case .scale(let scale, _):
            return """
            @keyframes scaleIn {
                from { transform: scale(\(scale)); }
                to { transform: scale(1); }
            }
            @keyframes scaleOut {
                from { transform: scale(1); }
                to { transform: scale(\(scale)); }
            }
            """

        case .slide:
            return """
            @keyframes slideIn {
                from { transform: translateY(100%); }
                to { transform: translateY(0); }
            }
            @keyframes slideOut {
                from { transform: translateY(0); }
                to { transform: translateY(100%); }
            }
            """

        case .move(let edge):
            let fromTransform = edge.cssTransformAxis
            return """
            @keyframes slideIn {
                from { transform: \(fromTransform); }
                to { transform: translate(0, 0); }
            }
            @keyframes slideOut {
                from { transform: translate(0, 0); }
                to { transform: \(fromTransform); }
            }
            """

        case .offset(let x, let y):
            return """
            @keyframes offsetIn {
                from { transform: translate(\(x)px, \(y)px); }
                to { transform: translate(0, 0); }
            }
            @keyframes offsetOut {
                from { transform: translate(0, 0); }
                to { transform: translate(\(x)px, \(y)px); }
            }
            """

        case .push(let edge):
            let fromTransform = edge.cssTransformAxis
            return """
            @keyframes pushIn {
                from { transform: \(fromTransform); opacity: 1; }
                to { transform: translate(0, 0); opacity: 1; }
            }
            @keyframes pushOut {
                from { transform: translate(0, 0); opacity: 1; }
                to { transform: \(fromTransform); opacity: 1; }
            }
            """

        case .modifier(let active, let identity):
            // For now, generate placeholder keyframes
            // In a full implementation, this would generate CSS from the actual modifiers
            return """
            @keyframes modifierIn {
                from { /* \(active) */ }
                to { /* \(identity) */ }
            }
            @keyframes modifierOut {
                from { /* \(identity) */ }
                to { /* \(active) */ }
            }
            """

        case .combined(let first, let second):
            return first.cssKeyframes() + "\n" + second.cssKeyframes()

        case .asymmetric(let insertion, let removal):
            return insertion.cssKeyframes() + "\n" + removal.cssKeyframes()
        }
    }

    /// Returns the CSS transform-origin value if this transition uses scale.
    ///
    /// - Returns: CSS transform-origin value, or nil if not applicable.
    internal func cssTransformOrigin() -> String? {
        switch storage {
        case .scale(_, let anchor):
            return anchor.cssTransformOrigin
        case .combined(let first, let second):
            return first.cssTransformOrigin() ?? second.cssTransformOrigin()
        case .asymmetric(let insertion, _):
            return insertion.cssTransformOrigin()
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension AnyTransition: CustomStringConvertible {
    public var description: String {
        switch storage {
        case .identity:
            return "AnyTransition.identity"
        case .opacity:
            return "AnyTransition.opacity"
        case .scale(let scale, let anchor):
            return "AnyTransition.scale(scale: \(scale), anchor: \(anchor))"
        case .slide:
            return "AnyTransition.slide"
        case .move(let edge):
            return "AnyTransition.move(edge: .\(edge))"
        case .offset(let x, let y):
            return "AnyTransition.offset(x: \(x), y: \(y))"
        case .push(let edge):
            return "AnyTransition.push(from: .\(edge))"
        case .modifier(let active, let identity):
            return "AnyTransition.modifier(active: \(active), identity: \(identity))"
        case .combined(let first, let second):
            return "\(first).combined(with: \(second))"
        case .asymmetric(let insertion, let removal):
            return "AnyTransition.asymmetric(insertion: \(insertion), removal: \(removal))"
        }
    }
}
