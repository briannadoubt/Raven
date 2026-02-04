import Foundation

/// Enhanced error reporter that provides context-rich error messages with suggestions
@available(macOS 13.0, *)
public struct EnhancedErrorReporter: Sendable {

    // MARK: - Error Enhancement

    /// Enhances a raw compiler error with better context and suggestions
    /// - Parameter error: The raw compilation error message
    /// - Returns: An enhanced error message with context and suggestions
    public func enhanceError(_ error: CompilationErrorMessage) -> EnhancedError {
        let suggestions = generateSuggestions(for: error)
        let contextLines = extractContextLines(for: error)
        let commonMistake = detectCommonMistake(in: error)

        return EnhancedError(
            original: error,
            suggestions: suggestions,
            contextLines: contextLines,
            commonMistake: commonMistake
        )
    }

    /// Formats an enhanced error for display
    /// - Parameter error: The enhanced error to format
    /// - Returns: A formatted error message string
    public func formatError(_ error: EnhancedError) -> String {
        var output = ""

        // Header with file location
        output += "\n"
        output += "╭─ Error ──────────────────────────────────────────────────────\n"
        output += "│\n"
        output += "│ \(error.original.severity.emoji) \(error.original.severity.displayName): \(error.original.message)\n"
        output += "│\n"
        output += "│ 📁 File: \(error.original.file)\n"
        output += "│ 📍 Location: Line \(error.original.line), Column \(error.original.column)\n"

        // Context lines if available
        if !error.contextLines.isEmpty {
            output += "│\n"
            output += "│ Context:\n"
            output += "│\n"
            for contextLine in error.contextLines {
                let prefix = contextLine.isError ? "│ ➤ " : "│   "
                output += "\(prefix)\(contextLine.lineNumber): \(contextLine.content)\n"

                if contextLine.isError && error.original.column > 0 {
                    let spaces = String(repeating: " ", count: error.original.column - 1)
                    output += "│   \(spaces)^\n"
                }
            }
        }

        // Common mistake detection
        if let mistake = error.commonMistake {
            output += "│\n"
            output += "│ 💡 Common Mistake: \(mistake.description)\n"
            output += "│    This error often occurs when \(mistake.explanation)\n"
        }

        // Suggestions
        if !error.suggestions.isEmpty {
            output += "│\n"
            output += "│ 💬 Suggestions:\n"
            for (index, suggestion) in error.suggestions.enumerated() {
                output += "│    \(index + 1). \(suggestion)\n"
            }
        }

        output += "│\n"
        output += "╰──────────────────────────────────────────────────────────────\n"

        return output
    }

    // MARK: - Suggestion Generation

    private func generateSuggestions(for error: CompilationErrorMessage) -> [String] {
        var suggestions: [String] = []
        let message = error.message.lowercased()

        // Type mismatch suggestions
        if message.contains("cannot convert") || message.contains("type mismatch") {
            suggestions.append("Check that the types match exactly")
            suggestions.append("Consider using type casting or conversion methods")

            if message.contains("view") {
                suggestions.append("Ensure your View's body returns a valid View type")
                suggestions.append("Try wrapping complex View hierarchies in AnyView or @ViewBuilder")
            }
        }

        // Missing import suggestions
        if message.contains("cannot find type") || message.contains("use of undeclared type") {
            suggestions.append("Check that you've imported the necessary module (e.g., 'import Raven')")
            suggestions.append("Verify the type name is spelled correctly")
        }

        // Property wrapper suggestions
        if message.contains("@state") || message.contains("@binding") || message.contains("state") {
            suggestions.append("Ensure property wrappers are used correctly (@State, @Binding, @StateObject)")
            suggestions.append("Check that @State properties are initialized or marked as optional")
        }

        // View protocol suggestions
        if message.contains("does not conform to protocol") && message.contains("view") {
            suggestions.append("Add a 'body' property that returns 'some View'")
            suggestions.append("Ensure all required protocol methods are implemented")
        }

        // Async/await suggestions
        if message.contains("async") || message.contains("await") {
            suggestions.append("Use 'await' when calling async functions")
            suggestions.append("Ensure your function is marked as 'async' if it uses 'await'")
            suggestions.append("Consider wrapping async code in Task { } if in a sync context")
        }

        // Sendable suggestions
        if message.contains("sendable") || message.contains("concurrency") {
            suggestions.append("Ensure types used across concurrency boundaries conform to Sendable")
            suggestions.append("Consider using @MainActor for UI-related code")
        }

        // Closure suggestions
        if message.contains("closure") || message.contains("trailing closure") {
            suggestions.append("Check closure parameter types match expectations")
            suggestions.append("Try using explicit parameter types in the closure")
        }

        // ViewBuilder suggestions
        if message.contains("result builder") || message.contains("viewbuilder") {
            suggestions.append("Ensure you're using @ViewBuilder for functions that return multiple views")
            suggestions.append("Remember that ViewBuilder doesn't support all Swift features (loops, complex conditionals)")
        }

        return suggestions
    }

