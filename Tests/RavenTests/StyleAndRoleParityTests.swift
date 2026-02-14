import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite struct StyleAndRoleParityTests {
    @Test func primitiveButtonStyleStaticsCompile() {
        let _ = PrimitiveButtonStyle.automatic
        let _ = PrimitiveButtonStyle.glass
        let _ = PrimitiveButtonStyle.glass(.prominent)
        let _ = PrimitiveButtonStyle.glassProminent
        #expect(true)
    }

    @Test func toggleStyleStaticsCompile() {
        let _ = ToggleStyle.automatic
        let _ = ToggleStyle.button
        let _ = ToggleStyle.switch
        #expect(true)
    }

    @Test func gaugeStyleStaticsCompile() {
        let _ = GaugeStyle.automatic
        let _ = GaugeStyle.accessoryCircular
        let _ = GaugeStyle.accessoryCircularCapacity
        let _ = GaugeStyle.accessoryLinear
        let _ = GaugeStyle.accessoryLinearCapacity
        #expect(true)
    }

    @Test func textAndMenuAutomaticStylesCompile() {
        let _ = TextFieldStyle.automatic
        let _ = MenuStyle.automatic
        let _ = MenuStyle.borderlessButton
        #expect(true)
    }

    @Test func buttonRoleCasesCompile() {
        let roles: [ButtonRole] = [.cancel, .close, .confirm, .destructive]
        #expect(roles.count == 4)
    }

    @Test func buttonStaticConstructorsCompile() {
        let cancel1 = Button.cancel("Cancel")
        let cancel2 = Button.cancel("Cancel") {}
        let normal = Button.default("OK") {}
        let destructive = Button.destructive("Delete") {}
        #expect(cancel1 != nil)
        #expect(cancel2 != nil)
        #expect(normal != nil)
        #expect(destructive != nil)
    }

    @Test func searchFieldPlacementVariantsCompile() {
        let placements: [SearchFieldPlacement] = [
            .automatic,
            .navigationBarDrawer,
            .navigationBarDrawer(displayMode: .automatic),
            .sidebar,
            .toolbar,
            .toolbarPrincipal,
        ]
        #expect(placements.count == 6)
    }

    @Test func accessibilityEnvironmentFlagsCompile() {
        var environment = EnvironmentValues()
        environment.accessibilityAssistiveAccessEnabled = true
        environment.accessibilityLargeContentViewerEnabled = true
        environment.accessibilityQuickActionsEnabled = true
        environment.accessibilitySwitchControlEnabled = true
        environment.accessibilityVoiceOverEnabled = true

        #expect(environment.accessibilityAssistiveAccessEnabled)
        #expect(environment.accessibilityLargeContentViewerEnabled)
        #expect(environment.accessibilityQuickActionsEnabled)
        #expect(environment.accessibilitySwitchControlEnabled)
        #expect(environment.accessibilityVoiceOverEnabled)
    }

    @Test func interactionParityTypesCompile() {
        let interactions: [FocusInteractions] = [.automatic, .activate]
        let severities: [DialogSeverity] = [.automatic, .critical]
        #expect(interactions.count == 2)
        #expect(severities.count == 2)
    }

    @Test func highSignalOwnerParityTypesCompile() {
        let _ = BackgroundDisplayMode.automatic
        let _ = BackgroundDisplayMode.always
        let _ = IndexDisplayMode.automatic
        let _ = IndexDisplayMode.always
        let _ = LimitBehavior.automatic
        let _ = LimitBehavior.always
        let _ = LimitBehavior.alwaysByFew
        let _ = LimitBehavior.alwaysByOne
        let _ = ScrollBounceBehavior.automatic
        let _ = ScrollBounceBehavior.always
        let _ = ScrollBounceBehavior.basedOnSize
        let _ = ToolbarCustomizationOptions.alwaysAvailable
        let _ = InterfaceOrientation.allCases
        let _ = DefaultFocusEvaluationPriority.automatic
        let _ = MenuOrder.automatic
        let _ = SceneRestorationBehavior.automatic
        let _ = ScrollDismissesKeyboardMode.automatic
        let _ = ScrollIndicatorVisibility.automatic
        let _ = ScrollIndicatorVisibility.visible
        let _ = ScrollIndicatorVisibility.hidden
        let _ = ScrollInputBehavior.automatic
        let _ = SearchPresentationToolbarBehavior.automatic
        let _ = SearchPresentationToolbarBehavior.avoidHidingContent
        let _ = SearchToolbarBehavior.automatic
        let _ = TabBarMinimizeBehavior.automatic
        let _ = TabCustomizationBehavior.automatic
        let _ = TabPlacement.automatic
        let _ = TabSearchActivation.automatic
        let _ = TableColumnAlignment.automatic
        let _ = TextInputDictationBehavior.automatic
        let _ = ToolbarLabelStyle.automatic
        let _ = ToolbarRole.automatic
        let _ = ToolbarRole.browser
        let _ = WindowManagerRole.automatic
        let _ = WindowResizability.automatic
        let _ = WindowToolbarFullScreenVisibility.automatic
        let _ = WritingToolsBehavior.automatic
        let _ = PresentationBackgroundInteraction.automatic
        let _ = PresentationContentInteraction.automatic
        let _ = (any PresentationSizing).self
        let _ = PresentationSizing.automatic
        let _ = (any CustomHoverEffect).self
        let _ = CustomHoverEffect.automatic
        let _ = (any NavigationTransition).self
        let _ = NavigationTransition.automatic

        let inputPose = InputDevicePose(altitude: 1.0, azimuth: 2.0)
        let hoverPose = PencilHoverPose(altitude: 1.0, azimuth: 2.0, anchor: .center)
        #expect(inputPose.altitude == 1.0)
        #expect(inputPose.azimuth == 2.0)
        #expect(hoverPose.altitude == 1.0)
        #expect(hoverPose.azimuth == 2.0)
        #expect(hoverPose.anchor == .center)
        #expect(SensoryFeedback.success.alignment == .center)
    }

    @Test func scrollBounceBehaviorOverloadAndSubscriptionActionCompile() {
        let gridItem = GridItem(.flexible(), spacing: 8, alignment: .center)
        #expect(gridItem.alignment == .center)

        let bounced = ScrollView {
            Text("Row")
        }
        .scrollBounceBehavior(.always, axes: [.vertical])
        #expect(bounced != nil)

        let subscription = SubscriptionView {
            Text("Premium")
        }
        #expect(subscription.action == nil)
    }

    @Test func datePickerOwnerAliasAndTimelineScheduleStaticsCompile() {
        let _: DatePicker.Components = [.date, .hourAndMinute]
        let scheduleA = AnimationTimelineSchedule.animation
        let scheduleB = AnimationTimelineSchedule.animation(minimumInterval: 0.25, paused: false)
        #expect(scheduleA.entries(from: Date(), mode: .normal).isEmpty)
        #expect(scheduleB.entries(from: Date(), mode: .normal).isEmpty)
    }

    @Test func scrollTransitionConfigurationParityCompile() {
        let base = ScrollTransitionConfiguration(axis: .vertical)
        #expect(base.animated)
        let disabled = base.animated(false)
        #expect(!disabled.animated)
        let withAnimation = base.animation(.default)
        #expect(withAnimation.animated)
    }

    @Test func highSignalAccessibilityParityCompiles() {
        let baseText = Text("Title")
        let headingText = baseText.accessibilityHeading(2)
        let explicitTextLabel = baseText.accessibilityLabel(Text("Accessible title"))
        let textType = baseText.accessibilityTextContentType(.sourceCode)

        #expect(headingText != nil)
        #expect(explicitTextLabel != nil)
        #expect(textType != nil)
    }
}
