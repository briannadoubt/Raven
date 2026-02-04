import Raven

/// Example demonstrating LazyVStack usage in Raven.
///
/// This example shows how to use LazyVStack for efficient vertical layouts
/// with large collections of items.
@MainActor
struct LazyVStackExampleApp: View {
    var body: some View {
        BasicLazyVStackExample()
    }
}

// MARK: - Basic Example

@MainActor
struct BasicLazyVStackExample: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<100) { index in
                    Text("Item \(index)")
                        .padding()
                }
            }
        }
    }
}

// MARK: - With Alignment

@MainActor
struct AlignedLazyVStackExample: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(1...20, id: \.self) { number in
                    HStack {
                        Text("Row \(number)")
                        Spacer()
                        Text("\(number * 10)")
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - With Sections and Pinned Headers

@MainActor
struct SectionedLazyVStackExample: View {
    let sections = [
        ("Fruits", ["Apple", "Banana", "Orange"]),
        ("Vegetables", ["Carrot", "Broccoli", "Spinach"]),
        ("Grains", ["Rice", "Wheat", "Oats"])
    ]

    var body: some View {
        ScrollView {
            LazyVStack(pinnedViews: .sectionHeaders) {
                ForEach(sections, id: \.0) { section in
                    Section(header: Text(section.0).font(.headline)) {
                        ForEach(section.1, id: \.self) { item in
                            Text(item)
                                .padding()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Large Dataset Example

@MainActor
struct LargeDatasetExample: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<10000) { index in
                    HStack {
                        Text("Item \(index)")
                        Spacer()
                        Text("Value: \(index * 2)")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .virtualized(estimatedItemHeight: 40)
        }
    }
}

// MARK: - Complex Layout Example

@MainActor
struct ComplexLazyVStackExample: View {
    @State private var items: [Item] = (0..<100).map { Item(id: $0, title: "Item \($0)") }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                        Text("Description for \(item.title)")
                            .font(.body)
                        HStack {
                            Button("Edit") {
                                // Edit action
                            }
                            Button("Delete") {
                                // Delete action
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    struct Item: Identifiable {
        let id: Int
        let title: String
    }
}

// MARK: - Comparison with VStack

@MainActor
struct ComparisonExample: View {
    var body: some View {
        VStack {
            Text("VStack (Eager)")
                .font(.headline)

            // VStack renders all children immediately
            VStack(spacing: 10) {
                ForEach(0..<10) { index in
                    Text("VStack Item \(index)")
                }
            }

            Divider()

            Text("LazyVStack (Lazy)")
                .font(.headline)

            // LazyVStack creates views on demand
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(0..<10) { index in
                        Text("LazyVStack Item \(index)")
                    }
                }
            }
        }
    }
}
