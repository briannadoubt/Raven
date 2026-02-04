import Foundation

// MARK: - Picker Styles

/// A type that specifies the appearance and behavior of a picker.
///
/// Picker styles define how a picker is rendered in the user interface.
/// Different styles are appropriate for different contexts and platforms.
///
/// ## Overview
///
/// Use the `.pickerStyle()` modifier to apply a style to a picker or to all
/// pickers within a view hierarchy.
///
/// ## Available Styles
///
/// - ``MenuPickerStyle``: Displays options in a dropdown menu (default)
/// - ``SegmentedPickerStyle``: Future support for segmented control appearance
/// - ``WheelPickerStyle``: Future support for wheel/spinner appearance
///
/// ## Example
///
/// ```swift
/// Picker("Size", selection: $selectedSize) {
///     Text("Small").tag("S")
///     Text("Medium").tag("M")
///     Text("Large").tag("L")
/// }
/// .pickerStyle(.menu)
/// ```
public protocol PickerStyle: Sendable {
    /// The type of view representing the body of the picker style.
    associatedtype Body: View

    /// Creates a view representing the styled picker.
    ///
    /// - Parameter configuration: The properties of the picker.
    /// - Returns: A view representing the picker with this style applied.
    @MainActor func makeBody(configuration: Configuration) -> Body

    /// The properties of a picker.
    typealias Configuration = PickerStyleConfiguration
}

/// The properties of a picker.
///
/// This configuration is passed to picker styles to provide the necessary
/// information for rendering the picker.
public struct PickerStyleConfiguration: Sendable {
    /// The label for the picker
    public let label: String

    /// The picker's content view
    public let content: AnyView

    /// Creates a picker style configuration.
    public init(label: String, content: AnyView) {
        self.label = label
        self.content = content
    }
}

// MARK: - Menu Picker Style

/// A picker style that displays options in a dropdown menu.
///
/// This is the default picker style and renders as an HTML `<select>` element.
/// It's appropriate for most use cases where you need to select from a list of options.
///
/// ## Example
///
/// ```swift
/// Picker("Options", selection: $selection) {
///     Text("Option 1").tag(1)
///     Text("Option 2").tag(2)
///     Text("Option 3").tag(3)
/// }
/// .pickerStyle(.menu)
/// ```
///
/// ## Appearance
///
/// The menu picker style displays a dropdown that expands when clicked,
/// showing all available options. It provides a compact interface suitable
/// for forms and settings screens.
///
/// ## Best Practices
///
/// - Use for lists of 3-20 options
/// - Consider segmented style for 2-4 options
/// - For longer lists, consider adding search or filtering
/// - Ensure option labels are concise and descriptive
public struct MenuPickerStyle: PickerStyle {
    /// Creates a menu picker style.
    public init() {}

    /// Creates the default dropdown menu appearance.
    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // The default picker implementation already renders as a menu/select element
        // This style doesn't need to modify the appearance
        configuration.content
    }
}

// MARK: - Segmented Picker Style

/// A picker style that displays options as a segmented control.
///
/// This style presents options as a horizontal row of segments, similar to
/// a tab bar or button group. It's best for a small number of options (2-4).
///
/// ## Example
///
/// ```swift
/// Picker("View Mode", selection: $viewMode) {
///     Text("List").tag(ViewMode.list)
///     Text("Grid").tag(ViewMode.grid)
/// }
/// .pickerStyle(.segmented)
/// ```
///
/// ## Appearance
///
/// Options are displayed as adjacent buttons in a single row, with the
/// selected option highlighted. This provides immediate visual feedback
/// and makes all options visible at once.
///
/// ## Best Practices
///
/// - Use for 2-4 mutually exclusive options
/// - Keep option labels short (ideally 1-2 words)
/// - Consider menu style for more than 4 options
/// - Ideal for view mode toggles, simple settings
///
/// - Note: This style is planned for future implementation and currently
///   falls back to menu style.
public struct SegmentedPickerStyle: PickerStyle {
    /// Creates a segmented picker style.
    public init() {}

    /// Creates the segmented control appearance.
    ///
    /// - Note: Currently falls back to menu style. Full implementation
    ///   will be added in a future update.
    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // TODO: Implement segmented control appearance
        // For now, fall back to menu style
        configuration.content
    }
}

// MARK: - Wheel Picker Style

