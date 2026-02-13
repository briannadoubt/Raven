import Foundation

/// Result builder for table column declarations.
///
/// SwiftUI exposes a dedicated table column builder instead of reusing `ViewBuilder`.
/// Raven keeps behavior equivalent while matching the API surface for parity.
@resultBuilder
public struct TableColumnBuilder: Sendable {
    @MainActor public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }

    @MainActor public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    @MainActor public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    @MainActor public static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> TupleView<C0, C1> {
        TupleView(c0, c1)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View>(
        _ c0: C0, _ c1: C1, _ c2: C2
    ) -> TupleView<C0, C1, C2> {
        TupleView(c0, c1, c2)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3
    ) -> TupleView<C0, C1, C2, C3> {
        TupleView(c0, c1, c2, c3)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4
    ) -> TupleView<C0, C1, C2, C3, C4> {
        TupleView(c0, c1, c2, c3, c4)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5
    ) -> TupleView<C0, C1, C2, C3, C4, C5> {
        TupleView(c0, c1, c2, c3, c4, c5)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6> {
        TupleView(c0, c1, c2, c3, c4, c5, c6)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
    }

    @MainActor public static func buildEither<First: View, Second: View>(
        first component: First
    ) -> ConditionalContent<First, Second> {
        ConditionalContent(trueContent: component)
    }

    @MainActor public static func buildEither<First: View, Second: View>(
        second component: Second
    ) -> ConditionalContent<First, Second> {
        ConditionalContent(falseContent: component)
    }

    @MainActor public static func buildIf<Content: View>(_ component: Content?) -> OptionalContent<Content> {
        OptionalContent(content: component)
    }

    @MainActor public static func buildOptional<Content: View>(_ component: Content?) -> OptionalContent<Content> {
        OptionalContent(content: component)
    }

    @MainActor public static func buildLimitedAvailability<Content: View>(_ component: Content) -> Content {
        component
    }
}

/// Result builder for table row declarations.
///
/// This mirrors SwiftUI's dedicated row builder entry points and allows table-specific
/// APIs to evolve without coupling row composition to the general `ViewBuilder`.
@resultBuilder
public struct TableRowBuilder: Sendable {
    @MainActor public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }

    @MainActor public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    @MainActor public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    @MainActor public static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> TupleView<C0, C1> {
        TupleView(c0, c1)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View>(
        _ c0: C0, _ c1: C1, _ c2: C2
    ) -> TupleView<C0, C1, C2> {
        TupleView(c0, c1, c2)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3
    ) -> TupleView<C0, C1, C2, C3> {
        TupleView(c0, c1, c2, c3)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4
    ) -> TupleView<C0, C1, C2, C3, C4> {
        TupleView(c0, c1, c2, c3, c4)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5
    ) -> TupleView<C0, C1, C2, C3, C4, C5> {
        TupleView(c0, c1, c2, c3, c4, c5)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6> {
        TupleView(c0, c1, c2, c3, c4, c5, c6)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
    }

    @MainActor public static func buildEither<First: View, Second: View>(
        first component: First
    ) -> ConditionalContent<First, Second> {
        ConditionalContent(trueContent: component)
    }

    @MainActor public static func buildEither<First: View, Second: View>(
        second component: Second
    ) -> ConditionalContent<First, Second> {
        ConditionalContent(falseContent: component)
    }

    @MainActor public static func buildIf<Content: View>(_ component: Content?) -> OptionalContent<Content> {
        OptionalContent(content: component)
    }

    @MainActor public static func buildOptional<Content: View>(_ component: Content?) -> OptionalContent<Content> {
        OptionalContent(content: component)
    }

    @MainActor public static func buildLimitedAvailability<Content: View>(_ component: Content) -> Content {
        component
    }
}
