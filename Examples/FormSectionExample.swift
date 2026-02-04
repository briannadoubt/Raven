import Foundation
import Raven

/// Example demonstrating Form and Section views in Raven.
///
/// This example shows how to create semantic form structures with sections,
/// headers, and footers for organizing form content.
@main
@MainActor
struct FormSectionExample {
    static func main() async {
        // Example 1: Simple Form with Sections
        let simpleForm = Form {
            Section(header: "Personal Information") {
                Text("Name: John Doe")
                Text("Email: john@example.com")
            }

            Section(header: "Preferences") {
                Text("Notifications: Enabled")
                Text("Theme: Dark")
            }
        }

        print("Example 1: Simple Form with Sections")
        let vnode1 = simpleForm.toVNode()
        print("Form element: \(vnode1.elementTag ?? "unknown")")
        print("Form has role attribute: \(vnode1.props["role"] != nil)")
        print("Form has submit handler: \(vnode1.props["onSubmit"] != nil)")
        print()

        // Example 2: Section with Header and Footer
        let sectionWithFooter = Section(
            header: "Account Settings",
            footer: { Text("Changes will take effect immediately") }
        ) {
            Text("Username: johndoe")
            Text("Status: Active")
        }

        print("Example 2: Section with Header and Footer")
        let vnode2 = sectionWithFooter.toVNode()
        print("Section element: \(vnode2.elementTag ?? "unknown")")
        print("Has header: \(sectionWithFooter.header != nil)")
        print("Has footer: \(sectionWithFooter.footer != nil)")
        print()

        // Example 3: Nested Layout
        let nestedForm = Form {
            Section(header: "Login Information") {
                VStack(spacing: 8) {
                    Text("Username")
                    Text("Password")
                }
            }

            Section {
                Text("Remember me")
            }

            Section(footer: { Text("Forgot your password?") }) {
                Text("Submit")
            }
        }

        print("Example 3: Nested Form Layout")
        let vnode3 = nestedForm.toVNode()
        print("Form created with \(vnode3.props.count) properties")
        print()

        // Example 4: Custom Header View
        let customHeaderSection = Section(
            header: {
                HStack {
                    Text("Settings")
                    Text("⚙️")
                }
            }
        ) {
            Text("Dark Mode: On")
            Text("Sound: Off")
        }

        print("Example 4: Section with Custom Header")
        let vnode4 = customHeaderSection.toVNode()
        print("Section element: \(vnode4.elementTag ?? "unknown")")
        print()

        // Example 5: Form Styling
        let formProps = simpleForm.toVNode().props
        print("Example 5: Form Default Styling")
        if case .style(_, let value) = formProps["display"] {
            print("Display: \(value)")
        }
        if case .style(_, let value) = formProps["flex-direction"] {
            print("Flex Direction: \(value)")
        }
        if case .style(_, let value) = formProps["gap"] {
            print("Gap: \(value)")
        }
        if case .style(_, let value) = formProps["width"] {
            print("Width: \(value)")
        }
        print()

        print("Form and Section examples completed successfully!")
    }
}