    // MARK: - Common Mistake Detection

    private func detectCommonMistake(in error: CompilationErrorMessage) -> CommonMistake? {
        let message = error.message.lowercased()

        if message.contains("cannot convert") && message.contains("view") {
            return CommonMistake(
                type: .typeMismatch,
                description: "View type mismatch",
                explanation: "trying to use a type that doesn't conform to View where a View is expected"
            )
        }

        if message.contains("@state") && (message.contains("cannot find") || message.contains("use of undeclared")) {
            return CommonMistake(
                type: .propertyWrapper,
                description: "Incorrect property wrapper usage",
                explanation: "@State is being used incorrectly or on an unsupported type"
            )
        }

        if message.contains("cannot find") && message.contains("in scope") {
            return CommonMistake(
                type: .missingImport,
                description: "Missing import statement",
                explanation: "the type or function is not imported or doesn't exist"
            )
        }

        if message.contains("reference to member") && message.contains("cannot be resolved") {
            return CommonMistake(
                type: .ambiguousReference,
                description: "Ambiguous or missing member reference",
                explanation: "the compiler can't determine which member you're referring to"
            )
        }

        if message.contains("async") && message.contains("context") {
            return CommonMistake(
                type: .asyncContext,
                description: "Async/await context mismatch",
                explanation: "you're trying to use await in a non-async context or vice versa"
            )
        }

        return nil
    }

    // MARK: - Context Extraction

    private func extractContextLines(for error: CompilationErrorMessage) -> [ContextLine] {
        guard FileManager.default.fileExists(atPath: error.file) else {
            return []
        }

        guard let content = try? String(contentsOfFile: error.file, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines)
        let errorLine = error.line - 1 // Convert to 0-based

        guard errorLine >= 0 && errorLine < lines.count else {
            return []
        }

        var contextLines: [ContextLine] = []

        // Show 2 lines before and after the error
        let startLine = max(0, errorLine - 2)
        let endLine = min(lines.count - 1, errorLine + 2)

        for i in startLine...endLine {
            contextLines.append(ContextLine(
                lineNumber: i + 1,
                content: lines[i],
                isError: i == errorLine
            ))
        }

        return contextLines
    }
}

// MARK: - Supporting Types

/// An enhanced error with additional context and suggestions
public struct EnhancedError: Sendable {
    public let original: CompilationErrorMessage
    public let suggestions: [String]
    public let contextLines: [ContextLine]
    public let commonMistake: CommonMistake?
}

/// A line of source code with context
public struct ContextLine: Sendable {
    public let lineNumber: Int
    public let content: String
    public let isError: Bool
}

/// Represents a common programming mistake
public struct CommonMistake: Sendable {
    public enum MistakeType: Sendable {
        case typeMismatch
        case propertyWrapper
        case missingImport
        case ambiguousReference
        case asyncContext
    }

    public let type: MistakeType
    public let description: String
    public let explanation: String
}

// MARK: - Extensions

extension CompilationErrorMessage.Severity {
    var emoji: String {
        switch self {
        case .error: return "🔴"
        case .warning: return "🟡"
        case .note: return "ℹ️"
        }
    }

    var displayName: String {
        switch self {
        case .error: return "Error"
        case .warning: return "Warning"
        case .note: return "Note"
        }
    }
}
