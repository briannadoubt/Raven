import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct RavenPreviewMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PreviewMacro.self,
    ]
}

/// Implements SwiftUI-style `#Preview { ... }`.
///
/// Raven currently treats previews as a compile-time-only feature: the macro expands to
/// no declarations so it has no runtime behavior (and the preview body is not type-checked).
public struct PreviewMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