/// A picker style that displays options in a wheel or spinner interface.
///
/// This style presents options in a rotating wheel interface, similar to
/// iOS date pickers. It's useful for continuous or cyclical data.
///
/// ## Example
///
/// ```swift
/// Picker("Hour", selection: $hour) {
///     ForEach(1...12, id: \.self) { hour in
///         Text("\(hour)").tag(hour)
///     }
/// }
/// .pickerStyle(.wheel)
/// ```
///
/// ## Appearance
///
/// Options are displayed in a vertical wheel that can be scrolled to
/// select a value. The selected value is highlighted in the center.
///
/// ## Best Practices
///
/// - Use for numeric ranges or cyclical data
/// - Consider for time, date, or measurement selection
/// - Not ideal for short lists with distinct values
/// - Good for values that benefit from continuous scrolling
///
/// - Note: This style is planned for future implementation and currently
///   falls back to menu style.
public struct WheelPickerStyle: PickerStyle {
    /// Creates a wheel picker style.
    public init() {}

    /// Creates the wheel picker appearance.
    ///
    /// - Note: Currently falls back to menu style. Full implementation
    ///   will be added in a future update.
    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // TODO: Implement wheel picker appearance
        // For now, fall back to menu style
        configuration.content
    }
}

// MARK: - Inline Picker Style

/// A picker style that displays options inline without a dropdown.
///
/// This style presents all options directly in the view hierarchy,
/// typically as a list of radio buttons or similar controls.
///
/// ## Example
///
/// ```swift
/// Picker("Priority", selection: $priority) {
///     Text("Low").tag(Priority.low)
///     Text("Medium").tag(Priority.medium)
///     Text("High").tag(Priority.high)
/// }
/// .pickerStyle(.inline)
/// ```
///
/// ## Appearance
///
/// All options are displayed at once, making them immediately visible
/// without requiring user interaction to reveal the list.
///
/// ## Best Practices
///
/// - Use when vertical space is available
/// - Good for 3-6 options
/// - Makes all options immediately visible
/// - Consider for forms where seeing all options is important
///
/// - Note: This style is planned for future implementation and currently
///   falls back to menu style.
public struct InlinePickerStyle: PickerStyle {
    /// Creates an inline picker style.
    public init() {}

    /// Creates the inline picker appearance.
    ///
    /// - Note: Currently falls back to menu style. Full implementation
    ///   will be added in a future update.
    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // TODO: Implement inline picker appearance (radio buttons)
        // For now, fall back to menu style
        configuration.content
    }
}

// MARK: - Style Modifier

extension View {
    /// Sets the style for pickers within this view.
    ///
    /// Use this modifier to customize the appearance of pickers in a view hierarchy.
    /// The style applies to all pickers within the modified view.
    ///
    /// Example:
    /// ```swift
    /// Form {
    ///     Picker("Size", selection: $size) {
    ///         Text("Small").tag("S")
    ///         Text("Large").tag("L")
    ///     }
    ///     Picker("Color", selection: $color) {
    ///         Text("Red").tag("red")
    ///         Text("Blue").tag("blue")
    ///     }
    /// }
    /// .pickerStyle(.menu)  // Applies to both pickers
    /// ```
    ///
    /// - Parameter style: The picker style to apply.
    /// - Returns: A view with the specified picker style.
    @MainActor public func pickerStyle<S: PickerStyle>(_ style: S) -> some View {
        // For now, return self as the default picker implementation
        // already renders in the desired style. In the future, this
        // could be implemented using environment values to pass the
        // style down the view hierarchy.
        self
    }
}

// MARK: - Convenience Extensions

extension PickerStyle where Self == MenuPickerStyle {
    /// The default menu picker style.
    ///
    /// Displays options in a dropdown menu.
    public static var menu: MenuPickerStyle {
        MenuPickerStyle()
    }
}

extension PickerStyle where Self == SegmentedPickerStyle {
    /// A segmented picker style.
    ///
    /// Displays options as a segmented control.
    ///
    /// - Note: Currently falls back to menu style.
    public static var segmented: SegmentedPickerStyle {
        SegmentedPickerStyle()
    }
}

extension PickerStyle where Self == WheelPickerStyle {
    /// A wheel picker style.
    ///
    /// Displays options in a wheel interface.
    ///
    /// - Note: Currently falls back to menu style.
    public static var wheel: WheelPickerStyle {
        WheelPickerStyle()
    }
}

extension PickerStyle where Self == InlinePickerStyle {
    /// An inline picker style.
    ///
    /// Displays all options inline without a dropdown.
    ///
    /// - Note: Currently falls back to menu style.
    public static var inline: InlinePickerStyle {
        InlinePickerStyle()
    }
}
