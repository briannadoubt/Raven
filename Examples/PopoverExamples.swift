import Foundation
import Raven

// MARK: - Popover Examples

/// This file demonstrates various popover usage patterns in Raven.
///
/// The examples show:
/// - Basic popover presentation
/// - Custom anchor points
/// - Different arrow edges
/// - Item-based popovers
/// - Complex popover content
/// - Multiple popovers
/// - Dismiss callbacks

// MARK: - Basic Popover Example

/// A simple button that shows an info popover
struct BasicPopoverExample: View {
    @State private var showInfo = false

    var body: some View {
        Button("Show Info") {
            showInfo = true
        }
        .popover(isPresented: $showInfo) {
            Text("This is a basic popover")
                .padding()
        }
    }
}

// MARK: - Custom Anchor Point Example

/// Demonstrates different anchor points for popovers
struct AnchorPointExample: View {
    @State private var showTopLeading = false
    @State private var showCenter = false
    @State private var showBottomTrailing = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Top Leading Anchor") {
                showTopLeading = true
            }
            .popover(
                isPresented: $showTopLeading,
                attachmentAnchor: .point(.topLeading),
                arrowEdge: .bottom
            ) {
                Text("Anchored to top-leading corner")
                    .padding()
            }

            Button("Center Anchor") {
                showCenter = true
            }
            .popover(
                isPresented: $showCenter,
                attachmentAnchor: .point(.center),
                arrowEdge: .top
            ) {
                Text("Anchored to center")
                    .padding()
            }

            Button("Bottom Trailing Anchor") {
                showBottomTrailing = true
            }
            .popover(
                isPresented: $showBottomTrailing,
                attachmentAnchor: .point(.bottomTrailing),
                arrowEdge: .top
            ) {
                Text("Anchored to bottom-trailing corner")
                    .padding()
            }
        }
    }
}

// MARK: - Custom Rect Anchor Example

/// Shows how to use a custom rectangular anchor region
struct CustomRectAnchorExample: View {
    @State private var showPopover = false

    var body: some View {
        GeometryReader { geometry in
            let rightHalf = CGRect(
                x: geometry.size.width / 2,
                y: 0,
                width: geometry.size.width / 2,
                height: geometry.size.height
            )

            Button("Show on Right Half") {
                showPopover = true
            }
            .frame(width: 200, height: 50)
            .popover(
                isPresented: $showPopover,
                attachmentAnchor: .rect(.rect(rightHalf)),
                arrowEdge: .leading
            ) {
                Text("Attached to right half of button")
                    .padding()
            }
        }
    }
}

// MARK: - Arrow Edge Example

/// Demonstrates all four arrow edge options
struct ArrowEdgeExample: View {
    @State private var selectedEdge: Edge = .top
    @State private var showPopover = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Arrow Edge:")
                .font(.headline)

            Picker("Arrow Edge", selection: $selectedEdge) {
                Text("Top").tag(Edge.top)
                Text("Bottom").tag(Edge.bottom)
                Text("Leading").tag(Edge.leading)
                Text("Trailing").tag(Edge.trailing)
            }

            Button("Show Popover") {
                showPopover = true
            }
            .popover(
                isPresented: $showPopover,
                arrowEdge: selectedEdge
            ) {
                VStack(spacing: 8) {
                    Text("Arrow Edge: \(selectedEdge.rawValue)")
                        .font(.headline)
                    Text("The arrow points from this edge")
                        .font(.caption)
                }
                .padding()
            }
        }
        .padding()
    }
}

// MARK: - Item-Based Popover Example

/// Uses an identifiable item to drive popover presentation
struct ItemBasedPopoverExample: View {
    struct User: Identifiable {
        let id: Int
        let name: String
        let email: String
    }

    let users = [
        User(id: 1, name: "Alice", email: "alice@example.com"),
        User(id: 2, name: "Bob", email: "bob@example.com"),
        User(id: 3, name: "Charlie", email: "charlie@example.com")
    ]

    @State private var selectedUser: User?

