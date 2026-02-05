import Foundation

// MARK: - Accessibility Label, Value, and Hint Modifiers

extension View {
    /// Sets the accessibility label for this view.
    ///
    /// The accessibility label is a brief, localized description of the view
    /// that VoiceOver and other assistive technologies read to the user.
    ///
    /// ## Overview
    ///
    /// Use accessibility labels to provide clear, concise descriptions:
    ///
    /// ```swift
    /// Image(systemName: "star.fill")
    ///     .accessibilityLabel("Favorite")
    /// ```
    ///
    /// ## Guidelines
    ///
    /// - Keep labels brief and descriptive
    /// - Don't include the element type (e.g., "button")
    /// - Use sentence case, not title case
    /// - Localize all labels
    ///
    /// - Parameter label: A brief description of the view
    /// - Returns: A view with the accessibility label set
    @MainActor
    public func accessibilityLabel(_ label: String) -> some View {
        AccessibilityModifier(
            content: self,
            label: label,
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

    /// Sets the accessibility label using a localized string key.
    ///
    /// - Parameter labelKey: A localized string key for the label
    /// - Returns: A view with the accessibility label set
    @MainActor
    public func accessibilityLabel(_ labelKey: LocalizedStringKey) -> some View {
        accessibilityLabel(labelKey.stringValue)
    }

    /// Sets the accessibility hint for this view.
    ///
    /// The accessibility hint provides additional context about what happens
    /// when the user interacts with the view. It's read after the label.
    ///
    /// ## Overview
    ///
    /// Use hints to describe the result of an action:
    ///
    /// ```swift
    /// Button("Delete") { }
    ///     .accessibilityLabel("Delete item")
    ///     .accessibilityHint("Removes the item from your list")
    /// ```
    ///
    /// ## Guidelines
    ///
    /// - Start with a verb (e.g., "Opens", "Selects", "Closes")
    /// - Describe the result, not the gesture
    /// - Keep hints short and optional
    /// - Don't repeat information from the label
    ///
    /// - Parameter hint: A description of what happens when interacting with the view
    /// - Returns: A view with the accessibility hint set
    @MainActor
    public func accessibilityHint(_ hint: String) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: hint,
            value: nil,
            role: nil,
            traits: nil,
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

    /// Sets the accessibility hint using a localized string key.
    ///
    /// - Parameter hintKey: A localized string key for the hint
    /// - Returns: A view with the accessibility hint set
    @MainActor
    public func accessibilityHint(_ hintKey: LocalizedStringKey) -> some View {
        accessibilityHint(hintKey.stringValue)
    }

    /// Sets the accessibility value for this view.
    ///
    /// The accessibility value represents the current value of a control,
    /// such as the position of a slider or the state of a switch.
    ///
    /// ## Overview
    ///
    /// Use accessibility values for controls with changing states:
    ///
    /// ```swift
    /// Slider(value: $volume, in: 0...100)
    ///     .accessibilityLabel("Volume")
    ///     .accessibilityValue("\(Int(volume)) percent")
    /// ```
    ///
    /// ## Guidelines
    ///
    /// - Update values dynamically as the control changes
    /// - Include units (e.g., "50 percent", "3 items")
    /// - Keep values concise
    ///
    /// - Parameter value: The current value or state of the view
    /// - Returns: A view with the accessibility value set
    @MainActor
    public func accessibilityValue(_ value: String) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: value,
            role: nil,
            traits: nil,
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
