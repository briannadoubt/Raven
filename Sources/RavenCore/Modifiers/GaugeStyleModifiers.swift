import Foundation

// MARK: - Gauge Styles

/// A type that specifies the appearance and interaction behavior of gauges.
public protocol GaugeStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = GaugeStyleConfiguration
}

extension GaugeStyle {
    @MainActor func _makeBodyAny(configuration: Configuration) -> AnyView {
        AnyView(makeBody(configuration: configuration))
    }
}

/// The properties of a gauge for style configuration.
public struct GaugeStyleConfiguration: Sendable {
    public let label: AnyView?
    public let currentValueLabel: AnyView?
    public let minimumValueLabel: AnyView?
    public let maximumValueLabel: AnyView?

    public init(
        label: AnyView?,
        currentValueLabel: AnyView?,
        minimumValueLabel: AnyView?,
        maximumValueLabel: AnyView?
    ) {
        self.label = label
        self.currentValueLabel = currentValueLabel
        self.minimumValueLabel = minimumValueLabel
        self.maximumValueLabel = maximumValueLabel
    }
}

/// A style that chooses the best gauge appearance automatically.
public struct DefaultGaugeStyle: GaugeStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label ?? AnyView(EmptyView())
    }
}

/// A linear gauge style.
public struct LinearCapacityGaugeStyle: GaugeStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label ?? AnyView(EmptyView())
    }
}

/// An accessory circular gauge style.
public struct AccessoryCircularGaugeStyle: GaugeStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label ?? AnyView(EmptyView())
    }
}

/// An accessory circular-capacity gauge style.
public struct AccessoryCircularCapacityGaugeStyle: GaugeStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label ?? AnyView(EmptyView())
    }
}

/// An accessory linear gauge style.
public struct AccessoryLinearGaugeStyle: GaugeStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label ?? AnyView(EmptyView())
    }
}

/// An accessory linear-capacity gauge style.
public struct AccessoryLinearCapacityGaugeStyle: GaugeStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label ?? AnyView(EmptyView())
    }
}

extension GaugeStyle where Self == DefaultGaugeStyle {
    /// The automatic gauge style.
    public static var automatic: DefaultGaugeStyle {
        DefaultGaugeStyle()
    }
}

extension GaugeStyle where Self == AccessoryCircularGaugeStyle {
    /// An accessory circular gauge style.
    public static var accessoryCircular: AccessoryCircularGaugeStyle {
        AccessoryCircularGaugeStyle()
    }
}

extension GaugeStyle where Self == AccessoryCircularCapacityGaugeStyle {
    /// An accessory circular-capacity gauge style.
    public static var accessoryCircularCapacity: AccessoryCircularCapacityGaugeStyle {
        AccessoryCircularCapacityGaugeStyle()
    }
}

extension GaugeStyle where Self == AccessoryLinearGaugeStyle {
    /// An accessory linear gauge style.
    public static var accessoryLinear: AccessoryLinearGaugeStyle {
        AccessoryLinearGaugeStyle()
    }
}

extension GaugeStyle where Self == AccessoryLinearCapacityGaugeStyle {
    /// An accessory linear-capacity gauge style.
    public static var accessoryLinearCapacity: AccessoryLinearCapacityGaugeStyle {
        AccessoryLinearCapacityGaugeStyle()
    }
}

private struct GaugeStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any GaugeStyle = DefaultGaugeStyle()
}

extension EnvironmentValues {
    var gaugeStyle: any GaugeStyle {
        get { self[GaugeStyleEnvironmentKey.self] }
        set { self[GaugeStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for gauges within this view.
    @MainActor public func gaugeStyle(_ style: some GaugeStyle) -> some View {
        environment(\.gaugeStyle, style)
    }
}
