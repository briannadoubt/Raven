import Foundation

// MARK: - Accessibility Role

/// Semantic roles that describe the purpose and behavior of UI elements.
///
/// Accessibility roles map to ARIA roles and help assistive technologies
/// understand the purpose of UI elements. They provide semantic information
/// beyond the visual presentation.
///
/// ## Overview
///
/// Use accessibility roles to communicate the purpose of custom UI elements:
///
/// ```swift
/// CustomView()
///     .accessibilityRole(.button)
/// ```
///
/// ## Common Roles
///
/// - **button**: Interactive element that triggers an action
/// - **heading**: Section header text
/// - **link**: Navigation element
/// - **image**: Visual content
/// - **textField**: Text input
/// - **searchField**: Search input
/// - **checkbox**: Toggle control
/// - **radioButton**: Mutually exclusive selection
/// - **list**: Collection of items
/// - **listItem**: Item within a list
/// - **table**: Data grid
/// - **cell**: Table cell
/// - **navigation**: Navigation landmark
/// - **main**: Main content landmark
/// - **complementary**: Supporting content landmark
/// - **banner**: Site header landmark
/// - **contentInfo**: Site footer landmark
/// - **region**: Generic landmark
/// - **form**: Form landmark
/// - **search**: Search landmark
/// - **dialog**: Modal dialog
/// - **alertDialog**: Alert dialog
/// - **alert**: Alert message
/// - **status**: Status update
/// - **progressbar**: Progress indicator
/// - **tablist**: Tab navigation container
/// - **tab**: Individual tab
/// - **tabpanel**: Tab content panel
/// - **menu**: Menu container
/// - **menuitem**: Menu item
/// - **toolbar**: Toolbar container
public enum AccessibilityRole: String, Sendable {
    // Interactive elements
    case button
    case link
    case checkbox
    case radioButton = "radio"
    case menuitem
    case menuitemCheckbox = "menuitemcheckbox"
    case menuitemRadio = "menuitemradio"
    case switch_ = "switch"
    case slider
    case spinbutton

    // Input elements
    case textField = "textbox"
    case searchField = "searchbox"
    case combobox

    // Structure
    case heading
    case list
    case listItem = "listitem"
    case table
    case row
    case cell
    case columnHeader = "columnheader"
    case rowHeader = "rowheader"
    case grid
    case gridcell

    // Landmark roles (WCAG 2.1 requirement)
    case navigation
    case main
    case complementary
    case banner
    case contentInfo = "contentinfo"
    case region
    case form
    case search

    // Widgets
    case dialog
    case alertDialog = "alertdialog"
    case alert
    case status
    case progressbar
    case tablist
    case tab
    case tabpanel
    case menu
    case menubar
    case toolbar
    case tooltip
    case tree
    case treeitem

    // Document structure
    case article
    case document
    case note
    case separator
    case group
    case none
    case presentation

    // Images
    case image = "img"
    case figure

    /// The ARIA role attribute value
    public var ariaValue: String {
        rawValue
    }
}

// MARK: - Accessibility Live Region

/// Priority levels for live region updates.
///
/// Live regions announce dynamic content changes to screen readers.
/// The priority determines how urgently the announcement should be made.
///
/// ## Overview
///
/// Use live regions for dynamic content that updates without page reload:
///
/// ```swift
/// Text(statusMessage)
///     .accessibilityLiveRegion(.polite)
/// ```
///
/// ## Priority Levels
///
/// - **off**: Changes are not announced (default)
/// - **polite**: Announce when user is idle (most common)
/// - **assertive**: Interrupt immediately (use sparingly)
public enum AccessibilityLiveRegion: String, Sendable {
    /// Changes are not announced
    case off
    /// Announce changes when user is idle
    case polite
    /// Interrupt and announce changes immediately
    case assertive

    /// The ARIA live region attribute value
    public var ariaValue: String {
        rawValue
    }
}

// MARK: - Accessibility Modifier

/// Internal modifier that applies accessibility attributes to a view.
@MainActor
internal struct AccessibilityModifier<Content: View>: View, Sendable {
    typealias Body = Never

    let content: Content
    let label: String?
    let hint: String?
    let value: String?
    let role: AccessibilityRole?
    let traits: AccessibilityTraits?
    let liveRegion: AccessibilityLiveRegion?
    let hidden: Bool?
    let labelledBy: String?
    let describedBy: String?
    let controls: String?
    let expanded: Bool?
    let pressed: Bool?
    let checked: Bool?
    let level: Int?
    let posInSet: Int?
    let setSize: Int?
    let invalid: Bool?
    let required: Bool?
    let readonly: Bool?
    let selected: Bool?
    let modal: Bool?

