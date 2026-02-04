import Foundation

/// A control for selecting dates and times.
///
/// `DatePicker` is a primitive view that renders directly to an HTML `input` element
/// with various date/time types. It provides two-way data binding through a `Binding<Date>`
/// that updates when the user selects a date and reflects external changes to the bound value.
///
/// ## Overview
///
/// Use `DatePicker` to let users select dates, times, or both. The picker automatically
/// adapts to the specified components, displaying only the relevant input controls.
/// The HTML5 date/time input types provide native, accessible date selection UI.
///
/// ## Basic Usage
///
/// Create a date picker with default components (date only):
///
/// ```swift
/// struct EventView: View {
///     @State private var eventDate = Date()
///
///     var body: some View {
///         VStack {
///             Text("Event Date:")
///             DatePicker("Select Date", selection: $eventDate)
///         }
///     }
/// }
/// ```
///
/// ## Date and Time Components
///
/// Specify which components to display using `displayedComponents`:
///
/// ```swift
/// // Date only
/// DatePicker("Date", selection: $date, displayedComponents: .date)
///
/// // Time only
/// DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
///
/// // Date and time
/// DatePicker("DateTime", selection: $dateTime,
///            displayedComponents: [.date, .hourAndMinute])
/// ```
///
/// ## Date Range Constraints
///
/// Limit the selectable date range:
///
/// ```swift
/// let today = Date()
/// let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
///
/// DatePicker("Appointment",
///            selection: $appointmentDate,
///            in: today...nextWeek)
/// ```
///
/// ## Closed and Partial Ranges
///
/// Use various range types for different constraints:
///
/// ```swift
/// // Dates from today onwards
/// DatePicker("Future Date", selection: $date, in: Date()...)
///
/// // Dates up to today
/// DatePicker("Past Date", selection: $date, in: ...Date())
///
/// // Specific date range
/// let start = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
/// let end = Date()
/// DatePicker("Last Year", selection: $date, in: start...end)
/// ```
///
/// ## Common Patterns
///
/// **Birthday selector:**
/// ```swift
/// @State private var birthDate = Date()
///
/// let calendar = Calendar.current
/// let maxDate = calendar.date(byAdding: .year, value: -13, to: Date())!
/// let minDate = calendar.date(byAdding: .year, value: -120, to: Date())!
///
/// DatePicker("Birth Date",
///            selection: $birthDate,
///            in: minDate...maxDate,
///            displayedComponents: .date)
/// ```
///
/// **Time selector:**
/// ```swift
/// @State private var alarmTime = Date()
///
/// DatePicker("Alarm Time",
///            selection: $alarmTime,
///            displayedComponents: .hourAndMinute)
/// ```
///
/// **Appointment scheduler:**
/// ```swift
/// @State private var appointment = Date()
///
/// let now = Date()
/// let businessHours = DateInterval(
///     start: Calendar.current.startOfDay(for: now).addingTimeInterval(9 * 3600),
///     end: Calendar.current.startOfDay(for: now).addingTimeInterval(17 * 3600)
/// )
///
/// DatePicker("Select Time",
///            selection: $appointment,
///            in: businessHours,
///            displayedComponents: [.date, .hourAndMinute])
/// ```
///
/// ## Styling
///
/// Apply modifiers to customize appearance:
///
/// ```swift
/// DatePicker("Date", selection: $date)
///     .datePickerStyle(.automatic) // Platform-appropriate style
///     .accentColor(.blue)
/// ```
///
/// ## Localization
///
/// DatePicker respects the user's locale settings for date format,
/// calendar system, and time zone. The browser's native date picker
/// will display according to the user's preferences.
///
/// ## Accessibility
///
/// DatePicker provides built-in accessibility through the native HTML5
/// input elements, which include:
/// - Keyboard navigation
/// - Screen reader support
/// - Focus management
///
/// ## Best Practices
///
/// - Always provide appropriate date ranges to prevent invalid selections
/// - Use meaningful labels to describe what date/time is being selected
/// - Consider time zones when working with Date values
/// - Test with different locales to ensure proper formatting
/// - Use `.date` for date-only selections and `.hourAndMinute` for time-only
///
/// ## Implementation Notes
///
/// This implementation uses HTML5 input types:
/// - `type="date"` for date selection
/// - `type="time"` for time selection
/// - `type="datetime-local"` for combined date and time
///
/// The native browser controls provide consistent, accessible UI across platforms
/// while respecting user preferences for date/time formatting.
///
/// ## See Also
///
/// - ``DatePickerComponents``
/// - ``TextField``
///
/// Because `DatePicker` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct DatePicker: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label to display for the picker
    private let label: String

    /// Two-way binding to the date value
    private let selection: Binding<Date>

    /// The date range that constrains selectable dates
    private let dateRange: DateRange

    /// Which date/time components to display
    private let displayedComponents: DatePickerComponents

    // MARK: - Initializers

    /// Creates a date picker with a label and date binding.
    ///
    /// - Parameters:
    ///   - label: The label to display for the picker.
    ///   - selection: A binding to the selected date.
    ///   - displayedComponents: The components to display (date, time, or both).
    ///
    /// Example:
    /// ```swift
    /// @State private var selectedDate = Date()
    ///
    /// DatePicker("Choose Date", selection: $selectedDate)
    /// ```
    @MainActor public init(
        _ label: String,
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.dateRange = .unlimited
        self.displayedComponents = displayedComponents
    }

    /// Creates a date picker with a localized label and date binding.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the label.
    ///   - selection: A binding to the selected date.
    ///   - displayedComponents: The components to display.
    ///
    /// Example:
    /// ```swift
    /// @State private var selectedDate = Date()
    ///
    /// DatePicker("date_label", selection: $selectedDate)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.dateRange = .unlimited
        self.displayedComponents = displayedComponents
    }

    /// Creates a date picker with a closed date range constraint.
    ///
    /// - Parameters:
    ///   - label: The label to display for the picker.
    ///   - selection: A binding to the selected date.
    ///   - range: The closed range of valid dates.
    ///   - displayedComponents: The components to display.
    ///
    /// Example:
    /// ```swift
    /// let today = Date()
    /// let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
    ///
    /// DatePicker("Date", selection: $date, in: today...nextWeek)
    /// ```
    @MainActor public init(
        _ label: String,
        selection: Binding<Date>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.dateRange = .closed(range)
        self.displayedComponents = displayedComponents
    }

    /// Creates a date picker with a partial range from a minimum date.
    ///
    /// - Parameters:
    ///   - label: The label to display for the picker.
    ///   - selection: A binding to the selected date.
    ///   - range: The partial range from a minimum date onwards.
    ///   - displayedComponents: The components to display.
    ///
    /// Example:
    /// ```swift
    /// DatePicker("Future Date", selection: $date, in: Date()...)
    /// ```
    @MainActor public init(
        _ label: String,
        selection: Binding<Date>,
        in range: PartialRangeFrom<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.dateRange = .from(range.lowerBound)
        self.displayedComponents = displayedComponents
    }

    /// Creates a date picker with a partial range up to a maximum date.
    ///
    /// - Parameters:
    ///   - label: The label to display for the picker.
    ///   - selection: A binding to the selected date.
    ///   - range: The partial range up to a maximum date.
    ///   - displayedComponents: The components to display.
    ///
    /// Example:
    /// ```swift
    /// DatePicker("Past Date", selection: $date, in: ...Date())
    /// ```
    @MainActor public init(
        _ label: String,
        selection: Binding<Date>,
        in range: PartialRangeThrough<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.dateRange = .through(range.upperBound)
        self.displayedComponents = displayedComponents
    }

    // MARK: - VNode Conversion

    /// Converts this DatePicker to a virtual DOM node.
    ///
    /// The DatePicker is rendered as an `input` element with:
    /// - `type` attribute based on displayed components (date, time, or datetime-local)
    /// - `min` and `max` attributes for date range constraints
    /// - `value` attribute bound to the current date value
    /// - `change` event handler for two-way data binding
    ///
    /// - Returns: A VNode configured as a date/time input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the change event handler
        let handlerID = UUID()

        // Determine input type based on displayed components
        let inputType = inputTypeString()

        // Format the current date value for the input
        let formattedValue = formatDateForInput(selection.wrappedValue)

        // Create properties for the input element
        var props: [String: VProperty] = [
            // Input type
            "type": .attribute(name: "type", value: inputType),

            // Current value (reflects the binding)
            "value": .attribute(name: "value", value: formattedValue),

            // Change event handler for two-way binding
            "onChange": .eventHandler(event: "change", handlerID: handlerID),

            // ARIA label for accessibility
            "aria-label": .attribute(name: "aria-label", value: label),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
        ]

        // Add min/max constraints based on date range
        switch dateRange {
        case .unlimited:
            break
        case .closed(let range):
            props["min"] = .attribute(name: "min", value: formatDateForInput(range.lowerBound))
            props["max"] = .attribute(name: "max", value: formatDateForInput(range.upperBound))
        case .from(let minDate):
            props["min"] = .attribute(name: "min", value: formatDateForInput(minDate))
        case .through(let maxDate):
            props["max"] = .attribute(name: "max", value: formatDateForInput(maxDate))
        }

        return VNode.element(
            "input",
            props: props,
            children: []
        )
    }

    // MARK: - Internal Access

    /// Provides access to the selection binding for the render coordinator.
    @MainActor public var dateBinding: Binding<Date> {
        selection
    }

    // MARK: - Private Helpers

    /// Returns the appropriate HTML input type string.
    @MainActor private func inputTypeString() -> String {
        if displayedComponents.contains(.date) && displayedComponents.contains(.hourAndMinute) {
            return "datetime-local"
        } else if displayedComponents.contains(.hourAndMinute) {
            return "time"
        } else {
            return "date"
        }
    }

    /// Formats a date for the HTML input value attribute.
    @MainActor private func formatDateForInput(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()

        if displayedComponents.contains(.date) && displayedComponents.contains(.hourAndMinute) {
            // datetime-local format: YYYY-MM-DDTHH:mm
            formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withColonSeparatorInTime]
            let formatted = formatter.string(from: date)
            // Remove timezone info for datetime-local
            return formatted.replacingOccurrences(of: "Z", with: "")
        } else if displayedComponents.contains(.hourAndMinute) {
            // time format: HH:mm
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return String(format: "%02d:%02d", hour, minute)
        } else {
            // date format: YYYY-MM-DD
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supporting Types

/// An enumeration representing which components of a date to display in a date picker.
public struct DatePickerComponents: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Display the date (year, month, day)
    public static let date = DatePickerComponents(rawValue: 1 << 0)

    /// Display the time (hour and minute)
    public static let hourAndMinute = DatePickerComponents(rawValue: 1 << 1)
}

/// Internal representation of date range constraints.
private enum DateRange: Sendable {
    case unlimited
    case closed(ClosedRange<Date>)
    case from(Date)
    case through(Date)
}
