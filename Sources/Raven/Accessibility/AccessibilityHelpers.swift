import Foundation

// MARK: - Accessibility Helper Extensions

/// Convenience extensions for common accessibility patterns.
///
/// These helpers make it easier to apply accessibility attributes
/// for common use cases without needing to know all the ARIA details.

extension View {
    /// Marks this view as an accessible heading with the specified level.
    ///
    /// Headings provide structure to the page and help users navigate
    /// with assistive technologies. Levels should follow a logical hierarchy
    /// (h1 for main title, h2 for sections, h3 for subsections, etc.).
    ///
    /// ## Overview
    ///
    /// ```swift
    /// Text("Page Title")
    ///     .accessibilityHeading(level: 1)
    ///
    /// Text("Section Title")
    ///     .accessibilityHeading(level: 2)
    /// ```
    ///
    /// ## Guidelines
    ///
    /// - Start with level 1 for the main page title
    /// - Use levels sequentially (don't skip from 1 to 3)
    /// - Each page should have exactly one level 1 heading
    /// - Use levels 2-6 for subsections
    ///
    /// - Parameter level: The heading level (1-6)
    /// - Returns: A view marked as a heading
    @MainActor
    public func accessibilityHeading(level: Int = 1) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: .heading,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: max(1, min(6, level)), // Clamp to 1-6
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }

    /// Marks this list item with its position in the set.
    ///
    /// Use this for list items to help users understand their position
    /// when navigating with assistive technologies.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ///     ItemView(item: item)
    ///         .accessibilityListItem(position: index + 1, total: items.count)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - position: The 1-based position in the set
    ///   - total: The total number of items in the set
    /// - Returns: A view marked with list item position
    @MainActor
    public func accessibilityListItem(position: Int, total: Int) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: .listItem,
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
            posInSet: position,
            setSize: total,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }

    /// Marks this form field as invalid with an optional error message reference.
    ///
    /// Use this to indicate validation errors on form fields. Combine with
    /// `accessibilityDescribedBy` to reference the error message element.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// TextField("Email", text: $email)
    ///     .accessibilityInvalid(isInvalid: !emailValid, describedBy: "email-error")
    ///
    /// if !emailValid {
    ///     Text("Please enter a valid email address")
    ///         .accessibilityIdentifier("email-error")
    ///         .accessibilityRole(.alert)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isInvalid: Whether the field contains invalid data
    ///   - describedBy: Optional ID of the error message element
    /// - Returns: A view marked as invalid
    @MainActor
    public func accessibilityInvalid(isInvalid: Bool, describedBy: String? = nil) -> some View {
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
            describedBy: describedBy,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: isInvalid,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }

    /// Marks this form field as required.
    ///
    /// Use this to indicate that a field must be filled out before form submission.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .accessibilityRequired(true)
    ///     .accessibilityLabel("Name (required)")
    /// ```
    ///
    /// - Parameter isRequired: Whether the field is required
    /// - Returns: A view marked as required
    @MainActor
    public func accessibilityRequired(_ isRequired: Bool = true) -> some View {
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
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: isRequired,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }

    /// Marks this form field as read-only.
    ///
    /// Use this for fields that display data but cannot be edited.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// TextField("User ID", text: .constant(userId))
    ///     .accessibilityReadonly(true)
    /// ```
    ///
    /// - Parameter isReadonly: Whether the field is read-only
    /// - Returns: A view marked as read-only
    @MainActor
    public func accessibilityReadonly(_ isReadonly: Bool = true) -> some View {
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
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: isReadonly,
            selected: nil,
            modal: nil
        )
    }

    /// Marks this element as selected within a selectable group.
    ///
    /// Use this for elements within lists, grids, or tab panels where
    /// multiple items can be selected.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// ForEach(items) { item in
    ///     ItemView(item: item)
    ///         .accessibilitySelected(selectedItems.contains(item.id))
    /// }
    /// ```
    ///
    /// - Parameter isSelected: Whether the element is selected
    /// - Returns: A view marked with selection state
    @MainActor
    public func accessibilitySelected(_ isSelected: Bool) -> some View {
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
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: isSelected,
            modal: nil
        )
    }

    /// Marks this view as a landmark region with a label.
    ///
    /// Landmarks help users navigate the page structure with assistive technologies.
    /// Use this for major sections of your page.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// VStack {
    ///     // Sidebar content
    /// }
    /// .accessibilityLandmark(.complementary, label: "Filters")
    ///
    /// VStack {
    ///     // Main content
    /// }
    /// .accessibilityLandmark(.main, label: "Product list")
    /// ```
    ///
    /// ## Common Landmarks
    ///
    /// - **main**: Primary content (one per page)
    /// - **navigation**: Navigation sections
    /// - **complementary**: Supporting content (sidebars)
    /// - **search**: Search functionality
    /// - **banner**: Site header
    /// - **contentInfo**: Site footer
    ///
    /// - Parameters:
    ///   - role: The landmark role
    ///   - label: A descriptive label for the landmark
    /// - Returns: A view marked as a landmark
    @MainActor
    public func accessibilityLandmark(_ role: AccessibilityRole, label: String? = nil) -> some View {
        let modifier = AccessibilityModifier(
            content: self,
            label: label,
            hint: nil,
            value: nil,
            role: role,
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
        return modifier
    }

    /// Marks this view as an alert for important messages.
    ///
    /// Use this for error messages, warnings, or important status updates
    /// that need immediate attention. Alerts are announced by screen readers
    /// as soon as they appear.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// if let error = errorMessage {
    ///     Text(error)
    ///         .accessibilityAlert()
    /// }
    /// ```
    ///
    /// - Parameter message: Optional message for the alert
    /// - Returns: A view marked as an alert
    @MainActor
    public func accessibilityAlert(message: String? = nil) -> some View {
        AccessibilityModifier(
            content: self,
            label: message,
            hint: nil,
            value: nil,
            role: .alert,
            traits: nil,
            liveRegion: .assertive,
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

    /// Marks this view as a status message.
    ///
    /// Use this for non-critical status updates like loading indicators,
    /// progress messages, or informational notices. Status messages are
    /// announced politely when the user is idle.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// Text("Saving...")
    ///     .accessibilityStatus()
    ///
    /// Text("Saved successfully")
    ///     .accessibilityStatus()
    /// ```
    ///
    /// - Parameter message: Optional message for the status
    /// - Returns: A view marked as a status
    @MainActor
    public func accessibilityStatus(message: String? = nil) -> some View {
        AccessibilityModifier(
            content: self,
            label: message,
            hint: nil,
            value: nil,
            role: .status,
            traits: nil,
            liveRegion: .polite,
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

    /// Marks this button as a toggle button with pressed state.
    ///
    /// Use this for buttons that maintain a pressed/unpressed state,
    /// like formatting buttons in a text editor.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// Button("Bold") { isBold.toggle() }
    ///     .accessibilityToggleButton(isPressed: isBold)
    /// ```
    ///
    /// - Parameter isPressed: Whether the button is currently pressed
    /// - Returns: A view marked as a toggle button
    @MainActor
    public func accessibilityToggleButton(isPressed: Bool) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: .button,
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

    /// Marks this button as a disclosure button that expands/collapses content.
    ///
    /// Use this for buttons that show/hide additional content, like
    /// accordion headers or expandable sections.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// Button("Show Details") { isExpanded.toggle() }
    ///     .accessibilityDisclosureButton(
    ///         isExpanded: isExpanded,
    ///         controls: "details-content"
    ///     )
    ///
    /// if isExpanded {
    ///     VStack {
    ///         // Details
    ///     }
    ///     .accessibilityIdentifier("details-content")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isExpanded: Whether the controlled content is expanded
    ///   - controls: The ID of the controlled content element
    /// - Returns: A view marked as a disclosure button
    @MainActor
    public func accessibilityDisclosureButton(isExpanded: Bool, controls: String) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: .button,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: controls,
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
}

// MARK: - Progress and Loading Indicators

extension View {
    /// Marks this view as a progress indicator.
    ///
    /// Use this for progress bars, spinners, or other loading indicators.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// ProgressView(value: progress, total: 100)
    ///     .accessibilityProgress(
    ///         value: Int(progress),
    ///         total: 100,
    ///         label: "Upload progress"
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - value: Current progress value
    ///   - total: Maximum progress value
    ///   - label: Descriptive label
    /// - Returns: A view marked as a progress indicator
    @MainActor
    public func accessibilityProgress(value: Int, total: Int, label: String? = nil) -> some View {
        let percentValue = total > 0 ? "\(value * 100 / total) percent" : "Loading"
        return AccessibilityModifier(
            content: self,
            label: label,
            hint: nil,
            value: percentValue,
            role: .progressbar,
            traits: nil,
            liveRegion: .polite,
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

// MARK: - Form Field Combinations

extension View {
    /// Configures a form field with label, help text, and validation.
    ///
    /// This is a convenience method that combines multiple accessibility
    /// attributes for a complete form field configuration.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// TextField("", text: $email)
    ///     .accessibilityFormField(
    ///         label: "Email address",
    ///         hint: "We'll never share your email",
    ///         helpTextId: "email-help",
    ///         required: true,
    ///         invalid: !emailValid,
    ///         errorId: emailValid ? nil : "email-error"
    ///     )
    ///
    /// Text("We'll never share your email")
    ///     .accessibilityIdentifier("email-help")
    ///
    /// if !emailValid {
    ///     Text("Please enter a valid email")
    ///         .accessibilityIdentifier("email-error")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - label: The field label
    ///   - hint: Optional hint text
    ///   - helpTextId: ID of help text element
    ///   - required: Whether the field is required
    ///   - invalid: Whether the field is invalid
    ///   - errorId: ID of error message element
    /// - Returns: A view configured as a form field
    @MainActor
    public func accessibilityFormField(
        label: String,
        hint: String? = nil,
        helpTextId: String? = nil,
        required: Bool = false,
        invalid: Bool = false,
        errorId: String? = nil
    ) -> some View {
        let describedBy = [helpTextId, errorId]
            .compactMap { $0 }
            .joined(separator: " ")

        return AccessibilityModifier(
            content: self,
            label: label,
            hint: hint,
            value: nil,
            role: nil,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: describedBy.isEmpty ? nil : describedBy,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: invalid,
            required: required,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }
}
