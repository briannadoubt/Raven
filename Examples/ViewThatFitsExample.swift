import Raven

/// Example demonstrating ViewThatFits for responsive layouts.
///
/// This example shows how to use ViewThatFits to create layouts that automatically
/// adapt between desktop and mobile views based on available space.
struct ViewThatFitsExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Responsive Navigation Header

            ViewThatFits(in: .horizontal) {
                // Wide layout for desktop
                HStack(spacing: 16) {
                    Text("MyApp")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 12) {
                        Text("Home")
                        Text("Products")
                        Text("About")
                        Text("Contact")
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Text("Sign In")
                        Text("Sign Up")
                    }
                }
                .padding()

                // Medium layout - condensed navigation
                HStack {
                    Text("MyApp")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 8) {
                        Text("Home")
                        Text("More")
                    }
                    Spacer()
                    Text("Sign In")
                }
                .padding()

                // Compact layout for mobile
                VStack {
                    HStack {
                        Text("MyApp")
                        Spacer()
                        Text("Menu")
                    }
                    .padding()
                }
            }

            Divider()

            // MARK: - Responsive Form Layout

            ViewThatFits {
                // Two-column layout for wide screens
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Information")
                            .font(.headline)
                        Text("First Name")
                        Text("Last Name")
                        Text("Email")
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Details")
                            .font(.headline)
                        Text("Phone")
                        Text("Address")
                        Text("City")
                    }
                }
                .padding()

                // Single-column layout for narrow screens
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personal Information")
                        .font(.headline)
                    Text("First Name")
                    Text("Last Name")
                    Text("Email")

                    Text("Contact Details")
                        .font(.headline)
                    Text("Phone")
                    Text("Address")
                    Text("City")
                }
                .padding()
            }

            Divider()

            // MARK: - Responsive Card Grid

            ViewThatFits(in: .horizontal) {
                // Three cards side by side
                HStack(spacing: 16) {
                    CardView(title: "Card 1")
                    CardView(title: "Card 2")
                    CardView(title: "Card 3")
                }

                // Two cards side by side
                HStack(spacing: 16) {
                    CardView(title: "Card 1")
                    CardView(title: "Card 2")
                }

                // Vertical stack for mobile
                VStack(spacing: 16) {
                    CardView(title: "Card 1")
                    CardView(title: "Card 2")
                    CardView(title: "Card 3")
                }
            }
            .padding()

            Divider()

            // MARK: - Responsive Toolbar

            ViewThatFits(in: .horizontal) {
                // Full toolbar
                HStack(spacing: 12) {
                    Text("New")
                    Text("Edit")
                    Text("Delete")
                    Spacer()
                    Text("Share")
                    Text("Export")
                    Text("Settings")
                }

                // Condensed toolbar
                HStack(spacing: 12) {
                    Text("New")
                    Text("Edit")
                    Spacer()
                    Text("More")
                }

                // Icon-only toolbar
                HStack(spacing: 8) {
                    Text("+")
                    Spacer()
                    Text("⋯")
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct CardView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text("Description")
                .font(.body)
            Text("Action")
        }
        .padding()
    }
}

// MARK: - Advanced Examples

struct AdvancedViewThatFitsExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Dashboard Layout

            ViewThatFits {
                // Wide dashboard with sidebar
                HStack(alignment: .top, spacing: 20) {
                    // Sidebar
                    VStack(alignment: .leading) {
                        Text("Navigation")
                            .font(.headline)
                        Text("Dashboard")
                        Text("Analytics")
                        Text("Reports")
                        Text("Settings")
                    }
                    .padding()

                    // Main content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dashboard")
                            .font(.title)

                        HStack(spacing: 16) {
                            StatCard(title: "Users", value: "1,234")
                            StatCard(title: "Revenue", value: "$56.7K")
                            StatCard(title: "Growth", value: "+12%")
                        }
                    }
                }

                // Medium layout with top navigation
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Dashboard")
                        Text("Analytics")
                        Text("Reports")
                    }

                    HStack(spacing: 16) {
                        StatCard(title: "Users", value: "1,234")
                        StatCard(title: "Revenue", value: "$56.7K")
                    }
                }

                // Compact mobile layout
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dashboard")
                        .font(.title)

                    VStack(spacing: 12) {
                        StatCard(title: "Users", value: "1,234")
                        StatCard(title: "Revenue", value: "$56.7K")
                        StatCard(title: "Growth", value: "+12%")
                    }
                }
            }
            .padding()

            Divider()

            // MARK: - Nested ViewThatFits

            ViewThatFits(in: .horizontal) {
                // Desktop: horizontal sections, each with responsive content
                HStack(spacing: 20) {
                    ViewThatFits(in: .vertical) {
                        VStack {
                            Text("Section A")
                            Text("Detailed content")
                            Text("More details")
                        }
                        VStack {
                            Text("Section A")
                            Text("Brief content")
                        }
                    }

                    ViewThatFits(in: .vertical) {
                        VStack {
                            Text("Section B")
                            Text("Detailed content")
                            Text("More details")
                        }
                        VStack {
                            Text("Section B")
                            Text("Brief content")
                        }
                    }
                }

                // Mobile: vertical sections
                VStack(spacing: 20) {
                    VStack {
                        Text("Section A")
                        Text("Content")
                    }
                    VStack {
                        Text("Section B")
                        Text("Content")
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
            Text(value)
                .font(.title)
        }
        .padding()
    }
}

// MARK: - Usage Notes

/*
 ViewThatFits Best Practices:

 1. **Order Matters**: Always list views from most preferred to least preferred.
    The first view that fits will be displayed.

 2. **Always Provide a Fallback**: The last view should be compact enough to fit
    in minimal space as a guaranteed fallback.

 3. **Axis Selection**:
    - .horizontal: For layouts that differ in width (navigation, toolbars)
    - .vertical: For layouts that differ in height (content sections)
    - [.horizontal, .vertical]: For layouts that differ in both dimensions

 4. **Performance**: ViewThatFits uses CSS container queries, which are highly
    efficient. The browser handles the selection natively.

 5. **Testing**: Always test your ViewThatFits layouts at various sizes to ensure
    all options display correctly and transitions are smooth.

 6. **Combining with Other Modifiers**: ViewThatFits works well with:
    - .containerRelativeFrame() for precise sizing
    - GeometryReader for dynamic sizing
    - .padding() and .frame() for spacing control

 7. **Browser Support**: Ensure your target browsers support CSS container queries:
    - Chrome/Edge 105+
    - Safari 16+
    - Firefox 110+

 8. **Avoid Overuse**: Don't use ViewThatFits for simple hide/show logic.
    Use it when you have genuinely different layouts for different sizes.
 */
