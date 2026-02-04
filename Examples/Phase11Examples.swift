import Raven

// MARK: - Phase 11 Examples: Responsive Design & Search

/// This file demonstrates real-world usage of Phase 11 features:
/// - containerRelativeFrame() for responsive sizing without GeometryReader
/// - ViewThatFits for adaptive layouts that respond to available space
/// - Scroll behavior modifiers (.scrollBounceBehavior, .scrollClipDisabled)
/// - scrollTransition() for scroll-driven animations
/// - searchable() for search functionality

// MARK: - Example 1: Responsive Photo Grid

/// A photo grid that adapts from 4 columns on desktop to 2 on mobile
struct ResponsivePhotoGrid: View {
    @State private var searchText = ""

    let photos = [
        "photo1", "photo2", "photo3", "photo4",
        "photo5", "photo6", "photo7", "photo8"
    ]

    var filteredPhotos: [String] {
        guard !searchText.isEmpty else { return photos }
        return photos.filter { $0.contains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Photo Gallery")
                .font(.title)
                .padding()

            // Responsive grid using containerRelativeFrame
            ViewThatFits(in: .horizontal) {
                // Desktop: 4 columns
                VStack(spacing: 10) {
                    ForEach(0..<2) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<4) { col in
                                let index = row * 4 + col
                                if index < filteredPhotos.count {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: [.blue, .purple],
                                            angle: Angle(degrees: 45)
                                        ))
                                        .containerRelativeFrame(
                                            .horizontal,
                                            count: 4,
                                            spacing: 10
                                        )
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .scrollTransition { content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1 : 0.6)
                                                .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                        }
                                }
                            }
                        }
                    }
                }

                // Tablet: 3 columns
                VStack(spacing: 10) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<3) { col in
                                let index = row * 3 + col
                                if index < filteredPhotos.count {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: [.blue, .purple],
                                            angle: Angle(degrees: 45)
                                        ))
                                        .containerRelativeFrame(
                                            .horizontal,
                                            count: 3,
                                            spacing: 10
                                        )
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }

                // Mobile: 2 columns
                VStack(spacing: 8) {
                    ForEach(0..<4) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<2) { col in
                                let index = row * 2 + col
                                if index < filteredPhotos.count {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: [.blue, .purple],
                                            angle: Angle(degrees: 45)
                                        ))
                                        .containerRelativeFrame(
                                            .horizontal,
                                            count: 2,
                                            spacing: 8
                                        )
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer,
            prompt: Text("Search photos")
        )
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Example 2: Adaptive Navigation Bar

/// A navigation bar that collapses from full menu to hamburger based on space
struct AdaptiveNavigationBar: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Wide screen: Full navigation
            HStack(spacing: 30) {
                Text("🏠 MyApp")
                    .font(.headline)

                Spacer()

                HStack(spacing: 20) {
                    Text("Home")
                        .onTapGesture { }
                    Text("Products")
                        .onTapGesture { }
                    Text("Services")
                        .onTapGesture { }
                    Text("About")
                        .onTapGesture { }
                    Text("Contact")
                        .onTapGesture { }
                }

                HStack(spacing: 12) {
                    Text("Sign In")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { }

                    Text("Sign Up")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { }
                }
            }
            .padding()

            // Medium screen: Compact navigation
            HStack {
                Text("🏠 MyApp")
                    .font(.headline)

                Spacer()

                HStack(spacing: 16) {
                    Text("Home")
                    Text("Products")
                    Text("More ▾")
                }

                Text("Account")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()

            // Narrow screen: Menu button only
            HStack {
                Text("☰")
                    .font(.title2)
                    .onTapGesture { }

                Text("🏠 MyApp")
                    .font(.headline)

                Spacer()

                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("U")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
            .padding()
        }
        .background(Color.white)
        .shadow(radius: 2)
    }
}

// MARK: - Example 3: Scrollable Card List with Transitions

/// Cards that fade and scale in as they scroll into view
struct ScrollableCardList: View {
    let items = Array(1...10)

    var body: some View {
        VStack(spacing: 20) {
            Text("Featured Items")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        // Image placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                angle: Angle(degrees: 135)
                            ))
                            .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Item \(item)")
                                .font(.headline)
                            Text("Description of item \(item) with some details")
                                .font(.body)
                                .foregroundColor(.gray)
                            Text("$\(item * 10).99")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0)
                            .scaleEffect(phase.isIdentity ? 1 : 0.85)
                            .blur(radius: phase.isIdentity ? 0 : 3)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled() // Allow shadows to extend
    }
}