    @MainActor
    func toVNode() -> VNode {
        // This will be handled by the rendering system
        // which will apply the accessibility properties to the content's VNode
        var props: [String: VProperty] = [:]

        // Apply ARIA attributes
        if let label = label {
            props["aria-label"] = .attribute(name: "aria-label", value: label)
        }

        if let hint = hint {
            props["aria-description"] = .attribute(name: "aria-description", value: hint)
        }

        if let value = value {
            props["aria-valuenow"] = .attribute(name: "aria-valuenow", value: value)
        }

        if let role = role {
            props["role"] = .attribute(name: "role", value: role.ariaValue)
        }

        if let liveRegion = liveRegion, liveRegion != .off {
            props["aria-live"] = .attribute(name: "aria-live", value: liveRegion.ariaValue)
        }

        if let hidden = hidden, hidden {
            props["aria-hidden"] = .attribute(name: "aria-hidden", value: "true")
        }

        if let labelledBy = labelledBy {
            props["aria-labelledby"] = .attribute(name: "aria-labelledby", value: labelledBy)
        }

        if let describedBy = describedBy {
            props["aria-describedby"] = .attribute(name: "aria-describedby", value: describedBy)
        }

        if let controls = controls {
            props["aria-controls"] = .attribute(name: "aria-controls", value: controls)
        }

        if let expanded = expanded {
            props["aria-expanded"] = .attribute(name: "aria-expanded", value: expanded ? "true" : "false")
        }

        if let pressed = pressed {
            props["aria-pressed"] = .attribute(name: "aria-pressed", value: pressed ? "true" : "false")
        }

        if let checked = checked {
            props["aria-checked"] = .attribute(name: "aria-checked", value: checked ? "true" : "false")
        }

        if let level = level {
            props["aria-level"] = .attribute(name: "aria-level", value: "\(level)")
        }

        if let posInSet = posInSet {
            props["aria-posinset"] = .attribute(name: "aria-posinset", value: "\(posInSet)")
        }

        if let setSize = setSize {
            props["aria-setsize"] = .attribute(name: "aria-setsize", value: "\(setSize)")
        }

        if let invalid = invalid, invalid {
            props["aria-invalid"] = .attribute(name: "aria-invalid", value: "true")
        }

        if let required = required, required {
            props["aria-required"] = .attribute(name: "aria-required", value: "true")
        }

        if let readonly = readonly, readonly {
            props["aria-readonly"] = .attribute(name: "aria-readonly", value: "true")
        }

        if let selected = selected {
            props["aria-selected"] = .attribute(name: "aria-selected", value: selected ? "true" : "false")
        }

        if let modal = modal, modal {
            props["aria-modal"] = .attribute(name: "aria-modal", value: "true")
        }

        // Wrap content in a div with accessibility properties
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Sets the accessibility role for this view.
    ///
    /// The accessibility role describes the purpose and behavior of the view
    /// to assistive technologies. It maps to ARIA roles in the rendered HTML.
    ///
    /// ## Overview
    ///
    /// Use roles to communicate semantic meaning:
    ///
    /// ```swift
    /// VStack {
    ///     Text("Section Title")
    ///     Text("Section content...")
    /// }
    /// .accessibilityRole(.region)
    /// .accessibilityLabel("Content Section")
    /// ```
    ///
    /// ## Common Roles
    ///
    /// - **button**: Interactive trigger
    /// - **heading**: Section header
    /// - **navigation**: Navigation landmark
    /// - **main**: Main content landmark
    /// - **form**: Form landmark
    /// - **search**: Search landmark
    /// - **alert**: Alert message
    /// - **dialog**: Modal dialog
    ///
    /// - Parameter role: The semantic role of the view
    /// - Returns: A view with the accessibility role set
    @MainActor
    public func accessibilityRole(_ role: AccessibilityRole) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: role,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }

    /// Marks this view as a live region for dynamic content updates.
    ///
    /// Live regions announce changes to their content to assistive technologies,
    /// even when the region doesn't have focus. Use this for status messages,
    /// notifications, and other dynamic content.
    ///
    /// ## Overview
    ///
    /// Use live regions for content that updates without user interaction:
    ///
    /// ```swift
    /// Text(statusMessage)
    ///     .accessibilityLiveRegion(.polite)
    /// ```
    ///
    /// ## Priority Levels
    ///
    /// - **off**: No announcements (default)
    /// - **polite**: Announce when user is idle (recommended)
    /// - **assertive**: Interrupt immediately (use sparingly for critical alerts)
    ///
    /// ## Guidelines
    ///
    /// - Use `.polite` for most live regions
    /// - Reserve `.assertive` for urgent alerts
    /// - Keep announced content concise
    /// - Don't overuse live regions
    ///
    /// - Parameter liveRegion: The priority level for announcements
    /// - Returns: A view configured as a live region
    @MainActor
    public func accessibilityLiveRegion(_ liveRegion: AccessibilityLiveRegion) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: nil,
            traits: nil,
            liveRegion: liveRegion,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: nil,
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }
}
