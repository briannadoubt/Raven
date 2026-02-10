import Foundation

/// Built-in symbol library with common symbols and SF Symbol compatibility.
///
/// This module provides a comprehensive set of commonly-used symbols organized
/// by category, along with SF Symbol name mappings for compatibility.
///
/// All symbols are normalized to a unit square (0,0 to 1,1) coordinate system
/// and are defined using SVG path data.
@MainActor
struct BuiltInSymbols {
    /// Registers all built-in symbols in the registry.
    static func registerAll(in registry: SymbolRegistry) {
        // Register all symbol categories
        registerShapes(in: registry)
        registerArrows(in: registry)
        registerCommunication(in: registry)
        registerMedia(in: registry)
        registerActions(in: registry)
        registerStatus(in: registry)
        registerNavigation(in: registry)

        // Register SF Symbol aliases
        registerSFSymbolAliases(in: registry)
    }

    // MARK: - Shapes

    private static func registerShapes(in registry: SymbolRegistry) {
        registry.register([
            // Circle
            Symbol(
                name: "circle",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0 A 0.5 0.5 0 1 1 0.5 1 A 0.5 0.5 0 1 1 0.5 0 Z"
            ),

            // Circle filled
            Symbol(
                name: "circle.fill",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0 A 0.5 0.5 0 1 1 0.5 1 A 0.5 0.5 0 1 1 0.5 0 Z"
            ),

            // Square
            Symbol(
                name: "square",
                category: Symbol.Category.shapes,
                pathData: "M 0.15 0.15 L 0.85 0.15 L 0.85 0.85 L 0.15 0.85 Z"
            ),

            // Square filled
            Symbol(
                name: "square.fill",
                category: Symbol.Category.shapes,
                pathData: "M 0.15 0.15 L 0.85 0.15 L 0.85 0.85 L 0.15 0.85 Z"
            ),

            // Triangle
            Symbol(
                name: "triangle",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.9 0.9 L 0.1 0.9 Z"
            ),

            // Triangle filled
            Symbol(
                name: "triangle.fill",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.9 0.9 L 0.1 0.9 Z"
            ),

            // Star
            Symbol(
                name: "star",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.61 0.4 L 0.95 0.4 L 0.68 0.6 L 0.79 0.9 L 0.5 0.7 L 0.21 0.9 L 0.32 0.6 L 0.05 0.4 L 0.39 0.4 Z"
            ),

            // Star filled
            Symbol(
                name: "star.fill",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.61 0.4 L 0.95 0.4 L 0.68 0.6 L 0.79 0.9 L 0.5 0.7 L 0.21 0.9 L 0.32 0.6 L 0.05 0.4 L 0.39 0.4 Z"
            ),

            // Heart
            Symbol(
                name: "heart",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.9 C 0.5 0.9 0.1 0.6 0.1 0.35 C 0.1 0.15 0.25 0.05 0.35 0.05 C 0.45 0.05 0.5 0.15 0.5 0.15 C 0.5 0.15 0.55 0.05 0.65 0.05 C 0.75 0.05 0.9 0.15 0.9 0.35 C 0.9 0.6 0.5 0.9 0.5 0.9 Z"
            ),

            // Heart filled
            Symbol(
                name: "heart.fill",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.9 C 0.5 0.9 0.1 0.6 0.1 0.35 C 0.1 0.15 0.25 0.05 0.35 0.05 C 0.45 0.05 0.5 0.15 0.5 0.15 C 0.5 0.15 0.55 0.05 0.65 0.05 C 0.75 0.05 0.9 0.15 0.9 0.35 C 0.9 0.6 0.5 0.9 0.5 0.9 Z"
            ),

            // Diamond
            Symbol(
                name: "diamond",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.9 0.5 L 0.5 0.9 L 0.1 0.5 Z"
            ),

            // Diamond filled
            Symbol(
                name: "diamond.fill",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.9 0.5 L 0.5 0.9 L 0.1 0.5 Z"
            ),

            // Pentagon
            Symbol(
                name: "pentagon",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.9 0.4 L 0.75 0.9 L 0.25 0.9 L 0.1 0.4 Z"
            ),

            // Hexagon
            Symbol(
                name: "hexagon",
                category: Symbol.Category.shapes,
                pathData: "M 0.5 0.1 L 0.85 0.3 L 0.85 0.7 L 0.5 0.9 L 0.15 0.7 L 0.15 0.3 Z"
            ),
        ])
    }

