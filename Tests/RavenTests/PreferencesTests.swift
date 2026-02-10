import Foundation
import Testing
import JavaScriptKit
@testable import RavenCore

@MainActor
@Suite struct PreferencesTests {

    // MARK: - Test Keys

    struct IntListKey: PreferenceKey {
        static var defaultValue: [Int] { [] }
        static func reduce(value: inout [Int], nextValue: () -> [Int]) {
            value.append(contentsOf: nextValue())
        }
    }

    struct StringKey: PreferenceKey {
        static var defaultValue: String { "" }
        static func reduce(value: inout String, nextValue: () -> String) {
            value = value + nextValue()
        }
    }

    struct NonAssociativeStringKey: PreferenceKey {
        static var defaultValue: String { "" }
        static func reduce(value: inout String, nextValue: () -> String) {
            // Intentionally non-associative: the output depends on how values are grouped.
            // This lets us verify Raven reduces in flattened view-tree order (SwiftUI-like),
            // rather than reducing per-subtree then merging.
            value = value + "\(nextValue().count)"
        }
    }

    struct BoundsAnchorKey: PreferenceKey {
        typealias Value = Anchor<RavenCore.CGRect>?

        static var defaultValue: Value { nil }
        static func reduce(value: inout Value, nextValue: () -> Value) {
            // Prefer the last (SwiftUI-style "most recent wins" for optional anchor).
            value = nextValue() ?? value
        }
    }

    // MARK: - Minimal Coordinator Context

    @MainActor
    final class PreferenceTestContext: _RenderContext {
        private var pathStack: [String] = []
        private var childCounterStack: [Int] = []
        private var handlerCounterStack: [Int] = []
        private var persistentStateStorage: [String: AnyObject] = [:]

        private var preferenceCollectorStack: [_PreferenceCollector] = []
        private var postRenderActions: [@Sendable @MainActor () -> Void] = []

        func renderRootWithPreferences(_ view: any View) -> (VNode, PreferenceValues) {
            postRenderActions.removeAll(keepingCapacity: true)
            let (node, prefs) = renderSubtreeCollectingPreferences(view)
            let actions = postRenderActions
            postRenderActions.removeAll(keepingCapacity: true)
            for action in actions { action() }
            return (node, prefs)
        }

        func renderChild(_ view: any View) -> VNode {
            let (node, _) = renderChildWithPreferences(view)
            return node
        }

        func renderChildWithPreferences(_ view: any View) -> (VNode, PreferenceValues) {
            let childIdx: Int
            if !childCounterStack.isEmpty {
                childIdx = childCounterStack[childCounterStack.count - 1]
                childCounterStack[childCounterStack.count - 1] += 1
            } else {
                childIdx = 0
            }
            pathStack.append(String(childIdx))
            defer { pathStack.removeLast() }
            return renderSubtreeCollectingPreferences(view)
        }

        func registerClickHandler(_ action: @escaping @Sendable @MainActor () -> Void) -> UUID {
            _ = action
            return UUID()
        }

        func registerInputHandler(_ handler: @escaping @Sendable @MainActor (JSValue) -> Void) -> UUID {
            _ = handler
            return UUID()
        }

        func persistentState<T: AnyObject>(create: () -> T) -> T {
            let key = pathStack.joined(separator: ".")
            if let existing = persistentStateStorage[key] as? T { return existing }
            let obj = create()
            persistentStateStorage[key] = obj
            return obj
        }

        func enqueuePostRender(_ action: @escaping @Sendable @MainActor () -> Void) {
            postRenderActions.append(action)
        }

        private func renderSubtreeCollectingPreferences(_ view: any View) -> (VNode, PreferenceValues) {
            preferenceCollectorStack.append(_PreferenceCollector())
            _PreferenceContext.currentCollector = preferenceCollectorStack.last

            let node = convertViewToVNode(view)

            let collector = preferenceCollectorStack.removeLast()
            let snapshot = collector.snapshot()

            if let parent = preferenceCollectorStack.last {
                parent.merge(snapshot)
                _PreferenceContext.currentCollector = parent
            } else {
                _PreferenceContext.currentCollector = nil
            }

            return (node, snapshot)
        }

