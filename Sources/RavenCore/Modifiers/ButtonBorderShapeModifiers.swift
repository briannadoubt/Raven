import Foundation

/// A shape that defines the border geometry for bordered buttons.
public struct ButtonBorderShape: Sendable, Hashable {
    private enum Kind: Sendable, Hashable {
        case automatic
        case capsule
        case circle
        case roundedRectangle(radius: Double?)
    }

    private let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

    /// The platform-appropriate default shape.
    public static let automatic = ButtonBorderShape(kind: .automatic)

    /// A pill-like border shape.
    public static let capsule = ButtonBorderShape(kind: .capsule)

    /// A circular border shape.
    public static let circle = ButtonBorderShape(kind: .circle)

    /// A rounded-rectangle border shape using the system default radius.
    public static let roundedRectangle = ButtonBorderShape(kind: .roundedRectangle(radius: nil))

    /// A rounded-rectangle border shape with an explicit radius.
    public static func roundedRectangle(radius: Double) -> ButtonBorderShape {
        ButtonBorderShape(kind: .roundedRectangle(radius: radius))
    }

    var cssBorderRadius: String {
        switch kind {
        case .automatic:
            return "8px"
        case .capsule:
            return "9999px"
        case .circle:
            return "50%"
        case let .roundedRectangle(radius):
            if let radius {
                return "\(radius)px"
            }
            return "8px"
        }
    }
}

private struct ButtonBorderShapeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ButtonBorderShape = .automatic
}

extension EnvironmentValues {
    var buttonBorderShape: ButtonBorderShape {
        get { self[ButtonBorderShapeEnvironmentKey.self] }
        set { self[ButtonBorderShapeEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the border shape used by bordered button styles.
    @MainActor public func buttonBorderShape(_ shape: ButtonBorderShape) -> some View {
        environment(\.buttonBorderShape, shape)
    }
}