    // MARK: - Arrows

    private static func registerArrows(in registry: SymbolRegistry) {
        registry.register([
            // Arrow up
            Symbol(
                name: "arrow.up",
                category: Symbol.Category.arrows,
                pathData: "M 0.5 0.1 L 0.5 0.9 M 0.5 0.1 L 0.3 0.3 M 0.5 0.1 L 0.7 0.3"
            ),

            // Arrow down
            Symbol(
                name: "arrow.down",
                category: Symbol.Category.arrows,
                pathData: "M 0.5 0.1 L 0.5 0.9 M 0.5 0.9 L 0.3 0.7 M 0.5 0.9 L 0.7 0.7"
            ),

            // Arrow left
            Symbol(
                name: "arrow.left",
                category: Symbol.Category.arrows,
                pathData: "M 0.9 0.5 L 0.1 0.5 M 0.1 0.5 L 0.3 0.3 M 0.1 0.5 L 0.3 0.7"
            ),

            // Arrow right
            Symbol(
                name: "arrow.right",
                category: Symbol.Category.arrows,
                pathData: "M 0.1 0.5 L 0.9 0.5 M 0.9 0.5 L 0.7 0.3 M 0.9 0.5 L 0.7 0.7"
            ),

            // Arrow up-left
            Symbol(
                name: "arrow.up.left",
                category: Symbol.Category.arrows,
                pathData: "M 0.8 0.8 L 0.2 0.2 M 0.2 0.2 L 0.5 0.2 M 0.2 0.2 L 0.2 0.5"
            ),

            // Arrow up-right
            Symbol(
                name: "arrow.up.right",
                category: Symbol.Category.arrows,
                pathData: "M 0.2 0.8 L 0.8 0.2 M 0.8 0.2 L 0.5 0.2 M 0.8 0.2 L 0.8 0.5"
            ),

            // Arrow down-left
            Symbol(
                name: "arrow.down.left",
                category: Symbol.Category.arrows,
                pathData: "M 0.8 0.2 L 0.2 0.8 M 0.2 0.8 L 0.5 0.8 M 0.2 0.8 L 0.2 0.5"
            ),

            // Arrow down-right
            Symbol(
                name: "arrow.down.right",
                category: Symbol.Category.arrows,
                pathData: "M 0.2 0.2 L 0.8 0.8 M 0.8 0.8 L 0.5 0.8 M 0.8 0.8 L 0.8 0.5"
            ),

            // Arrow clockwise
            Symbol(
                name: "arrow.clockwise",
                category: Symbol.Category.arrows,
                pathData: "M 0.7 0.3 A 0.3 0.3 0 1 1 0.5 0.8 M 0.7 0.3 L 0.7 0.1 M 0.7 0.3 L 0.9 0.3"
            ),

            // Arrow counterclockwise
            Symbol(
                name: "arrow.counterclockwise",
                category: Symbol.Category.arrows,
                pathData: "M 0.3 0.3 A 0.3 0.3 0 1 0 0.5 0.8 M 0.3 0.3 L 0.3 0.1 M 0.3 0.3 L 0.1 0.3"
            ),

            // Chevron up
            Symbol(
                name: "chevron.up",
                category: Symbol.Category.arrows,
                pathData: "M 0.2 0.6 L 0.5 0.3 L 0.8 0.6"
            ),

            // Chevron down
            Symbol(
                name: "chevron.down",
                category: Symbol.Category.arrows,
                pathData: "M 0.2 0.4 L 0.5 0.7 L 0.8 0.4"
            ),

            // Chevron left
            Symbol(
                name: "chevron.left",
                category: Symbol.Category.arrows,
                pathData: "M 0.6 0.2 L 0.3 0.5 L 0.6 0.8"
            ),

            // Chevron right
            Symbol(
                name: "chevron.right",
                category: Symbol.Category.arrows,
                pathData: "M 0.4 0.2 L 0.7 0.5 L 0.4 0.8"
            ),
        ])
    }

    // MARK: - Communication

