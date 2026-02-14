import Foundation

extension View {
    /// Declares an accessibility drag point for Assistive Access and related technologies.
    @MainActor public func accessibilityDragPoint(
        _ point: UnitPoint,
        description: Text
    ) -> some View {
        accessibilityDragPoint(point, description: description, isEnabled: true)
    }

    /// Declares an accessibility drag point for Assistive Access and related technologies.
    @MainActor public func accessibilityDragPoint(
        _ point: UnitPoint,
        description: Text,
        isEnabled: Bool
    ) -> some View {
        guard isEnabled else { return AnyView(self) }
        return AnyView(
            _AccessibilityMetadataView(
                content: self,
                properties: [
                    "data-accessibility-drag-point-x": "\(point.x)",
                    "data-accessibility-drag-point-y": "\(point.y)",
                    "data-accessibility-drag-point-description": description.textContent,
                ]
            )
        )
    }

    /// Declares an accessibility drop point for Assistive Access and related technologies.
    @MainActor public func accessibilityDropPoint(
        _ point: UnitPoint,
        description: Text
    ) -> some View {
        accessibilityDropPoint(point, description: description, isEnabled: true)
    }

    /// Declares an accessibility drop point for Assistive Access and related technologies.
    @MainActor public func accessibilityDropPoint(
        _ point: UnitPoint,
        description: Text,
        isEnabled: Bool
    ) -> some View {
        guard isEnabled else { return AnyView(self) }
        return AnyView(
            _AccessibilityMetadataView(
                content: self,
                properties: [
                    "data-accessibility-drop-point-x": "\(point.x)",
                    "data-accessibility-drop-point-y": "\(point.y)",
                    "data-accessibility-drop-point-description": description.textContent,
                ]
            )
        )
    }

    /// Sets a navigation icon hint used by Assistive Access experiences.
    @MainActor public func assistiveAccessNavigationIcon(_ icon: Image) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-assistive-access-navigation-icon": String(describing: icon),
            ]
        )
    }

    /// Sets a navigation icon hint used by Assistive Access experiences.
    @MainActor public func assistiveAccessNavigationIcon(systemImage: String) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-assistive-access-navigation-system-image": systemImage,
            ]
        )
    }
}

extension Text {
    /// Marks text as an accessibility heading using a SwiftUI-compatible call shape.
    @MainActor public func accessibilityHeading(_ level: Int = 1) -> some View {
        AccessibilityModifier(
            content: self,
            label: nil,
            hint: nil,
            value: nil,
            role: .heading,
            traits: nil,
            liveRegion: nil,
            hidden: nil,
            labelledBy: nil,
            describedBy: nil,
            controls: nil,
            expanded: nil,
            pressed: nil,
            checked: nil,
            level: max(1, min(6, level)),
            posInSet: nil,
            setSize: nil,
            invalid: nil,
            required: nil,
            readonly: nil,
            selected: nil,
            modal: nil
        )
    }

    /// Sets an accessibility label using a `Text` value.
    @MainActor public func accessibilityLabel(_ label: Text) -> some View {
        AccessibilityModifier(
            content: self,
            label: label.textContent,
            hint: nil,
            value: nil,
            role: nil,
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

    /// Sets a semantic accessibility text content type.
    @MainActor public func accessibilityTextContentType(
        _ contentType: AccessibilityTextContentType
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-text-content-type": contentType.rawValue]
        )
    }
}