// MARK: - Example 4: Search Results Page

/// A searchable list with real-time filtering and scroll animations
struct SearchResultsPage: View {
    @State private var searchText = ""

    let products = [
        "MacBook Pro", "MacBook Air", "iPad Pro", "iPad Air",
        "iPhone 15 Pro", "iPhone 15", "AirPods Pro", "AirPods",
        "Apple Watch Ultra", "Apple Watch", "Mac Studio", "Mac Mini"
    ]

    var searchResults: [String] {
        guard !searchText.isEmpty else { return products }
        return products.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Results header
            if !searchText.isEmpty {
                HStack {
                    Text("\(searchResults.count) results for '\(searchText)'")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            }

            // Results using ViewThatFits for responsive layout
            ViewThatFits {
                // Desktop: 3-column grid
                VStack(spacing: 16) {
                    ForEach(0..<(searchResults.count + 2) / 3, id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(0..<3) { col in
                                let index = row * 3 + col
                                if index < searchResults.count {
                                    ProductCard(name: searchResults[index])
                                        .containerRelativeFrame(
                                            .horizontal,
                                            count: 3,
                                            spacing: 16
                                        )
                                        .scrollTransition { content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1 : 0.3)
                                                .offset(y: phase == .topLeading ? 20 : 0)
                                        }
                                }
                            }
                        }
                    }
                }

                // Mobile: Single column
                VStack(spacing: 12) {
                    ForEach(searchResults, id: \.self) { product in
                        ProductCard(name: product)
                            .containerRelativeFrame(.horizontal) { width, _ in
                                width * 0.95
                            }
                            .scrollTransition { content, phase in
                                content.opacity(phase.isIdentity ? 1 : 0.5)
                            }
                    }
                }
            }
            .padding()
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer,
            prompt: Text("Search products")
        )
    }
}

struct ProductCard: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1.5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(name)
                .font(.headline)
                .lineLimit(1)

            Text("Starting at $999")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

// MARK: - Example 5: Responsive Dashboard

/// A complete dashboard that adapts layout based on screen size
struct ResponsiveDashboard: View {
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Dashboard content
            ViewThatFits {
                // Desktop: Side-by-side panels
                HStack(spacing: 20) {
                    // Left panel: Stats
                    VStack(spacing: 16) {
                        StatsCard(title: "Revenue", value: "$12,345", trend: "+12%")
                        StatsCard(title: "Users", value: "1,234", trend: "+5%")
                        StatsCard(title: "Orders", value: "567", trend: "+8%")
                    }
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 20)

                    // Right panel: Chart
                    VStack {
                        Text("Analytics")
                            .font(.headline)

                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                angle: Angle(degrees: 45)
                            ))
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 20)
                }
                .padding()

                // Mobile: Stacked panels
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatsCard(title: "Revenue", value: "$12,345", trend: "+12%")
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 12)
                        StatsCard(title: "Users", value: "1,234", trend: "+5%")
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 12)
                    }

                    StatsCard(title: "Orders", value: "567", trend: "+8%")
                        .containerRelativeFrame(.horizontal) { width, _ in width * 0.95 }

                    VStack {
                        Text("Analytics")
                            .font(.headline)

                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                angle: Angle(degrees: 45)
                            ))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer,
            prompt: Text("Search dashboard")
        )
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(trend)
                .font(.caption)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

// MARK: - Example 6: Horizontal Scroll Gallery with Transitions

/// A horizontal scrolling gallery with scroll-driven animations
struct HorizontalScrollGallery: View {
    let items = Array(1...10)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured Collection")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            HStack(spacing: 20) {
                ForEach(items, id: \.self) { item in
                    VStack(spacing: 12) {
                        // Image placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                angle: Angle(degrees: 45)
                            ))
                            .frame(width: 200, height: 250)
                            .scrollTransition(axis: .horizontal) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.5)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.85)
                                    .brightness(phase.isIdentity ? 1 : 0.7)
                            }

                        Text("Item \(item)")
                            .font(.headline)

                        Text("$\(item * 15).00")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollBounceBehavior(.always, axes: [.horizontal])
    }
}

// MARK: - Example 7: Form Layout with Responsive Columns