    private static func registerCommunication(in registry: SymbolRegistry) {
        registry.register([
            // Envelope
            Symbol(
                name: "envelope",
                category: Symbol.Category.communication,
                pathData: "M 0.1 0.2 L 0.9 0.2 L 0.9 0.8 L 0.1 0.8 Z M 0.1 0.2 L 0.5 0.5 L 0.9 0.2"
            ),

            // Envelope filled
            Symbol(
                name: "envelope.fill",
                category: Symbol.Category.communication,
                pathData: "M 0.1 0.2 L 0.9 0.2 L 0.9 0.8 L 0.1 0.8 Z M 0.1 0.2 L 0.5 0.5 L 0.9 0.2"
            ),

            // Phone
            Symbol(
                name: "phone",
                category: Symbol.Category.communication,
                pathData: "M 0.3 0.15 L 0.4 0.15 C 0.4 0.15 0.5 0.25 0.5 0.35 C 0.5 0.35 0.4 0.4 0.45 0.5 C 0.5 0.6 0.7 0.8 0.8 0.75 C 0.8 0.75 0.85 0.7 0.9 0.75 C 0.9 0.8 0.85 0.85 0.8 0.85 L 0.7 0.85"
            ),

            // Phone filled
            Symbol(
                name: "phone.fill",
                category: Symbol.Category.communication,
                pathData: "M 0.3 0.15 L 0.4 0.15 C 0.4 0.15 0.5 0.25 0.5 0.35 C 0.5 0.35 0.4 0.4 0.45 0.5 C 0.5 0.6 0.7 0.8 0.8 0.75 C 0.8 0.75 0.85 0.7 0.9 0.75 C 0.9 0.8 0.85 0.85 0.8 0.85 L 0.7 0.85"
            ),

            // Message
            Symbol(
                name: "message",
                category: Symbol.Category.communication,
                pathData: "M 0.1 0.2 L 0.9 0.2 L 0.9 0.7 L 0.6 0.7 L 0.5 0.85 L 0.4 0.7 L 0.1 0.7 Z"
            ),

            // Message filled
            Symbol(
                name: "message.fill",
                category: Symbol.Category.communication,
                pathData: "M 0.1 0.2 L 0.9 0.2 L 0.9 0.7 L 0.6 0.7 L 0.5 0.85 L 0.4 0.7 L 0.1 0.7 Z"
            ),

            // Bell
            Symbol(
                name: "bell",
                category: Symbol.Category.communication,
                pathData: "M 0.5 0.15 C 0.5 0.15 0.3 0.2 0.3 0.5 L 0.3 0.65 L 0.2 0.75 L 0.8 0.75 L 0.7 0.65 L 0.7 0.5 C 0.7 0.2 0.5 0.15 0.5 0.15 M 0.4 0.8 C 0.4 0.85 0.45 0.9 0.5 0.9 C 0.55 0.9 0.6 0.85 0.6 0.8"
            ),

            // Bell filled
            Symbol(
                name: "bell.fill",
                category: Symbol.Category.communication,
                pathData: "M 0.5 0.15 C 0.5 0.15 0.3 0.2 0.3 0.5 L 0.3 0.65 L 0.2 0.75 L 0.8 0.75 L 0.7 0.65 L 0.7 0.5 C 0.7 0.2 0.5 0.15 0.5 0.15 M 0.4 0.8 C 0.4 0.85 0.45 0.9 0.5 0.9 C 0.55 0.9 0.6 0.85 0.6 0.8"
            ),
        ])
    }

    // MARK: - Media

