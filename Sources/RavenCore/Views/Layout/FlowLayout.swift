import Foundation

@MainActor
public struct FlowLayout: Layout {
    public typealias Cache = Void

    public let itemSpacing: Double?
    public let lineSpacing: Double?

    public init(itemSpacing: Double? = nil, lineSpacing: Double? = nil) {
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
    }

    private var resolvedItemSpacing: Double {
        itemSpacing ?? LayoutDefaults.defaultStackSpacing
    }

    private var resolvedLineSpacing: Double {
        lineSpacing ?? LayoutDefaults.defaultStackSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let maxWidth = proposal.width ?? .infinity

        var lineWidth: Double = 0
        var lineHeight: Double = 0
        var totalHeight: Double = 0
        var maxLineWidth: Double = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let candidate = lineWidth == 0 ? size.width : lineWidth + resolvedItemSpacing + size.width

            if candidate > maxWidth, lineWidth > 0 {
                maxLineWidth = max(maxLineWidth, lineWidth)
                totalHeight += lineHeight + resolvedLineSpacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth = candidate
                lineHeight = max(lineHeight, size.height)
            }
        }

        maxLineWidth = max(maxLineWidth, lineWidth)
        totalHeight += lineHeight

        let width = proposal.width ?? maxLineWidth
        let height = proposal.height ?? totalHeight

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Void) {
        guard !subviews.isEmpty else { return }

        let maxWidth = proposal.width ?? bounds.width
        var y = bounds.minY
        var lineWidth: Double = 0
        var lineHeight: Double = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let candidateWidth = lineWidth == 0 ? size.width : lineWidth + resolvedItemSpacing + size.width
            if candidateWidth > maxWidth, lineWidth > 0 {
                y += lineHeight + resolvedLineSpacing
                lineWidth = 0
                lineHeight = 0
            }
            let x = bounds.minX + (lineWidth == 0 ? 0 : lineWidth + resolvedItemSpacing)

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            lineWidth = lineWidth == 0 ? size.width : lineWidth + resolvedItemSpacing + size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}
