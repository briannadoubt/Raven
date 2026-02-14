import Foundation

@MainActor
public struct HStackLayout: Layout {
    public typealias Cache = Void

    public static var layoutProperties: LayoutProperties {
        LayoutProperties(stackOrientation: .horizontal)
    }

    public let alignment: VerticalAlignment
    public let spacing: Double?

    public init(alignment: VerticalAlignment = .center, spacing: Double? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    private var resolvedSpacing: Double {
        spacing ?? LayoutDefaults.defaultStackSpacing
    }

    private func resolvedSizes(in availableWidth: Double?, subviews: LayoutSubviews) -> [CGSize] {
        var sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        guard let availableWidth else { return sizes }

        let spacingTotal = resolvedSpacing * Double(max(0, sizes.count - 1))
        let naturalWidth = sizes.reduce(0) { $0 + $1.width } + spacingTotal
        let extra = availableWidth - naturalWidth
        guard extra > 0 else { return sizes }

        let weights = subviews.map { subview -> Double in
            let base = max(0, subview.priority)
            if base > 0 { return base }
            return subview.storage.measured.isSpacer ? 1 : 0
        }
        let weightSum = weights.reduce(0, +)
        guard weightSum > 0 else { return sizes }

        for index in sizes.indices {
            let delta = extra * (weights[index] / weightSum)
            sizes[index].width += delta
        }

        return sizes
    }

    private func requiredHeight(for sizes: [CGSize], subviews: LayoutSubviews) -> Double {
        guard !sizes.isEmpty else { return 0 }

        switch alignment {
        case .top, .center, .bottom:
            return sizes.map(\.height).max() ?? 0
        case .firstTextBaseline, .lastTextBaseline:
            var topExtent: Double = 0
            var bottomExtent: Double = 0
            for (index, subview) in subviews.enumerated() {
                let dimensions = subview.dimensions(in: ProposedViewSize(width: sizes[index].width, height: sizes[index].height))
                let baseline = alignment == .firstTextBaseline
                    ? dimensions[.firstTextBaseline]
                    : dimensions[.lastTextBaseline]
                topExtent = max(topExtent, baseline)
                bottomExtent = max(bottomExtent, sizes[index].height - baseline)
            }
            return topExtent + bottomExtent
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) -> CGSize {
        if subviews.isEmpty {
            return .zero
        }

        let sizes = resolvedSizes(in: proposal.width, subviews: subviews)
        let naturalWidth = sizes.reduce(0) { $0 + $1.width } + (resolvedSpacing * Double(max(0, sizes.count - 1)))
        let naturalHeight = requiredHeight(for: sizes, subviews: subviews)

        return CGSize(
            width: proposal.width ?? naturalWidth,
            height: proposal.height ?? naturalHeight
        )
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) {
        let sizes = resolvedSizes(in: bounds.width, subviews: subviews)

        var baselineReference: Double = 0
        if alignment == .firstTextBaseline || alignment == .lastTextBaseline {
            for (index, subview) in subviews.enumerated() {
                let dimensions = subview.dimensions(in: ProposedViewSize(width: sizes[index].width, height: sizes[index].height))
                baselineReference = max(
                    baselineReference,
                    alignment == .firstTextBaseline ? dimensions[.firstTextBaseline] : dimensions[.lastTextBaseline]
                )
            }
        }

        var x = bounds.minX

        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            let dimensions = subview.dimensions(in: ProposedViewSize(width: size.width, height: size.height))

            let y: Double
            switch alignment {
            case .top:
                y = bounds.minY
            case .center:
                y = bounds.minY + ((bounds.height - size.height) / 2)
            case .bottom:
                y = bounds.maxY - size.height
            case .firstTextBaseline:
                y = bounds.minY + (baselineReference - dimensions[.firstTextBaseline])
            case .lastTextBaseline:
                y = bounds.minY + (baselineReference - dimensions[.lastTextBaseline])
            }

            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + resolvedSpacing
        }
    }

    func _containerProps() -> [String: VProperty] {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "row"),
            "align-items": .style(name: "align-items", value: alignment.cssValue),
        ]
        if let spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }
        return props
    }
}

