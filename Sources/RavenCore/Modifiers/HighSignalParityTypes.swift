import Foundation

/// Controls background display behavior for compatible APIs.
public struct BackgroundDisplayMode: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = BackgroundDisplayMode("automatic")
    public static let always = BackgroundDisplayMode("always")
}

/// Controls page index display behavior for compatible APIs.
public struct IndexDisplayMode: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = IndexDisplayMode("automatic")
    public static let always = IndexDisplayMode("always")
}

/// Controls limiter behavior for compatible APIs.
public struct LimitBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = LimitBehavior("automatic")
    public static let always = LimitBehavior("always")
    public static let alwaysByFew = LimitBehavior("alwaysByFew")
    public static let alwaysByOne = LimitBehavior("alwaysByOne")
}

/// Controls scroll bounce behavior with SwiftUI-compatible naming.
public struct ScrollBounceBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ScrollBounceBehavior("automatic")
    public static let always = ScrollBounceBehavior("always")
    public static let basedOnSize = ScrollBounceBehavior("basedOnSize")

    internal var _bounceBehavior: BounceBehavior {
        switch rawValue {
        case "always":
            return .always
        case "basedOnSize":
            return .basedOnSize
        default:
            return .automatic
        }
    }
}

/// Options for toolbar customization.
public struct ToolbarCustomizationOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let alwaysAvailable = ToolbarCustomizationOptions(rawValue: 1 << 0)
}

/// An interface orientation value.
public enum InterfaceOrientation: String, Sendable, Hashable, CaseIterable {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
}

/// A pose payload for generic input devices.
public struct InputDevicePose: Sendable, Hashable {
    public var altitude: Double
    public var azimuth: Double

    public init(altitude: Double, azimuth: Double) {
        self.altitude = altitude
        self.azimuth = azimuth
    }
}

/// A pose payload for pencil-hover interactions.
public struct PencilHoverPose: Sendable, Hashable {
    public var altitude: Double
    public var azimuth: Double
    public var anchor: UnitPoint

    public init(altitude: Double, azimuth: Double, anchor: UnitPoint = .center) {
        self.altitude = altitude
        self.azimuth = azimuth
        self.anchor = anchor
    }
}

/// Controls focus evaluation behavior.
public struct DefaultFocusEvaluationPriority: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = DefaultFocusEvaluationPriority("automatic")
}

/// Controls menu ordering behavior.
public struct MenuOrder: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = MenuOrder("automatic")
}

/// Controls scene restoration behavior.
public struct SceneRestorationBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = SceneRestorationBehavior("automatic")
}

/// Controls how keyboard dismissal behaves while scrolling.
public struct ScrollDismissesKeyboardMode: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ScrollDismissesKeyboardMode("automatic")
}

/// Controls scroll indicator visibility preferences.
public struct ScrollIndicatorVisibility: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ScrollIndicatorVisibility("automatic")
    public static let visible = ScrollIndicatorVisibility("visible")
    public static let hidden = ScrollIndicatorVisibility("hidden")
}

/// Controls scroll input behavior preferences.
public struct ScrollInputBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ScrollInputBehavior("automatic")
}

/// Controls search presentation toolbar behavior.
public struct SearchPresentationToolbarBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = SearchPresentationToolbarBehavior("automatic")
    public static let avoidHidingContent = SearchPresentationToolbarBehavior("avoidHidingContent")
}

/// Controls search toolbar behavior.
public struct SearchToolbarBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = SearchToolbarBehavior("automatic")
}

/// Controls tab bar minimize behavior.
public struct TabBarMinimizeBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = TabBarMinimizeBehavior("automatic")
}

/// Controls tab customization behavior.
public struct TabCustomizationBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = TabCustomizationBehavior("automatic")
}

/// Controls default tab placement behavior.
public struct TabPlacement: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = TabPlacement("automatic")
}

/// Controls tab search activation behavior.
public struct TabSearchActivation: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = TabSearchActivation("automatic")
}

/// Controls table column alignment defaults.
public struct TableColumnAlignment: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = TableColumnAlignment("automatic")
}

/// Controls text input dictation behavior.
public struct TextInputDictationBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = TextInputDictationBehavior("automatic")
}

/// Controls toolbar label style behavior.
public struct ToolbarLabelStyle: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ToolbarLabelStyle("automatic")
}

/// Controls toolbar role behavior.
public struct ToolbarRole: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ToolbarRole("automatic")
    public static let browser = ToolbarRole("browser")
}

/// Controls window manager role behavior.
public struct WindowManagerRole: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = WindowManagerRole("automatic")
}

/// Controls window resizability behavior.
public struct WindowResizability: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = WindowResizability("automatic")
}

/// Controls full-screen toolbar visibility behavior.
public struct WindowToolbarFullScreenVisibility: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = WindowToolbarFullScreenVisibility("automatic")
}

/// Controls writing tools behavior.
public struct WritingToolsBehavior: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = WritingToolsBehavior("automatic")
}

/// Controls presentation background interaction behavior.
public struct PresentationBackgroundInteraction: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = PresentationBackgroundInteraction("automatic")
}

/// Controls presentation content interaction behavior.
public struct PresentationContentInteraction: Sendable, Hashable {
    private let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = PresentationContentInteraction("automatic")
}

/// Presentation sizing behavior.
public protocol PresentationSizing: Sendable {}

/// Automatic presentation sizing behavior.
public struct AutomaticPresentationSizing: PresentationSizing, Sendable, Hashable {
    public init() {}
}

extension PresentationSizing where Self == AutomaticPresentationSizing {
    public static var automatic: AutomaticPresentationSizing {
        AutomaticPresentationSizing()
    }
}

/// Hover-effect customization behavior.
public protocol CustomHoverEffect: Sendable {}

/// Default hover-effect behavior.
public struct AutomaticHoverEffect: CustomHoverEffect, Sendable, Hashable {
    public init() {}
}

extension CustomHoverEffect where Self == AutomaticHoverEffect {
    public static var automatic: AutomaticHoverEffect {
        AutomaticHoverEffect()
    }
}

/// Navigation transition behavior.
public protocol NavigationTransition: Sendable {}

/// Automatic navigation transition behavior.
public struct AutomaticNavigationTransition: NavigationTransition, Sendable, Hashable {
    public init() {}
}

extension NavigationTransition where Self == AutomaticNavigationTransition {
    public static var automatic: AutomaticNavigationTransition {
        AutomaticNavigationTransition()
    }
}
