import Foundation

private struct _OutlineSendableKeyPath<Root, Value>: @unchecked Sendable {
    let keyPath: KeyPath<Root, Value>

    init(_ keyPath: KeyPath<Root, Value>) {
        self.keyPath = keyPath
    }
}

/// A view that presents hierarchical data using expandable disclosure rows.
///
/// `OutlineGroup` recursively renders tree-shaped data. Nodes with children are
/// wrapped in `DisclosureGroup`; leaf nodes render directly.
public struct OutlineGroup<Data, ID, Content>: View, Sendable
where Data: RandomAccessCollection & Sendable, Data.Element: Sendable, ID: Hashable & Sendable, Content: View {
    private let data: Data
    private let idKeyPath: _OutlineSendableKeyPath<Data.Element, ID>
    private let childrenKeyPath: _OutlineSendableKeyPath<Data.Element, [Data.Element]?>
    private let rowContent: @Sendable @MainActor (Data.Element) -> Content

    @MainActor
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        children: KeyPath<Data.Element, [Data.Element]?>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = _OutlineSendableKeyPath(id)
        self.childrenKeyPath = _OutlineSendableKeyPath(children)
        self.rowContent = content
    }

    @MainActor public var body: some View {
        let items = Array(data)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: idKeyPath.keyPath) { element in
                OutlineGroupNode(
                    element: element,
                    idKeyPath: idKeyPath,
                    childrenKeyPath: childrenKeyPath,
                    rowContent: rowContent
                )
            }
        }
    }
}

private struct OutlineGroupNode<Element, ID, Content>: View, Sendable
where Element: Sendable, ID: Hashable & Sendable, Content: View {
    let element: Element
    let idKeyPath: _OutlineSendableKeyPath<Element, ID>
    let childrenKeyPath: _OutlineSendableKeyPath<Element, [Element]?>
    let rowContent: @Sendable @MainActor (Element) -> Content

    @MainActor var body: some View {
        let children = element[keyPath: childrenKeyPath.keyPath] ?? []

        if children.isEmpty {
            rowContent(element)
        } else {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(children, id: idKeyPath.keyPath) { child in
                        OutlineGroupNode(
                            element: child,
                            idKeyPath: idKeyPath,
                            childrenKeyPath: childrenKeyPath,
                            rowContent: rowContent
                        )
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 0))
            } label: {
                rowContent(element)
            }
        }
    }
}

extension OutlineGroup where ID == Data.Element.ID, Data.Element: Identifiable {
    @MainActor
    public init(
        _ data: Data,
        children: KeyPath<Data.Element, [Data.Element]?>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> Content
    ) {
        self.init(data, id: \.id, children: children, content: content)
    }
}