@MainActor
public struct VStackLayout: Layout {
    public typealias Cache = Void

    public static var layoutProperties: LayoutProperties {
        LayoutProperties(stackOrientation: .vertical)
    }

    public let alignment: HorizontalAlignment
    public let spacing: Double?

    public init(alignment: HorizontalAlignment = .center, spacing: Double? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    private var resolvedSpacing: Double {
        spacing ?? LayoutDefaults.defaultStackSpacing
    }

    private func resolvedSizes(in availableHeight: Double?, subviews: LayoutSubviews) -> [CGSize] {
        var sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        guard let availableHeight else { return sizes }

        let spacingTotal = resolvedSpacing * Double(max(0, sizes.count - 1))
        let naturalHeight = sizes.reduce(0) { $0 + $1.height } + spacingTotal
        let extra = availableHeight - naturalHeight
        guard extra > 0 else { return sizes }

        let weights = subviews.map { subview -> Double in
            let base = max(0, subview.priority)
            if base > 0 { return base }
            return subview.storage.measured.isSpacer ? 1 : 0
        }
        let weightSum = weights.reduce(0, +)
        guard weightSum > 0 else { return sizes }

        for index in sizes.indices {
            let delta = extra * (weights[index] / weightSum)
            sizes[index].height += delta
        }

        return sizes
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) -> CGSize {
        if subviews.isEmpty {
            return .zero
        }

        let sizes = resolvedSizes(in: proposal.height, subviews: subviews)
        let width = sizes.map(\.width).max() ?? 0
        let height = sizes.reduce(0) { $0 + $1.height } + (resolvedSpacing * Double(max(0, sizes.count - 1)))

        return CGSize(
            width: proposal.width ?? width,
            height: proposal.height ?? height
        )
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) {
        let sizes = resolvedSizes(in: bounds.height, subviews: subviews)

        var guideReference: Double = 0
        for (index, subview) in subviews.enumerated() {
            let dimensions = subview.dimensions(in: ProposedViewSize(width: sizes[index].width, height: sizes[index].height))
            guideReference = max(guideReference, dimensions[alignment])
        }

        var y = bounds.minY

        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            let dimensions = subview.dimensions(in: ProposedViewSize(width: size.width, height: size.height))
            let x = bounds.minX + (guideReference - dimensions[alignment])

            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: size.width, height: size.height))
            y += size.height + resolvedSpacing
        }
    }

    func _containerProps() -> [String: VProperty] {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "align-items": .style(name: "align-items", value: "stretch"),
        ]
        if let spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }
        return props
    }

    func _childRowJustification() -> String {
        switch alignment {
        case .leading: return "flex-start"
        case .center: return "center"
        case .trailing: return "flex-end"
        }
    }
}

@MainActor
public struct ZStackLayout: Layout {
    public typealias Cache = Void

    public let alignment: Alignment

    public init(alignment: Alignment = .center) {
        self.alignment = alignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = sizes.map(\.width).max() ?? 0
        let height = sizes.map(\.height).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: proposal.height ?? height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) {
        var horizontalReference: Double = 0
        var verticalReference: Double = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let dimensions = subview.dimensions(in: ProposedViewSize(width: size.width, height: size.height))
            horizontalReference = max(horizontalReference, dimensions[alignment.horizontal])
            verticalReference = max(verticalReference, dimensions[alignment.vertical])
        }

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let dimensions = subview.dimensions(in: ProposedViewSize(width: size.width, height: size.height))
            let x = bounds.minX + (horizontalReference - dimensions[alignment.horizontal])
            let y = bounds.minY + (verticalReference - dimensions[alignment.vertical])
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: size.width, height: size.height))
        }
    }

    func _containerProps() -> [String: VProperty] {
        [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue),
        ]
    }
}
