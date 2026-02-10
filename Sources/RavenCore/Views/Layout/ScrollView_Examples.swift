import Foundation

// MARK: - ScrollView Usage Examples
//
// This file contains examples of how to use ScrollView in Raven applications.
// These examples demonstrate common patterns and use cases.

#if false // These are examples, not actual code to compile

// MARK: - Basic Vertical Scrolling

struct BasicScrollExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<100) { index in
                    Text("Item \(index)")
                        .padding()
                }
            }
        }
    }
}

// MARK: - Horizontal Scrolling Gallery

struct HorizontalGalleryExample: View {
    let images = ["image1", "image2", "image3", "image4"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(images, id: \.self) { imageName in
                    Image(imageName)
                        .frame(width: 200, height: 150)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

// MARK: - Two-Directional Scrolling

struct TwoWayScrollExample: View {
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            // Large content that scrolls both ways
            VStack(spacing: 0) {
                ForEach(0..<50) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<50) { col in
                            Text("\(row),\(col)")
                                .frame(width: 60, height: 40)
                                .border(Color.gray, width: 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Article Reader

struct ArticleReaderExample: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Article Title")
                    .font(.title)
                    .bold()

                Text("By Author Name")
                    .font(.caption)
                    .foregroundColor(.gray)

                Image("hero-image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                Text("""
                    Long article content goes here. This can be many paragraphs
                    of text that require scrolling to view. The ScrollView
                    automatically handles the overflow.
                    """)
                    .font(.body)
                    .lineSpacing(4)

                // More content...
            }
            .padding()
        }
    }
}

// MARK: - Grid in ScrollView

struct ScrollableGridExample: View {
    let items = Array(0..<100)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 12)
            ], spacing: 12) {
                ForEach(items, id: \.self) { item in
                    CardView(item: item)
                }
            }
            .padding()
        }
    }
}

// MARK: - Hidden Scroll Indicators

struct HiddenIndicatorsExample: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                // Content without visible scrollbars
                // Useful for custom UI designs
            }
        }
    }
}

// MARK: - Nested Scroll Views

struct NestedScrollExample: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Text("Vertical Scroll Container")
                    .font(.headline)

                // Horizontal scroll inside vertical scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(0..<10) { i in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                                .frame(width: 100, height: 100)
                        }
                    }
                }
                .frame(height: 120)

                // More vertical content
                ForEach(0..<20) { i in
                    Text("Vertical Item \(i)")
                        .padding()
                }
            }
        }
    }
}

// MARK: - Scroll View with Fixed Header

struct ScrollWithHeaderExample: View {
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header (doesn't scroll)
            Text("Fixed Header")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))

            // Scrollable content
            ScrollView {
                VStack {
                    ForEach(0..<50) { i in
                        Text("Item \(i)")
                            .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Form in ScrollView

struct ScrollableFormExample: View {
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Contact Form")
                    .font(.title)

                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.headline)
                    TextField("Enter name", text: $name)
                }

                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.headline)
                    TextField("Enter email", text: $email)
                }

                VStack(alignment: .leading) {
                    Text("Message")
                        .font(.headline)
                    TextField("Enter message", text: $message)
                        .frame(height: 100)
                }

                Button("Submit") {
                    // Handle submission
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

// MARK: - Comparison: ScrollView vs List
//
// Use ScrollView when:
// - You need horizontal scrolling
// - You need both horizontal and vertical scrolling
// - You have custom layout requirements
// - You're displaying non-list content (articles, forms, etc.)
//
// Use List when:
// - You're displaying a vertical list of similar items
// - You want built-in list semantics and accessibility
// - You need better performance for very long lists

#endif
