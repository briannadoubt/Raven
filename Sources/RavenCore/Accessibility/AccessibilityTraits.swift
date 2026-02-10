import Foundation

// MARK: - Accessibility Traits

/// Traits that describe additional characteristics of UI elements.
///
/// Traits provide supplementary information about element behavior and state
/// beyond the basic role. Multiple traits can be combined.
///
/// ## Overview
///
/// Use traits to communicate additional element characteristics:
///
/// ```swift
/// Button("Important") { }
///     .accessibilityTraits([.isButton, .isHeader])
/// ```
public struct AccessibilityTraits: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Element is a button
    public static let isButton = AccessibilityTraits(rawValue: 1 << 0)
    /// Element is a header
    public static let isHeader = AccessibilityTraits(rawValue: 1 << 1)
    /// Element is a link
    public static let isLink = AccessibilityTraits(rawValue: 1 << 2)
    /// Element is an image
    public static let isImage = AccessibilityTraits(rawValue: 1 << 3)
    /// Element is selected
    public static let isSelected = AccessibilityTraits(rawValue: 1 << 4)
    /// Element plays sound
    public static let playsSound = AccessibilityTraits(rawValue: 1 << 5)
    /// Element is a keyboard key
    public static let isKeyboardKey = AccessibilityTraits(rawValue: 1 << 6)
    /// Element is static text
    public static let isStaticText = AccessibilityTraits(rawValue: 1 << 7)
    /// Element provides summary information
    public static let isSummaryElement = AccessibilityTraits(rawValue: 1 << 8)
    /// Element is not enabled/interactive
    public static let isNotEnabled = AccessibilityTraits(rawValue: 1 << 9)
    /// Element updates frequently
    public static let updatesFrequently = AccessibilityTraits(rawValue: 1 << 10)
    /// Element starts media playback
    public static let startsMediaSession = AccessibilityTraits(rawValue: 1 << 11)
    /// Element allows direct interaction
    public static let allowsDirectInteraction = AccessibilityTraits(rawValue: 1 << 12)
    /// Element causes content update
    public static let causesPageTurn = AccessibilityTraits(rawValue: 1 << 13)
    /// Element is a tab bar
    public static let isTabBar = AccessibilityTraits(rawValue: 1 << 14)
}

// MARK: - Accessibility Traits Modifier

extension View {
    /// Sets accessibility traits for this view.
    ///
    /// Traits provide supplementary information about the view's characteristics
    /// beyond its basic role. Multiple traits can be combined.
    ///
    /// ## Overview
    ///
    /// Use traits to describe additional characteristics:
    ///
    /// ```swift
    /// Button("Submit") { }
    ///     .accessibilityTraits([.isButton, .isHeader])
    /// ```
    ///
    /// - Parameter traits: The accessibility traits for the view
    /// - Returns: A view with the accessibility traits set
    @MainActor
    public func accessibilityTraits(_ traits: AccessibilityTraits) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: nil,
            traits: traits,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }
}
