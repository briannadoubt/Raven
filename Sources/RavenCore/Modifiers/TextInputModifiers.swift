import Foundation

/// The keyboard appearance to request for text entry controls.
public struct KeyboardType: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let `default` = KeyboardType("default")
    public static let asciiCapable = KeyboardType("asciiCapable")
    public static let numbersAndPunctuation = KeyboardType("numbersAndPunctuation")
    public static let url = KeyboardType("url")
    public static let numberPad = KeyboardType("numberPad")
    public static let phonePad = KeyboardType("phonePad")
    public static let namePhonePad = KeyboardType("namePhonePad")
    public static let emailAddress = KeyboardType("emailAddress")
    public static let decimalPad = KeyboardType("decimalPad")
    public static let twitter = KeyboardType("twitter")
    public static let webSearch = KeyboardType("webSearch")
    public static let asciiCapableNumberPad = KeyboardType("asciiCapableNumberPad")

    var htmlInputType: String {
        switch rawValue {
        case "emailAddress":
            "email"
        case "url":
            "url"
        case "phonePad", "namePhonePad":
            "tel"
        case "webSearch":
            "search"
        default:
            "text"
        }
    }

    var htmlInputMode: String? {
        switch rawValue {
        case "numberPad", "asciiCapableNumberPad":
            "numeric"
        case "decimalPad":
            "decimal"
        case "phonePad", "namePhonePad":
            "tel"
        case "emailAddress":
            "email"
        case "url":
            "url"
        case "webSearch":
            "search"
        default:
            nil
        }
    }
}

/// The automatic capitalization behavior to apply to text input views.
public struct TextInputAutocapitalization: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Browser/system default capitalization behavior.
    public static let automatic = TextInputAutocapitalization("sentences")

    /// Never capitalize user-entered text.
    public static let never = TextInputAutocapitalization("none")

    /// Capitalize each sentence.
    public static let sentences = TextInputAutocapitalization("sentences")

    /// Capitalize every word.
    public static let words = TextInputAutocapitalization("words")

    /// Capitalize every character.
    public static let characters = TextInputAutocapitalization("characters")
}

extension View {
    /// Configures whether this view hierarchy should disable text autocorrection.
    ///
    /// - Parameter disabled: Pass `true` to disable autocorrection.
    /// - Returns: A view with updated autocorrection behavior.
    @MainActor public func autocorrectionDisabled(_ disabled: Bool = true) -> some View {
        environment(\.autocorrectionDisabled, disabled)
    }

    /// Legacy alias for `autocorrectionDisabled(_:)`.
    @MainActor public func disableAutocorrection(_ disable: Bool = true) -> some View {
        environment(\.disableAutocorrection, disable)
    }

    /// Configures automatic capitalization behavior for text input views.
    @MainActor public func textInputAutocapitalization(
        _ autocapitalization: TextInputAutocapitalization?
    ) -> some View {
        environment(\.textInputAutocapitalization, autocapitalization)
    }

    /// Legacy alias for `textInputAutocapitalization(_:)`.
    @MainActor public func autocapitalization(
        _ autocapitalization: TextInputAutocapitalization
    ) -> some View {
        textInputAutocapitalization(autocapitalization)
    }

    /// Configures the preferred software keyboard for text input views.
    @MainActor public func keyboardType(_ type: KeyboardType) -> some View {
        environment(\.keyboardType, type)
    }
}