/// A form that switches from two-column to single-column based on space
struct ResponsiveFormLayout: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Contact Information")
                .font(.title)
                .fontWeight(.bold)

            ViewThatFits {
                // Desktop: Two-column form
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        FormField(label: "First Name", text: $firstName)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                        FormField(label: "Last Name", text: $lastName)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                    }

                    HStack(spacing: 16) {
                        FormField(label: "Email", text: $email)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                        FormField(label: "Phone", text: $phone)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                    }

                    HStack(spacing: 16) {
                        FormField(label: "Address", text: $address)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                        FormField(label: "City", text: $city)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                    }
                }

                // Mobile: Single-column form
                VStack(spacing: 12) {
                    FormField(label: "First Name", text: $firstName)
                    FormField(label: "Last Name", text: $lastName)
                    FormField(label: "Email", text: $email)
                    FormField(label: "Phone", text: $phone)
                    FormField(label: "Address", text: $address)
                    FormField(label: "City", text: $city)
                }
            }
            .padding()

            Text("Submit")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .onTapGesture {
                    // Submit action
                }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct FormField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)

            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Example 8: Complete E-commerce Product Page

/// A full product page with search, responsive layout, and scroll animations
struct EcommerceProductPage: View {
    @State private var searchText = ""
    @State private var selectedTab = 0

    let relatedProducts = [
        "Product A", "Product B", "Product C",
        "Product D", "Product E", "Product F"
    ]

    var filteredProducts: [String] {
        guard !searchText.isEmpty else { return relatedProducts }
        return relatedProducts.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Product details
            ViewThatFits {
                // Desktop: Image and details side-by-side
                HStack(alignment: .top, spacing: 30) {
                    // Product image
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            angle: Angle(degrees: 135)
                        ))
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 30)

                    // Product details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Product")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("$199.99")
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text("High-quality product with amazing features. Perfect for everyday use.")
                            .font(.body)
                            .foregroundColor(.gray)

                        Text("Add to Cart")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 30)
                }
                .padding()

                // Mobile: Stacked layout
                VStack(spacing: 20) {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            angle: Angle(degrees: 135)
                        ))
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Premium Product")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("$199.99")
                            .font(.title3)
                            .foregroundColor(.blue)

                        Text("High-quality product with amazing features.")
                            .font(.body)
                            .foregroundColor(.gray)

                        Text("Add to Cart")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }

            Divider()
                .padding(.vertical)

            // Related products section
            VStack(alignment: .leading, spacing: 16) {
                Text("Related Products")
                    .font(.headline)
                    .padding(.horizontal)

                ViewThatFits(in: .horizontal) {
                    // Desktop: 3 columns
                    VStack(spacing: 12) {
                        ForEach(0..<2, id: \.self) { row in
                            HStack(spacing: 12) {
                                ForEach(0..<3) { col in
                                    let index = row * 3 + col
                                    if index < filteredProducts.count {
                                        RelatedProductCard(name: filteredProducts[index])
                                            .containerRelativeFrame(
                                                .horizontal,
                                                count: 3,
                                                spacing: 12
                                            )
                                            .scrollTransition { content, phase in
                                                content
                                                    .opacity(phase.isIdentity ? 1 : 0.6)
                                                    .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Mobile: 2 columns
                    VStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(0..<2) { col in
                                    let index = row * 2 + col
                                    if index < filteredProducts.count {
                                        RelatedProductCard(name: filteredProducts[index])
                                            .containerRelativeFrame(
                                                .horizontal,
                                                count: 2,
                                                spacing: 10
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer,
            prompt: Text("Search products")
        )
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled()
    }
}

struct RelatedProductCard: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(name)
                .font(.caption)
                .lineLimit(1)

            Text("$49.99")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Main Demo View

/// Combined demo of all Phase 11 examples
struct Phase11DemoView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Phase 11: Responsive Design & Search")
                .font(.title)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 50) {
                    ResponsivePhotoGrid()
                    Divider()

                    AdaptiveNavigationBar()
                    Divider()

                    ScrollableCardList()
                    Divider()

                    SearchResultsPage()
                    Divider()

                    ResponsiveDashboard()
                    Divider()

                    HorizontalScrollGallery()
                    Divider()

                    ResponsiveFormLayout()
                    Divider()

                    EcommerceProductPage()
                }
            }
        }
        .padding()
    }
}
