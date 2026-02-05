import Foundation

// MARK: - Helper Protocols for Option Extraction

/// Protocol for traversing tuple views during option extraction.
@MainActor
protocol TupleViewProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

/// Protocol for traversing conditional content during option extraction.
@MainActor
protocol ConditionalContentProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

/// Protocol for traversing optional content during option extraction.
@MainActor
protocol OptionalContentProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

/// Protocol for traversing ForEach views during option extraction.
@MainActor
protocol ForEachViewProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

// MARK: - TupleView Conformance

extension TupleView: TupleViewProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        // Use Mirror to traverse tuple elements
        let mirror = Mirror(reflecting: content)
        for child in mirror.children {
            if let view = child.value as? any View {
                extractFromView(view, into: &options)
            }
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}

// MARK: - ConditionalContent Conformance

extension ConditionalContent: ConditionalContentProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        switch storage {
        case .trueContent(let content):
            extractFromView(content, into: &options)
        case .falseContent(let content):
            extractFromView(content, into: &options)
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}

// MARK: - OptionalContent Conformance

extension OptionalContent: OptionalContentProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let content = content {
            extractFromView(content, into: &options)
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}

// MARK: - ForEachView Conformance

extension ForEachView: ForEachViewProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        for view in views {
            extractFromView(view, into: &options)
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}