    private static func registerMedia(in registry: SymbolRegistry) {
        registry.register([
            // Play
            Symbol(
                name: "play",
                category: Symbol.Category.media,
                pathData: "M 0.3 0.15 L 0.3 0.85 L 0.8 0.5 Z"
            ),

            // Play filled
            Symbol(
                name: "play.fill",
                category: Symbol.Category.media,
                pathData: "M 0.3 0.15 L 0.3 0.85 L 0.8 0.5 Z"
            ),

            // Pause
            Symbol(
                name: "pause",
                category: Symbol.Category.media,
                pathData: "M 0.3 0.2 L 0.3 0.8 M 0.7 0.2 L 0.7 0.8"
            ),

            // Pause filled
            Symbol(
                name: "pause.fill",
                category: Symbol.Category.media,
                pathData: "M 0.25 0.2 L 0.4 0.2 L 0.4 0.8 L 0.25 0.8 Z M 0.6 0.2 L 0.75 0.2 L 0.75 0.8 L 0.6 0.8 Z"
            ),

            // Stop
            Symbol(
                name: "stop",
                category: Symbol.Category.media,
                pathData: "M 0.25 0.25 L 0.75 0.25 L 0.75 0.75 L 0.25 0.75 Z"
            ),

            // Stop filled
            Symbol(
                name: "stop.fill",
                category: Symbol.Category.media,
                pathData: "M 0.25 0.25 L 0.75 0.25 L 0.75 0.75 L 0.25 0.75 Z"
            ),

            // Forward
            Symbol(
                name: "forward",
                category: Symbol.Category.media,
                pathData: "M 0.2 0.2 L 0.2 0.8 L 0.5 0.5 Z M 0.5 0.2 L 0.5 0.8 L 0.8 0.5 Z"
            ),

            // Forward filled
            Symbol(
                name: "forward.fill",
                category: Symbol.Category.media,
                pathData: "M 0.2 0.2 L 0.2 0.8 L 0.5 0.5 Z M 0.5 0.2 L 0.5 0.8 L 0.8 0.5 Z"
            ),

            // Backward
            Symbol(
                name: "backward",
                category: Symbol.Category.media,
                pathData: "M 0.8 0.2 L 0.8 0.8 L 0.5 0.5 Z M 0.5 0.2 L 0.5 0.8 L 0.2 0.5 Z"
            ),

            // Backward filled
            Symbol(
                name: "backward.fill",
                category: Symbol.Category.media,
                pathData: "M 0.8 0.2 L 0.8 0.8 L 0.5 0.5 Z M 0.5 0.2 L 0.5 0.8 L 0.2 0.5 Z"
            ),

            // Speaker
            Symbol(
                name: "speaker",
                category: Symbol.Category.media,
                pathData: "M 0.2 0.35 L 0.35 0.35 L 0.5 0.2 L 0.5 0.8 L 0.35 0.65 L 0.2 0.65 Z M 0.6 0.35 C 0.6 0.35 0.7 0.4 0.7 0.5 C 0.7 0.6 0.6 0.65 0.6 0.65"
            ),

            // Speaker filled
            Symbol(
                name: "speaker.fill",
                category: Symbol.Category.media,
                pathData: "M 0.2 0.35 L 0.35 0.35 L 0.5 0.2 L 0.5 0.8 L 0.35 0.65 L 0.2 0.65 Z M 0.6 0.35 C 0.6 0.35 0.7 0.4 0.7 0.5 C 0.7 0.6 0.6 0.65 0.6 0.65"
            ),

            // Volume up
            Symbol(
                name: "speaker.wave.3",
                category: Symbol.Category.media,
                pathData: "M 0.15 0.35 L 0.3 0.35 L 0.45 0.2 L 0.45 0.8 L 0.3 0.65 L 0.15 0.65 Z M 0.55 0.3 C 0.6 0.35 0.65 0.4 0.65 0.5 C 0.65 0.6 0.6 0.65 0.55 0.7 M 0.65 0.2 C 0.75 0.3 0.8 0.4 0.8 0.5 C 0.8 0.6 0.75 0.7 0.65 0.8"
            ),
        ])
    }

    // MARK: - Actions

