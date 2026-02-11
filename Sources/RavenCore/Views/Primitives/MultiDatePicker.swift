import Foundation

/// A control for selecting multiple dates.
///
/// `MultiDatePicker` provides a lightweight SwiftUI-compatible API for selecting
/// multiple calendar dates in web environments. It uses a `DatePicker` for choosing
/// a candidate date and an add/remove action to manage the bound selection set.
public struct MultiDatePicker: View, Sendable {
    private let label: String
    private let selection: Binding<Set<DateComponents>>
    private let displayedComponents: DatePickerComponents
    private let bounds: _Bounds

    @State private var workingDate = Date()

    // MARK: - Initializers

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Set<DateComponents>>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .unbounded
    }

    @MainActor public init(
        _ label: String,
        selection: Binding<Set<DateComponents>>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .unbounded
    }

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Set<DateComponents>>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .closed(range)
    }

    @MainActor public init(
        _ label: String,
        selection: Binding<Set<DateComponents>>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .closed(range)
    }

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Set<DateComponents>>,
        in range: PartialRangeFrom<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .from(range.lowerBound)
    }

    @MainActor public init(
        _ label: String,
        selection: Binding<Set<DateComponents>>,
        in range: PartialRangeFrom<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .from(range.lowerBound)
    }

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Set<DateComponents>>,
        in range: PartialRangeThrough<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .through(range.upperBound)
    }

    @MainActor public init(
        _ label: String,
        selection: Binding<Set<DateComponents>>,
        in range: PartialRangeThrough<Date>,
        displayedComponents: DatePickerComponents = .date
    ) {
        self.label = label
        self.selection = selection
        self.displayedComponents = displayedComponents
        self.bounds = .through(range.upperBound)
    }

    // MARK: - Body

    @MainActor public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                buildDatePicker()
                Button(containsWorkingDate ? "Remove Date" : "Add Date") {
                    toggleWorkingDate()
                }
            }

            if sortedSelections.isEmpty {
                Text("\(label): no dates selected")
                    .font(.caption)
                    .foregroundColor(.secondaryLabel)
            } else {
                VStack(spacing: 6) {
                    ForEach(0..<sortedSelections.count, id: \.self) { index in
                        let components = sortedSelections[index]
                        HStack(spacing: 8) {
                            Text(format(components))
                                .font(.caption)
                            Spacer()
                            Button("Remove") {
                                remove(components)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private

    @MainActor @ViewBuilder
    private func buildDatePicker() -> some View {
        switch bounds {
        case .unbounded:
            DatePicker(label, selection: $workingDate, displayedComponents: displayedComponents)
        case .closed(let range):
            DatePicker(label, selection: $workingDate, in: range, displayedComponents: displayedComponents)
        case .from(let start):
            DatePicker(label, selection: $workingDate, in: start..., displayedComponents: displayedComponents)
        case .through(let end):
            DatePicker(label, selection: $workingDate, in: ...end, displayedComponents: displayedComponents)
        }
    }

    @MainActor
    private var containsWorkingDate: Bool {
        selection.wrappedValue.contains(normalizedComponents(from: workingDate))
    }

    @MainActor
    private var sortedSelections: [DateComponents] {
        selection.wrappedValue.sorted { lhs, rhs in
            sortKey(lhs) < sortKey(rhs)
        }
    }

    @MainActor
    private func toggleWorkingDate() {
        let candidate = normalizedComponents(from: workingDate)
        var current = selection.wrappedValue
        if current.contains(candidate) {
            current.remove(candidate)
        } else {
            current.insert(candidate)
        }
        selection.wrappedValue = current
    }

    @MainActor
    private func remove(_ components: DateComponents) {
        var current = selection.wrappedValue
        current.remove(components)
        selection.wrappedValue = current
    }

    @MainActor
    private func normalizedComponents(from date: Date) -> DateComponents {
        let calendar = Calendar(identifier: .gregorian)
        let keys: Set<Calendar.Component> = displayedComponents.contains(.hourAndMinute)
            ? [.year, .month, .day, .hour, .minute]
            : [.year, .month, .day]
        var components = calendar.dateComponents(keys, from: date)
        components.calendar = nil
        components.timeZone = nil
        return components
    }

    @MainActor
    private func sortKey(_ components: DateComponents) -> (Int, Int, Int, Int, Int) {
        (
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }

    @MainActor
    private func format(_ components: DateComponents) -> String {
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        func pad2(_ value: Int) -> String {
            value < 10 ? "0\(value)" : "\(value)"
        }

        if displayedComponents.contains(.hourAndMinute) {
            return "\(year)-\(pad2(month))-\(pad2(day)) \(pad2(hour)):\(pad2(minute))"
        }
        return "\(year)-\(pad2(month))-\(pad2(day))"
    }
}

private enum _Bounds: Sendable {
    case unbounded
    case closed(ClosedRange<Date>)
    case from(Date)
    case through(Date)
}
