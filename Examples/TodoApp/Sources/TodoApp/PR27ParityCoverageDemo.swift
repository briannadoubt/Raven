import SwiftUI

extension FocusedValues {
    var pr27StringValue: String? {
        get { nil }
        set {}
    }

    var pr27IntValue: Int? {
        get { nil }
        set {}
    }
}

@MainActor
final class PR27FocusObject: @unchecked Sendable {}

private struct PR27RotorEntry: Sendable {
    let id: Int
    let label: Text
}

@MainActor
private struct PR27CoverageRow<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)
            content
        }
        .padding(10)
        .background(Color.secondarySystemBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

@MainActor
struct PR27ParityCoverageDemo: View {
    @State private var textFieldValue = "Coverage Text"
    @State private var secureFieldValue = "secret"
    @State private var textEditorValue = "Editor coverage text"
    @State private var suppressionFlag = false
    @State private var focusFlag = false
    @State private var focusSelection: String? = "alpha"
    @State private var scrollPosition = ScrollPosition(id: "seed")
    @State private var scrollID: String? = "row-2"
    @State private var sensoryTrigger = 0
    @State private var symbolTrigger = 0
    @State private var userActivityCounter = 0
    @State private var parityMessage = "PR27 parity coverage loaded"
    private let focusObject = PR27FocusObject()
    private let rotorEntries: [PR27RotorEntry] = [
        PR27RotorEntry(id: 1, label: Text("Rotor One")),
        PR27RotorEntry(id: 2, label: Text("Rotor Two")),
    ]
    private let rotorSource = "RotorSource"

    private var rotorRanges: [Range<String.Index>] {
        let start = rotorSource.startIndex
        let middle = rotorSource.index(start, offsetBy: 5)
        let end = rotorSource.endIndex
        return [start..<middle, middle..<end]
    }

    private var launchSceneCoverageText: String {
        _ = DocumentGroupLaunchScene { DefaultDocumentGroupLaunchActions() }
        _ = DocumentGroupLaunchScene<DefaultDocumentGroupLaunchActions>()
        return "DocumentGroupLaunchScene covered"
    }

    var body: some View {
        SectionCard(title: "PR #27 Component Coverage") {
            VStack(alignment: .leading, spacing: 12) {
                Text("This section intentionally exercises every API added in PR #27.")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)

                VStack(spacing: 12) {
                    PR27CoverageRow("DocumentGroupLaunchScene + DefaultDocumentGroupLaunchActions") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(launchSceneCoverageText)
                            DefaultDocumentGroupLaunchActions()
                        }
                    }

                    PR27CoverageRow("buttonBorderShape") {
                        HStack(spacing: 8) {
                            Button("Auto") { parityMessage = "Button border: automatic" }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.automatic)
                            Button("Capsule") { parityMessage = "Button border: capsule" }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            Button("Circle") { parityMessage = "Button border: circle" }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                            Button("Rounded 20") { parityMessage = "Button border: rounded" }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.roundedRectangle(radius: 20))
                        }
                    }

                    PR27CoverageRow("Text input modifiers") {
                        VStack(spacing: 8) {
                            TextField("keyboardType + textInputAutocapitalization", text: $textFieldValue)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()

                            SecureField("disableAutocorrection + autocapitalization", text: $secureFieldValue)
                                .disableAutocorrection(true)
                                .autocapitalization(.characters)
                                .keyboardType(.numberPad)

                            TextEditor(text: $textEditorValue)
                                .frame(height: 70)
                                .keyboardType(.webSearch)
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled(false)
                        }
                    }

                    PR27CoverageRow("Phase2: help/hover/badge/button repeat") {
                        VStack(spacing: 8) {
                            Text("help(String)")
                                .help("Help from String")
                            Text("help(Text)")
                                .help(Text("Help from Text"))

                            Text("hoverEffect default")
                                .hoverEffect()
                            Text("hoverEffect + isEnabled")
                                .hoverEffect(.lift, isEnabled: true)

                            Text("defaultHoverEffect + hoverEffectDisabled")
                                .defaultHoverEffect(.highlight)
                                .hoverEffectDisabled(false)

                            Text("badgeProminence + buttonRepeatBehavior")
                                .badgeProminence(.increased)
                                .buttonRepeatBehavior(.enabled)
                        }
                    }

                    PR27CoverageRow("Phase3: labels/list row insets") {
                        VStack(spacing: 8) {
                            Label("labelsVisibility(.visible)", systemImage: "eye")
                                .labelsVisibility(.visible)
                            Label("labelsHidden()", systemImage: "eye.slash")
                                .labelsHidden()
                            Text("listRowInsets")
                                .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                        }
                    }

                    PR27CoverageRow("Phase4: behavior flags") {
                        VStack(spacing: 8) {
                            Text("find/delete/focus behavior")
                                .findDisabled()
                                .deleteDisabled(true)
                                .focusEffectDisabled()

                            Text("window activation + background extension")
                                .allowsWindowActivationEvents()
                                .allowsWindowActivationEvents(false)
                                .backgroundExtensionEffect()
                                .backgroundExtensionEffect(isEnabled: false)

                            Text("dialogSuppressionToggle(String)")
                                .dialogSuppressionToggle("Skip next time", isSuppressed: $suppressionFlag)
                            Text("dialogSuppressionToggle(Text)")
                                .dialogSuppressionToggle(Text("Suppress reminder"), isSuppressed: $suppressionFlag)
                            Text("dialogSuppressionToggle(isSuppressed:)")
                                .dialogSuppressionToggle(isSuppressed: $suppressionFlag)
                        }
                    }

                    PR27CoverageRow("Phase5: focus + scroll position") {
                        VStack(spacing: 8) {
                            Text("focusedValue + focusedSceneValue")
                                .focusedValue(\.pr27StringValue)
                                .focusedValue(\.pr27IntValue, 12)
                                .focusedSceneValue(\.pr27StringValue)
                                .focusedSceneValue(\.pr27IntValue, 34)
                                .focusedObject(focusObject)
                                .focusedSceneObject(focusObject)

                            Text("scrollPosition(ScrollPosition)")
                                .scrollPosition($scrollPosition, anchor: .center)
                            Text("scrollPosition(id:)")
                                .scrollPosition(id: $scrollID, anchor: .bottom)

                            Text("defaultScrollAnchor")
                                .defaultScrollAnchor(.topLeading)
                                .defaultScrollAnchor(.center, for: .content)
                        }
                    }
                }

                VStack(spacing: 12) {
                    PR27CoverageRow("Phase6: metadata modifiers") {
                        VStack(spacing: 8) {
                            VStack(spacing: 8) {
                                Text("navigationBarItems leading")
                                    .navigationBarItems(leading: Text("L"))
                                Text("navigationBarItems trailing")
                                    .navigationBarItems(trailing: Text("T"))
                                Text("navigationBarItems leading+trailing")
                                    .navigationBarItems(leading: Text("L"), trailing: Text("T"))
                                Text("sensoryFeedback basic")
                                    .sensoryFeedback(.success, trigger: sensoryTrigger)
                                Text("sensoryFeedback condition")
                                    .sensoryFeedback(.warning, trigger: sensoryTrigger) { old, new in old != new }
                                Text("sensoryFeedback dynamic")
                                    .sensoryFeedback(trigger: sensoryTrigger) { old, new in
                                        old == new ? nil : .impact
                                    }
                                Text("coordinateSpace enum")
                                    .coordinateSpace(.named("pr27-space"))
                                Text("coordinateSpace(name:)")
                                    .coordinateSpace(name: "pr27-space-2")
                            }

                            VStack(spacing: 8) {
                                Text("inspectorColumnWidth")
                                    .inspectorColumnWidth(220)
                                Text("inspectorColumnWidth min/ideal/max")
                                    .inspectorColumnWidth(min: 140, ideal: 220, max: 320)
                                Text("matchedTransitionSource id/in")
                                    .matchedTransitionSource(id: "avatar", in: "ns")
                                Text("matchedTransitionSource with configuration")
                                    .matchedTransitionSource(id: "badge", in: "ns", configuration: "config")
                                Text("onDrag")
                                    .onDrag { "drag-text" }
                                Text("onDrag + preview")
                                    .onDrag({ "drag-preview" }) { Text("Preview") }
                                Text("onLongPressGesture perform/onPressingChanged")
                                    .onLongPressGesture(
                                        minimumDuration: 0.1,
                                        maximumDistance: 20,
                                        perform: { parityMessage = "Long press action" },
                                        onPressingChanged: { _ in }
                                    )
                                Text("onLongPressGesture pressing/perform")
                                    .onLongPressGesture(
                                        minimumDuration: 0.1,
                                        maximumDistance: 20,
                                        pressing: { _ in },
                                        perform: { parityMessage = "Long press second action" }
                                    )
                            }

                            VStack(spacing: 8) {
                                Text("presentationCompactAdaptation single")
                                    .presentationCompactAdaptation(.popover)
                                Text("presentationCompactAdaptation h/v")
                                    .presentationCompactAdaptation(horizontal: .sheet, vertical: .fullScreenCover)
                                Text("scenePadding")
                                    .scenePadding(6)
                                Text("scenePadding edges")
                                    .scenePadding(4, edges: [.top, .leading])
                                Text("scrollIndicatorsFlash onAppear")
                                    .scrollIndicatorsFlash(onAppear: true)
                                Text("scrollIndicatorsFlash trigger")
                                    .scrollIndicatorsFlash(trigger: symbolTrigger)
                                Text("symbolEffect isActive")
                                    .symbolEffect(.pulse, options: [.repeating], isActive: true)
                                Text("symbolEffect value")
                                    .symbolEffect(.bounce, options: [.nonRepeating], value: symbolTrigger)
                                Text("tabViewBottomAccessory")
                                    .tabViewBottomAccessory { Text("Accessory") }
                                Text("tabViewBottomAccessory enabled")
                                    .tabViewBottomAccessory(isEnabled: true) { Text("Accessory Enabled") }
                            }

                            VStack(spacing: 8) {
                                Text("userActivity element/update")
                                    .userActivity("com.raven.pr27.element", element: userActivityCounter) { element in
                                        element += 1
                                    }
                                Text("userActivity active/update")
                                    .userActivity("com.raven.pr27.active", isActive: true) {
                                        userActivityCounter += 1
                                    }
                            }
                        }
                    }

                    PR27CoverageRow("Accessibility overloads + advanced modifiers") {
                        VStack(spacing: 8) {
                            VStack(spacing: 8) {
                                Text("accessibility(activationPoint:)")
                                    .accessibility(activationPoint: .center)
                                Text("accessibility(addTraits:)")
                                    .accessibility(addTraits: .isButton)
                                Text("accessibility(hidden:)")
                                    .accessibility(hidden: false)
                                Text("accessibility(hint:)")
                                    .accessibility(hint: Text("Hint text"))
                                Text("accessibility(identifier:)")
                                    .accessibility(identifier: "pr27.identifier")
                                Text("accessibility(inputLabels:)")
                                    .accessibility(inputLabels: [Text("First"), Text("Second")])
                                Text("accessibility(label:)")
                                    .accessibility(label: Text("Label value"))
                                Text("accessibility(removeTraits:)")
                                    .accessibility(removeTraits: .isSelected)
                                Text("accessibility(selectionIdentifier:)")
                                    .accessibility(selectionIdentifier: "selection-1")
                                Text("accessibility(sortPriority:)")
                                    .accessibility(sortPriority: 2.0)
                            }

                            VStack(spacing: 8) {
                                Text("accessibility(value:)")
                                    .accessibility(value: Text("Current value"))
                                Text("accessibilityActions(_)")
                                    .accessibilityActions { parityMessage = "accessibilityActions closure" }
                                Text("accessibilityActions(category:_)")
                                    .accessibilityActions(category: .default) { parityMessage = "accessibilityActions category closure" }
                                Text("accessibilityActivationPoint(_)")
                                    .accessibilityActivationPoint(.bottomTrailing)
                                Text("accessibilityActivationPoint(_:isEnabled:)")
                                    .accessibilityActivationPoint(.topLeading, isEnabled: true)
                                Text("accessibilityAddTraits")
                                    .accessibilityAddTraits(.isHeader)
                                Text("accessibilityAdjustableAction")
                                    .accessibilityAdjustableAction { _ in }
                                Text("accessibilityChartDescriptor")
                                    .accessibilityChartDescriptor { nil }
                                Text("accessibilityChildren(children:)")
                                    .accessibilityChildren(children: .contain)
                                Text("accessibilityCustomContent")
                                    .accessibilityCustomContent(Text("Priority"), Text("High"), importance: .high)
                            }

                            VStack(spacing: 8) {
                                Text("accessibilityDefaultFocus")
                                    .accessibilityDefaultFocus(true, "namespace")
                                Text("accessibilityDirectTouch")
                                    .accessibilityDirectTouch(true, options: [.silentOnTouch])
                                Text("accessibilityElement(children:)")
                                    .accessibilityElement(children: .combine)
                                Text("accessibilityFocused(_:) bool")
                                    .accessibilityFocused($focusFlag)
                                Text("accessibilityFocused(_:equals:)")
                                    .accessibilityFocused($focusSelection, equals: "alpha")
                                Text("accessibilityIgnoresInvertColors")
                                    .accessibilityIgnoresInvertColors()
                                Text("accessibilityInputLabels(_)")
                                    .accessibilityInputLabels([Text("Label A"), Text("Label B")])
                                Text("accessibilityInputLabels(_:isEnabled:)")
                                    .accessibilityInputLabels([Text("Label C")], isEnabled: true)
                                Text("accessibilityLabeledPair")
                                    .accessibilityLabeledPair(role: .content, id: "pair-id", in: "pair-ns")
                                Text("accessibilityLinkedGroup")
                                    .accessibilityLinkedGroup(id: "linked-id", in: "linked-ns")
                            }

                            VStack(spacing: 8) {
                                Text("accessibilityRemoveTraits")
                                    .accessibilityRemoveTraits(.isLink)
                                Text("accessibilityRepresentation")
                                    .accessibilityRepresentation { Text("Represented content") }
                                Text("accessibilityRespondsToUserInteraction")
                                    .accessibilityRespondsToUserInteraction(true)
                                Text("accessibilityRespondsToUserInteraction(_:isEnabled:)")
                                    .accessibilityRespondsToUserInteraction(true, isEnabled: true)
                                Text("accessibilityRotor entries")
                                    .accessibilityRotor(Text("Rotor Entries"), entries: rotorEntries)
                                Text("accessibilityRotor entries with id+label")
                                    .accessibilityRotor(Text("Rotor Entries ID"), entries: rotorEntries, entryID: \.id, entryLabel: \.label)
                                Text("accessibilityRotor entries with label")
                                    .accessibilityRotor(Text("Rotor Entries Label"), entries: rotorEntries, entryLabel: \.label)
                                Text("accessibilityRotor textRanges")
                                    .accessibilityRotor(Text("Rotor Text Ranges"), textRanges: rotorRanges)
                                Text("accessibilityRotorEntry")
                                    .accessibilityRotorEntry(id: "rotor-id", in: "rotor-ns")
                                Text("accessibilityScrollAction")
                                    .accessibilityScrollAction { _ in }
                            }

                            VStack(spacing: 8) {
                                Text("accessibilityScrollStatus")
                                    .accessibilityScrollStatus(Text("Scroll status"), isEnabled: true)
                                Text("accessibilityShowsLargeContentViewer()")
                                    .accessibilityShowsLargeContentViewer()
                                Text("accessibilityShowsLargeContentViewer(_:)")
                                    .accessibilityShowsLargeContentViewer(false)
                                Text("accessibilitySortPriority")
                                    .accessibilitySortPriority(5)
                                Text("accessibilityTextContentType")
                                    .accessibilityTextContentType(.sourceCode)
                                Text("accessibilityZoomAction")
                                    .accessibilityZoomAction { _ in }
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Button("Bump Sensory Trigger") { sensoryTrigger += 1 }
                        Button("Bump Symbol Trigger") { symbolTrigger += 1 }
                    }
                    .buttonStyle(.bordered)

                    Text(parityMessage)
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }
            }
        }
    }
}