    private static func registerActions(in registry: SymbolRegistry) {
        registry.register([
            // Plus
            Symbol(
                name: "plus",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.2 L 0.5 0.8 M 0.2 0.5 L 0.8 0.5"
            ),

            // Plus circle
            Symbol(
                name: "plus.circle",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.5 0.3 L 0.5 0.7 M 0.3 0.5 L 0.7 0.5"
            ),

            // Plus circle filled
            Symbol(
                name: "plus.circle.fill",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.5 0.3 L 0.5 0.7 M 0.3 0.5 L 0.7 0.5"
            ),

            // Minus
            Symbol(
                name: "minus",
                category: Symbol.Category.actions,
                pathData: "M 0.2 0.5 L 0.8 0.5"
            ),

            // Minus circle
            Symbol(
                name: "minus.circle",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.3 0.5 L 0.7 0.5"
            ),

            // Minus circle filled
            Symbol(
                name: "minus.circle.fill",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.3 0.5 L 0.7 0.5"
            ),

            // X mark
            Symbol(
                name: "xmark",
                category: Symbol.Category.actions,
                pathData: "M 0.25 0.25 L 0.75 0.75 M 0.75 0.25 L 0.25 0.75"
            ),

            // X mark circle
            Symbol(
                name: "xmark.circle",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.35 0.35 L 0.65 0.65 M 0.65 0.35 L 0.35 0.65"
            ),

            // X mark circle filled
            Symbol(
                name: "xmark.circle.fill",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.35 0.35 L 0.65 0.65 M 0.65 0.35 L 0.35 0.65"
            ),

            // Checkmark
            Symbol(
                name: "checkmark",
                category: Symbol.Category.actions,
                pathData: "M 0.2 0.5 L 0.4 0.7 L 0.8 0.3"
            ),

            // Checkmark circle
            Symbol(
                name: "checkmark.circle",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.3 0.5 L 0.45 0.65 L 0.7 0.35"
            ),

            // Checkmark circle filled
            Symbol(
                name: "checkmark.circle.fill",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.3 0.5 L 0.45 0.65 L 0.7 0.35"
            ),

            // Trash
            Symbol(
                name: "trash",
                category: Symbol.Category.actions,
                pathData: "M 0.25 0.3 L 0.75 0.3 L 0.7 0.85 L 0.3 0.85 Z M 0.4 0.2 L 0.6 0.2 M 0.2 0.3 L 0.8 0.3 M 0.4 0.4 L 0.4 0.75 M 0.5 0.4 L 0.5 0.75 M 0.6 0.4 L 0.6 0.75"
            ),

            // Trash filled
            Symbol(
                name: "trash.fill",
                category: Symbol.Category.actions,
                pathData: "M 0.25 0.3 L 0.75 0.3 L 0.7 0.85 L 0.3 0.85 Z M 0.4 0.2 L 0.6 0.2 M 0.2 0.3 L 0.8 0.3"
            ),

            // Gear
            Symbol(
                name: "gear",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.35 A 0.15 0.15 0 1 1 0.5 0.65 A 0.15 0.15 0 1 1 0.5 0.35 M 0.5 0.1 L 0.5 0.25 M 0.5 0.75 L 0.5 0.9 M 0.15 0.25 L 0.28 0.35 M 0.72 0.65 L 0.85 0.75 M 0.15 0.75 L 0.28 0.65 M 0.72 0.35 L 0.85 0.25 M 0.1 0.5 L 0.25 0.5 M 0.75 0.5 L 0.9 0.5"
            ),

            // Gear filled
            Symbol(
                name: "gearshape.fill",
                category: Symbol.Category.actions,
                pathData: "M 0.5 0.35 A 0.15 0.15 0 1 1 0.5 0.65 A 0.15 0.15 0 1 1 0.5 0.35 M 0.45 0.1 L 0.55 0.1 L 0.55 0.25 L 0.45 0.25 Z M 0.45 0.75 L 0.55 0.75 L 0.55 0.9 L 0.45 0.9 Z"
            ),
        ])
    }

    // MARK: - Status