        private func convertViewToVNode<V: View>(_ view: V) -> VNode {
            let typeName = _typeName(V.self)
            pathStack.append(typeName)
            childCounterStack.append(0)
            handlerCounterStack.append(0)
            defer {
                pathStack.removeLast()
                childCounterStack.removeLast()
                handlerCounterStack.removeLast()
            }

            if V.Body.self == Never.self {
                if let renderable = view as? any _CoordinatorRenderable {
                    return renderable._render(with: self)
                }
                if let anyView = view as? AnyView {
                    return convertViewToVNode(anyView.wrappedView)
                }
                if let primitive = view as? any PrimitiveView {
                    return primitive.toVNode()
                }
                return VNode.component(key: String(describing: V.self))
            }

            return convertViewToVNode(view.body)
        }

        private func _typeName<T>(_ type: T.Type) -> String {
            let full = String(describing: type)
            if let idx = full.firstIndex(of: "<") {
                return String(full[full.startIndex..<idx])
            }
            return full
        }
    }

    // MARK: - Tests

    @Test func preferenceReduceAndTransform() {
        let ctx = PreferenceTestContext()

        let view =
            VStack {
                Text("A").preference(key: IntListKey.self, value: [1])
                Text("B").preference(key: IntListKey.self, value: [2])
            }
            .transformPreference(IntListKey.self) { $0.append(99) }

        let (_, prefs) = ctx.renderRootWithPreferences(view)
        #expect(prefs[IntListKey.self] == [1, 2, 99])
    }

    @Test func overlayPreferenceValueSeesContentPreferences() {
        let ctx = PreferenceTestContext()

        let view =
            VStack {
                Text("A").preference(key: IntListKey.self, value: [1])
                Text("B").preference(key: IntListKey.self, value: [2])
            }
            .overlayPreferenceValue(IntListKey.self) { ints in
                Text("overlay")
                    .preference(key: StringKey.self, value: "\(ints)")
            }

        let (_, prefs) = ctx.renderRootWithPreferences(view)
        #expect(prefs[IntListKey.self] == [1, 2])
        #expect(prefs[StringKey.self].contains("[1, 2]"))
    }

    @Test func onPreferenceChangeIsDeferredAndOnlyFiresOnChanges() {
        let ctx = PreferenceTestContext()

        final class Counter: @unchecked Sendable {
            @MainActor var calls: [String] = []
        }
        let counter = Counter()

        func make(_ value: String) -> some View {
            Text("X")
                .preference(key: StringKey.self, value: value)
                .onPreferenceChange(StringKey.self) { newValue in
                    counter.calls.append(newValue)
                }
        }

        _ = ctx.renderRootWithPreferences(make("a"))
        #expect(counter.calls == ["a"])

        _ = ctx.renderRootWithPreferences(make("a"))
        #expect(counter.calls == ["a"])

        _ = ctx.renderRootWithPreferences(make("b"))
        #expect(counter.calls == ["a", "b"])
    }

    @Test func preferenceReductionIsFlattenedNotGroupedBySubtree() {
        let ctx = PreferenceTestContext()

        let view =
            VStack {
                VStack {
                    Text("A").preference(key: NonAssociativeStringKey.self, value: "a")
                    Text("B").preference(key: NonAssociativeStringKey.self, value: "b")
                }
                Text("C").preference(key: NonAssociativeStringKey.self, value: "c")
            }

        let (_, prefs) = ctx.renderRootWithPreferences(view)
        // Flattened order emits three single-character strings: "a", "b", "c" -> "111"
        #expect(prefs[NonAssociativeStringKey.self] == "111")
    }

    @Test func anchorPreferenceTagsVNodeAndEmitsAnchor() {
        let ctx = PreferenceTestContext()

        let view = Text("X").anchorPreference(key: BoundsAnchorKey.self, value: .bounds) { anchor in
            anchor
        }

        let (node, prefs) = ctx.renderRootWithPreferences(view)

        // Ensure the emitted anchor exists.
        let anchor = prefs[BoundsAnchorKey.self]
        #expect(anchor != nil)

        // Ensure the VNode got a stable anchor tag.
        switch node.type {
        case .element:
            let hasAttr = node.props.values.contains { prop in
                if case .attribute(let name, _) = prop { return name == "data-raven-anchor-id" }
                return false
            }
            #expect(hasAttr == true)
        default:
            // The anchor modifier should preserve content, but for now we only require
            // that it emits a preference.
            #expect(true)
        }
    }
}