    var body: some View {
        VStack(spacing: 10) {
            Text("Select a user to see details:")
                .font(.headline)

            ForEach(users) { user in
                Button(user.name) {
                    selectedUser = user
                }
            }
        }
        .popover(item: $selectedUser) { user in
            VStack(alignment: .leading, spacing: 12) {
                Text(user.name)
                    .font(.headline)

                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Close") {
                    selectedUser = nil
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

// MARK: - Complex Content Example

/// Shows a popover with rich content including forms and actions
struct ComplexContentExample: View {
    @State private var showSettings = false
    @State private var notificationsEnabled = true
    @State private var volume: Double = 0.5

    var body: some View {
        Button("Settings") {
            showSettings = true
        }
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.headline)

                Toggle("Notifications", isOn: $notificationsEnabled)

                VStack(alignment: .leading) {
                    Text("Volume")
                    // Slider would go here
                    Text("\(Int(volume * 100))%")
                        .font(.caption)
                }

                HStack {
                    Button("Cancel") {
                        showSettings = false
                    }

                    Button("Save") {
                        // Save settings
                        showSettings = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 250)
        }
    }
}

// MARK: - Dismiss Callback Example

/// Demonstrates using the onDismiss callback
struct DismissCallbackExample: View {
    @State private var showPopover = false
    @State private var dismissCount = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Popover dismissed \(dismissCount) times")
                .font(.caption)

            Button("Show Popover") {
                showPopover = true
            }
            .popover(
                isPresented: $showPopover,
                onDismiss: {
                    dismissCount += 1
                    print("Popover was dismissed")
                }
            ) {
                VStack(spacing: 12) {
                    Text("Dismiss me!")

                    Button("Close") {
                        showPopover = false
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Multiple Popovers Example

/// Shows how to handle multiple popovers on a single view
struct MultiplePopoversExample: View {
    @State private var showHelp = false
    @State private var showInfo = false
    @State private var showWarning = false

    var body: some View {
        HStack(spacing: 30) {
            Button("Help") {
                showHelp = true
            }
            .popover(
                isPresented: $showHelp,
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                Text("Help content here")
                    .padding()
            }

            Button("Info") {
                showInfo = true
            }
            .popover(
                isPresented: $showInfo,
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                Text("Information content here")
                    .padding()
            }

            Button("Warning") {
                showWarning = true
            }
            .popover(
                isPresented: $showWarning,
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                VStack {
                    Text("Warning!")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text("This action cannot be undone")
                        .font(.caption)
                }
                .padding()
            }
        }
    }
}

// MARK: - Context Menu Style Example

/// A popover used as a context menu replacement
struct ContextMenuStyleExample: View {
    struct MenuItem: Identifiable {
        let id = UUID()
        let title: String
        let action: () -> Void
    }

    @State private var showMenu = false

    var body: some View {
        Button("Right Click (or tap)") {
            showMenu = true
        }
        .popover(
            isPresented: $showMenu,
            attachmentAnchor: .point(.topLeading),
            arrowEdge: .trailing
        ) {
            VStack(alignment: .leading, spacing: 8) {
                menuButton("Copy") {
                    print("Copy action")
                    showMenu = false
                }

                menuButton("Paste") {
                    print("Paste action")
                    showMenu = false
                }

                menuButton("Delete") {
                    print("Delete action")
                    showMenu = false
                }
            }
            .padding(8)
        }
    }

    private func menuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            action()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}

// MARK: - Tooltip Style Example

/// A popover styled like a tooltip
struct TooltipStyleExample: View {
    @State private var showTooltip = false

    var body: some View {
        Button("Hover for info") {
            showTooltip = true
        }
        .popover(
            isPresented: $showTooltip,
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom,
            onDismiss: {
                print("Tooltip dismissed")
            }
        ) {
            Text("This is a helpful tooltip")
                .font(.caption)
                .padding(8)
        }
    }
}

// MARK: - Color Picker Example

/// A practical example of a color picker popover
struct ColorPickerPopoverExample: View {
    @State private var selectedColor = Color.blue
    @State private var showPicker = false

    let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Selected Color")
                .font(.headline)

            Circle()
                .fill(selectedColor)
                .frame(width: 60, height: 60)
                .onTapGesture {
                    showPicker = true
                }
                .popover(
                    isPresented: $showPicker,
                    attachmentAnchor: .point(.center),
                    arrowEdge: .bottom
                ) {
                    VStack(spacing: 12) {
                        Text("Choose a color")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .onTapGesture {
                                        selectedColor = color
                                        showPicker = false
                                    }
                            }
                        }
                    }
                    .padding()
                }
        }
    }
}

// MARK: - Form Validation Example

/// Shows validation errors in a popover
struct FormValidationExample: View {
    @State private var email = ""
    @State private var showValidation = false

    var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .popover(
                    isPresented: $showValidation,
                    attachmentAnchor: .point(.trailing),
                    arrowEdge: .leading
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invalid Email")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text("Email must contain @ and .")
                            .font(.caption)
                    }
                    .padding()
                }

            Button("Validate") {
                if !isValidEmail {
                    showValidation = true
                } else {
                    showValidation = false
                    print("Email is valid!")
                }
            }
        }
        .padding()
    }
}
