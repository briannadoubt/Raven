import Foundation
import Raven

/// Example demonstrating the Image and Toggle primitive views
///
/// This example shows:
/// - Creating images from different sources (named, system icons)
/// - Using toggles with two-way data binding
/// - Combining images and toggles in a form-like layout
struct ImageToggleExample: View {
    @State private var showImage = true
    @State private var enableNotifications = false
    @State private var darkModeEnabled = false

    var body: some View {
        VStack {
            Text("Image and Toggle Demo")

            // Simple toggle
            Toggle("Show Image", isOn: $showImage)

            // Conditionally display image
            if showImage {
                Image("sample-photo")
                    .accessibilityLabel("A sample photograph")
            }

            // Toggle with system icon label
            Toggle(isOn: $enableNotifications) {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Enable Notifications")
                }
            }

            // Another toggle example
            Toggle("Dark Mode", isOn: $darkModeEnabled)

            // Display status
            Text("Notifications: \(enableNotifications ? "On" : "Off")")
            Text("Dark Mode: \(darkModeEnabled ? "On" : "Off")")

            // Decorative image example
            Image(decorative: "decoration")

            // Image with custom alt text
            Image("profile", alt: "User profile picture")
        }
    }
}

/// Example showing different image types
struct ImageVariationsExample: View {
    var body: some View {
        VStack {
            Text("Image Types")

            // Named image
            Image("photo")

            // System icon
            Image(systemName: "star.fill")

            // Decorative image (hidden from screen readers)
            Image(decorative: "background-pattern")

            // Image with custom accessibility label
            Image("chart")
                .accessibilityLabel("Sales chart showing upward trend")
        }
    }
}

/// Example showing toggle in a settings-style interface
struct SettingsExample: View {
    @State private var airplaneMode = false
    @State private var wifiEnabled = true
    @State private var bluetoothEnabled = true
    @State private var locationServices = false

    var body: some View {
        VStack {
            Text("Settings")

            Toggle("Airplane Mode", isOn: $airplaneMode)
            Toggle("Wi-Fi", isOn: $wifiEnabled)
            Toggle("Bluetooth", isOn: $bluetoothEnabled)
            Toggle("Location Services", isOn: $locationServices)

            // Status summary with icons
            HStack {
                if airplaneMode {
                    Image(systemName: "airplane")
                }
                if wifiEnabled {
                    Image(systemName: "wifi")
                }
                if bluetoothEnabled {
                    Image(systemName: "bluetooth")
                }
                if locationServices {
                    Image(systemName: "location.fill")
                }
            }
        }
    }
}

/// Example demonstrating VNode generation for testing
@MainActor
func testImageToggleVNodeGeneration() {
    // Test Image VNode generation
    let namedImage = Image("test-photo")
    let imageNode = namedImage.toVNode()
    print("Named image VNode: \(imageNode)")

    let systemImage = Image(systemName: "heart.fill")
    let systemNode = systemImage.toVNode()
    print("System image VNode: \(systemNode)")

    // Test Toggle VNode generation
    let binding = Binding<Bool>(
        get: { true },
        set: { _ in }
    )

    let toggle = Toggle("Test Toggle", isOn: binding)
    let toggleNode = toggle.toVNode()
    print("Toggle VNode: \(toggleNode)")

    // Verify properties
    print("\nImage element tag: \(imageNode.elementTag ?? "none")")
    print("Toggle element tag: \(toggleNode.elementTag ?? "none")")
    print("Toggle has children: \(!toggleNode.children.isEmpty)")
}