    private static func registerStatus(in registry: SymbolRegistry) {
        registry.register([
            // Info
            Symbol(
                name: "info.circle",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.5 0.25 L 0.5 0.3 M 0.5 0.4 L 0.5 0.75"
            ),

            // Info filled
            Symbol(
                name: "info.circle.fill",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.5 0.25 L 0.5 0.3 M 0.5 0.4 L 0.5 0.75"
            ),

            // Warning
            Symbol(
                name: "exclamationmark.triangle",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.15 L 0.9 0.85 L 0.1 0.85 Z M 0.5 0.35 L 0.5 0.6 M 0.5 0.7 L 0.5 0.75"
            ),

            // Warning filled
            Symbol(
                name: "exclamationmark.triangle.fill",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.15 L 0.9 0.85 L 0.1 0.85 Z M 0.5 0.35 L 0.5 0.6 M 0.5 0.7 L 0.5 0.75"
            ),

            // Error (exclamation mark circle)
            Symbol(
                name: "exclamationmark.circle",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.5 0.25 L 0.5 0.55 M 0.5 0.65 L 0.5 0.7"
            ),

            // Error filled
            Symbol(
                name: "exclamationmark.circle.fill",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.5 0.25 L 0.5 0.55 M 0.5 0.65 L 0.5 0.7"
            ),

            // Success (checkmark in shield)
            Symbol(
                name: "checkmark.shield",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.1 L 0.8 0.25 L 0.8 0.5 C 0.8 0.7 0.7 0.85 0.5 0.9 C 0.3 0.85 0.2 0.7 0.2 0.5 L 0.2 0.25 Z M 0.35 0.5 L 0.45 0.6 L 0.65 0.4"
            ),

            // Success filled
            Symbol(
                name: "checkmark.shield.fill",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.1 L 0.8 0.25 L 0.8 0.5 C 0.8 0.7 0.7 0.85 0.5 0.9 C 0.3 0.85 0.2 0.7 0.2 0.5 L 0.2 0.25 Z M 0.35 0.5 L 0.45 0.6 L 0.65 0.4"
            ),

            // Question mark
            Symbol(
                name: "questionmark.circle",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.35 0.35 C 0.35 0.25 0.4 0.2 0.5 0.2 C 0.6 0.2 0.65 0.25 0.65 0.35 C 0.65 0.45 0.6 0.5 0.5 0.55 L 0.5 0.6 M 0.5 0.7 L 0.5 0.75"
            ),

            // Question mark filled
            Symbol(
                name: "questionmark.circle.fill",
                category: Symbol.Category.status,
                pathData: "M 0.5 0.05 A 0.45 0.45 0 1 1 0.5 0.95 A 0.45 0.45 0 1 1 0.5 0.05 M 0.35 0.35 C 0.35 0.25 0.4 0.2 0.5 0.2 C 0.6 0.2 0.65 0.25 0.65 0.35 C 0.65 0.45 0.6 0.5 0.5 0.55 L 0.5 0.6 M 0.5 0.7 L 0.5 0.75"
            ),
        ])
    }

    // MARK: - Navigation

    private static func registerNavigation(in registry: SymbolRegistry) {
        registry.register([
            // House
            Symbol(
                name: "house",
                category: Symbol.Category.navigation,
                pathData: "M 0.5 0.15 L 0.85 0.45 L 0.85 0.85 L 0.15 0.85 L 0.15 0.45 Z M 0.4 0.5 L 0.6 0.5 L 0.6 0.85 L 0.4 0.85 Z"
            ),

            // House filled
            Symbol(
                name: "house.fill",
                category: Symbol.Category.navigation,
                pathData: "M 0.5 0.15 L 0.85 0.45 L 0.85 0.85 L 0.15 0.85 L 0.15 0.45 Z"
            ),

            // Magnifying glass
            Symbol(
                name: "magnifyingglass",
                category: Symbol.Category.navigation,
                pathData: "M 0.4 0.2 A 0.25 0.25 0 1 1 0.4 0.7 A 0.25 0.25 0 1 1 0.4 0.2 M 0.58 0.58 L 0.8 0.8"
            ),

            // Person
            Symbol(
                name: "person",
                category: Symbol.Category.navigation,
                pathData: "M 0.5 0.25 A 0.1 0.1 0 1 1 0.5 0.45 A 0.1 0.1 0 1 1 0.5 0.25 M 0.3 0.55 L 0.3 0.75 L 0.7 0.75 L 0.7 0.55 C 0.7 0.55 0.65 0.5 0.5 0.5 C 0.35 0.5 0.3 0.55 0.3 0.55"
            ),

            // Person filled
            Symbol(
                name: "person.fill",
                category: Symbol.Category.navigation,
                pathData: "M 0.5 0.25 A 0.1 0.1 0 1 1 0.5 0.45 A 0.1 0.1 0 1 1 0.5 0.25 M 0.3 0.55 L 0.3 0.75 L 0.7 0.75 L 0.7 0.55 C 0.7 0.55 0.65 0.5 0.5 0.5 C 0.35 0.5 0.3 0.55 0.3 0.55"
            ),

            // Folder
            Symbol(
                name: "folder",
                category: Symbol.Category.navigation,
                pathData: "M 0.15 0.25 L 0.45 0.25 L 0.5 0.35 L 0.85 0.35 L 0.85 0.75 L 0.15 0.75 Z"
            ),

            // Folder filled
            Symbol(
                name: "folder.fill",
                category: Symbol.Category.navigation,
                pathData: "M 0.15 0.25 L 0.45 0.25 L 0.5 0.35 L 0.85 0.35 L 0.85 0.75 L 0.15 0.75 Z"
            ),

            // Doc
            Symbol(
                name: "doc",
                category: Symbol.Category.navigation,
                pathData: "M 0.25 0.15 L 0.6 0.15 L 0.75 0.3 L 0.75 0.85 L 0.25 0.85 Z M 0.6 0.15 L 0.6 0.3 L 0.75 0.3 M 0.35 0.45 L 0.65 0.45 M 0.35 0.55 L 0.65 0.55 M 0.35 0.65 L 0.55 0.65"
            ),

            // Doc filled
            Symbol(
                name: "doc.fill",
                category: Symbol.Category.navigation,
                pathData: "M 0.25 0.15 L 0.6 0.15 L 0.75 0.3 L 0.75 0.85 L 0.25 0.85 Z M 0.6 0.15 L 0.6 0.3 L 0.75 0.3"
            ),

            // Calendar
            Symbol(
                name: "calendar",
                category: Symbol.Category.navigation,
                pathData: "M 0.15 0.25 L 0.85 0.25 L 0.85 0.85 L 0.15 0.85 Z M 0.15 0.4 L 0.85 0.4 M 0.35 0.2 L 0.35 0.3 M 0.65 0.2 L 0.65 0.3"
            ),
        ])
    }

