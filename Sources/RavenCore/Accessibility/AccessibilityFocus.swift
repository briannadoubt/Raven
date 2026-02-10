import Foundation

// MARK: - Accessibility Focus and State Modifiers

extension View {
    /// Indicates whether this view is expanded or collapsed.
    ///
    /// Use this modifier for disclosure controls, accordions, and expandable sections.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// Button("Toggle Section") { isExpanded.toggle() }
    ///     .accessibilityExpanded(isExpanded)
    /// ```
    ///
    /// - Parameter isExpanded: Whether the view is expanded
    /// - Returns: A view with the expanded state set
    @MainActor
    public func accessibilityExpanded(_ isExpanded: Bool) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: nil,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: isExpanded,
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

    /// Indicates whether this toggle button is pressed.
    ///
    /// Use this modifier for toggle buttons that maintain a pressed/unpressed state.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// Button("Bold") { isBold.toggle() }
    ///     .accessibilityPressed(isBold)
    /// ```
    ///
    /// - Parameter isPressed: Whether the button is pressed
    /// - Returns: A view with the pressed state set
    @MainActor
    public func accessibilityPressed(_ isPressed: Bool) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: nil,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: nil,
            pressed: isPressed,
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
