import Foundation

public struct AnyLayoutCache: @unchecked Sendable {
    fileprivate var storage: Any?

    public init() {
        self.storage = nil
    }

    fileprivate init(storage: Any?) {
        self.storage = storage
    }
}

@MainActor
public struct AnyLayout: Layout {
    public typealias Cache = AnyLayoutCache

    private let _makeCache: (LayoutSubviews) -> Any
    private let _updateCache: (inout Any, LayoutSubviews) -> Void
    private let _sizeThatFits: (ProposedViewSize, LayoutSubviews, inout Any) -> CGSize
    private let _placeSubviews: (CGRect, ProposedViewSize, LayoutSubviews, inout Any) -> Void
    private let _explicitHorizontalAlignment: (HorizontalAlignment, CGRect, ProposedViewSize, LayoutSubviews, inout Any) -> Double?
    private let _explicitVerticalAlignment: (VerticalAlignment, CGRect, ProposedViewSize, LayoutSubviews, inout Any) -> Double?
    private let _properties: () -> LayoutProperties

    private let layoutIdentity: String

    public static var layoutProperties: LayoutProperties {
        LayoutProperties()
    }

    public init<L: Layout>(_ layout: L) {
        layoutIdentity = String(describing: L.self)
        _properties = { L.layoutProperties }

        _makeCache = { subviews in
            layout.makeCache(subviews: subviews)
        }

        _updateCache = { anyCache, subviews in
            var typed = (anyCache as? L.Cache) ?? layout.makeCache(subviews: subviews)
            layout.updateCache(&typed, subviews: subviews)
            anyCache = typed
        }

        _sizeThatFits = { proposal, subviews, anyCache in
            var typed = (anyCache as? L.Cache) ?? layout.makeCache(subviews: subviews)
            let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &typed)
            anyCache = typed
            return size
        }

        _placeSubviews = { bounds, proposal, subviews, anyCache in
            var typed = (anyCache as? L.Cache) ?? layout.makeCache(subviews: subviews)
            layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &typed)
            anyCache = typed
        }

        _explicitHorizontalAlignment = { guide, bounds, proposal, subviews, anyCache in
            var typed = (anyCache as? L.Cache) ?? layout.makeCache(subviews: subviews)
            let alignment = layout.explicitAlignment(
                of: guide,
                in: bounds,
                proposal: proposal,
                subviews: subviews,
                cache: &typed
            )
            anyCache = typed
            return alignment
        }

        _explicitVerticalAlignment = { guide, bounds, proposal, subviews, anyCache in
            var typed = (anyCache as? L.Cache) ?? layout.makeCache(subviews: subviews)
            let alignment = layout.explicitAlignment(
                of: guide,
                in: bounds,
                proposal: proposal,
                subviews: subviews,
                cache: &typed
            )
            anyCache = typed
            return alignment
        }
    }

    public func makeCache(subviews: LayoutSubviews) -> AnyLayoutCache {
        AnyLayoutCache(storage: _makeCache(subviews))
    }

    public func updateCache(_ cache: inout AnyLayoutCache, subviews: LayoutSubviews) {
        var underlying = cache.storage as Any
        _updateCache(&underlying, subviews)
        cache.storage = underlying
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayoutCache) -> CGSize {
        var underlying = cache.storage as Any
        let size = _sizeThatFits(proposal, subviews, &underlying)
        cache.storage = underlying
        return size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayoutCache) {
        var underlying = cache.storage as Any
        _placeSubviews(bounds, proposal, subviews, &underlying)
        cache.storage = underlying
    }

    public func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout AnyLayoutCache
    ) -> Double? {
        var underlying = cache.storage as Any
        let alignment = _explicitHorizontalAlignment(guide, bounds, proposal, subviews, &underlying)
        cache.storage = underlying
        return alignment
    }

    public func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout AnyLayoutCache
    ) -> Double? {
        var underlying = cache.storage as Any
        let alignment = _explicitVerticalAlignment(guide, bounds, proposal, subviews, &underlying)
        cache.storage = underlying
        return alignment
    }

    var _identity: String {
        layoutIdentity
    }

    func _computeLayout(
        proposal: ProposedViewSize,
        measuredSubviews: [_MeasuredLayoutSubview],
        cache: inout AnyLayoutCache
    ) -> (size: CGSize, frames: [CGRect]) {
        let subviews = LayoutSubviews._fromMeasured(measuredSubviews)
        if cache.storage == nil {
            cache = makeCache(subviews: subviews)
        } else {
            updateCache(&cache, subviews: subviews)
        }

        let size = sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        let bounds = CGRect(origin: .zero, size: size)
        placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
        return (size, subviews._frames())
    }
}