    // MARK: - SF Symbol Aliases

    private static func registerSFSymbolAliases(in registry: SymbolRegistry) {
        // Map SF Symbol names to our built-in symbols
        registry.registerAliases([
            // Common mappings
            "circle": "circle",
            "circle.fill": "circle.fill",
            "square": "square",
            "square.fill": "square.fill",
            "triangle": "triangle",
            "triangle.fill": "triangle.fill",
            "star": "star",
            "star.fill": "star.fill",
            "heart": "heart",
            "heart.fill": "heart.fill",

            // Arrows
            "arrow.up": "arrow.up",
            "arrow.down": "arrow.down",
            "arrow.left": "arrow.left",
            "arrow.right": "arrow.right",
            "arrow.clockwise": "arrow.clockwise",
            "arrow.counterclockwise": "arrow.counterclockwise",
            "chevron.up": "chevron.up",
            "chevron.down": "chevron.down",
            "chevron.left": "chevron.left",
            "chevron.right": "chevron.right",

            // Communication
            "envelope": "envelope",
            "envelope.fill": "envelope.fill",
            "phone": "phone",
            "phone.fill": "phone.fill",
            "message": "message",
            "message.fill": "message.fill",
            "bell": "bell",
            "bell.fill": "bell.fill",

            // Media
            "play": "play",
            "play.fill": "play.fill",
            "pause": "pause",
            "pause.fill": "pause.fill",
            "stop": "stop",
            "stop.fill": "stop.fill",
            "forward": "forward",
            "forward.fill": "forward.fill",
            "backward": "backward",
            "backward.fill": "backward.fill",

            // Actions
            "plus": "plus",
            "plus.circle": "plus.circle",
            "plus.circle.fill": "plus.circle.fill",
            "minus": "minus",
            "minus.circle": "minus.circle",
            "minus.circle.fill": "minus.circle.fill",
            "xmark": "xmark",
            "xmark.circle": "xmark.circle",
            "xmark.circle.fill": "xmark.circle.fill",
            "checkmark": "checkmark",
            "checkmark.circle": "checkmark.circle",
            "checkmark.circle.fill": "checkmark.circle.fill",
            "trash": "trash",
            "trash.fill": "trash.fill",
            "gear": "gear",
            "gearshape": "gear",
            "gearshape.fill": "gearshape.fill",

            // Status
            "info.circle": "info.circle",
            "info.circle.fill": "info.circle.fill",
            "exclamationmark.triangle": "exclamationmark.triangle",
            "exclamationmark.triangle.fill": "exclamationmark.triangle.fill",
            "exclamationmark.circle": "exclamationmark.circle",
            "exclamationmark.circle.fill": "exclamationmark.circle.fill",
            "checkmark.shield": "checkmark.shield",
            "checkmark.shield.fill": "checkmark.shield.fill",
            "questionmark.circle": "questionmark.circle",
            "questionmark.circle.fill": "questionmark.circle.fill",

            // Navigation
            "house": "house",
            "house.fill": "house.fill",
            "magnifyingglass": "magnifyingglass",
            "person": "person",
            "person.fill": "person.fill",
            "folder": "folder",
            "folder.fill": "folder.fill",
            "doc": "doc",
            "doc.fill": "doc.fill",
            "calendar": "calendar",
        ])
    }
}
