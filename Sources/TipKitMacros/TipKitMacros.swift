import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct TipKitMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ParameterMacro.self,
        RuleMacro.self,
    ]
}

/// Implements `@Parameter` attached macro used by TipKit.
///
/// Raven's TipKit shim stores a `TipKit.Tips.Parameter<T>` in a synthesized `$name`
/// peer property and routes reads/writes through that storage.
public struct ParameterMacro: AccessorMacro, PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let ident = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return []
        }

        let name = ident.identifier.text

        return [
            "get { $\(raw: name).wrappedValue }",
            "set { $\(raw: name).wrappedValue = newValue }",
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let ident = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return []
        }

        let name = ident.identifier.text

        // Determine the declared type (best-effort). If no type annotation exists,
        // fall back to `Any`.
        let typeString: String
        if let typeAnno = binding.typeAnnotation?.type {
            typeString = typeAnno.description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            typeString = "Any"
        }

        // Initial value is required for this macro.
        let initialExpr = binding.initializer?.value.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "nil"

        // Forward macro arguments (e.g. `.transient`) into the synthesized Parameter initializer.
        let options: String
        if let arguments = node.arguments {
            // `arguments` includes the surrounding parentheses; strip them.
            let raw = arguments.description.trimmingCharacters(in: .whitespacesAndNewlines)
            options = raw
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            options = ""
        }
        let optionsSuffix = options.isEmpty ? "" : ", \(options)"

        // Copy access level (best-effort).
        let accessPrefix: String = {
            for mod in varDecl.modifiers {
                switch mod.name.tokenKind {
                case .keyword(.public): return "public "
                case .keyword(.package): return "package "
                case .keyword(.internal): return "internal "
                case .keyword(.fileprivate): return "fileprivate "
                case .keyword(.private): return "private "
                case .keyword(.open): return "open "
                default: continue
                }
            }
            return ""
        }()

        let decl: DeclSyntax = DeclSyntax(
            stringLiteral:
                "\(accessPrefix)static let $\(name): TipKit.Tips.Parameter<\(typeString)> = TipKit.Tips.Parameter(Self.self, \"\(name)\", \(initialExpr)\(optionsSuffix))"
        )

        return [decl]
    }
}

/// Implements `#Rule(...) { ... }` freestanding expression macro.
///
/// We lower it to `TipKit.Tips.Rule(...)` which captures the inputs and evaluates
/// the provided predicate closure.
public struct RuleMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let args = node.arguments.map { $0.expression.description.trimmingCharacters(in: .whitespacesAndNewlines) }

        let body: String
        if let trailing = node.trailingClosure {
            body = trailing.description.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let last = args.last, last.hasPrefix("{") {
            body = last
        } else {
            body = "{ true }"
        }

        let nonClosureArgs = node.trailingClosure == nil ? args.dropLast() : args[...]
        let joined = nonClosureArgs.joined(separator: ", ")

        if joined.isEmpty {
            return "TipKit.Tips.Rule(\(raw: body))"
        }
        return "TipKit.Tips.Rule(\(raw: joined), body: \(raw: body))"
    }
}
