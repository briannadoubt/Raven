import Foundation

@MainActor
struct ActionSheetModifier: ViewModifier {
    @Environment(\.presentationCoordinator) private var coordinator

    @Binding var isPresented: Bool
    let makeActionSheet: @MainActor @Sendable () -> ActionSheet

    @State private var presentationId: UUID?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    presentActionSheet()
                } else {
                    dismissPresentation()
                }
            }
    }

    private func presentActionSheet() {
        if let existingId = presentationId {
            coordinator.dismiss(existingId)
            presentationId = nil
        }
        let sheet = makeActionSheet()
        let dialogContent = VStack(spacing: 12) {
            sheet.title
            if let message = sheet.message {
                message
            }
            ForEach(sheet.buttons) { button in
                actionButton(for: button)
            }
        }

        let id = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(dialogContent),
            onDismiss: { @MainActor in
                isPresented = false
                presentationId = nil
            }
        )
        presentationId = id
    }

    private func dismissPresentation() {
        guard let id = presentationId else { return }
        coordinator.dismiss(id)
        presentationId = nil
    }

    private func actionButton(for button: ActionSheet.Button) -> some View {
        Button(button.label.textContent, role: button.role) {
            button.action?()
            isPresented = false
            dismissPresentation()
        }
    }
}

@MainActor
struct ActionSheetItemModifier<Item: Identifiable & Sendable>: ViewModifier where Item.ID: Sendable {
    @Environment(\.presentationCoordinator) private var coordinator

    @Binding var item: Item?
    let makeActionSheet: @MainActor @Sendable (Item) -> ActionSheet

    @State private var presentationId: UUID?

    func body(content: Content) -> some View {
        content
            .onChange(of: item?.id) { _ in
                if let current = item {
                    presentActionSheet(for: current)
                } else {
                    dismissPresentation()
                }
            }
    }

    private func presentActionSheet(for item: Item) {
        if let existingId = presentationId {
            coordinator.dismiss(existingId)
            presentationId = nil
        }
        let sheet = makeActionSheet(item)
        let dialogContent = VStack(spacing: 12) {
            sheet.title
            if let message = sheet.message {
                message
            }
            ForEach(sheet.buttons) { button in
                actionButton(for: button)
            }
        }

        let id = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(dialogContent),
            onDismiss: { @MainActor in
                self.item = nil
                presentationId = nil
            }
        )
        presentationId = id
    }

    private func dismissPresentation() {
        guard let id = presentationId else { return }
        coordinator.dismiss(id)
        presentationId = nil
    }

    private func actionButton(for button: ActionSheet.Button) -> some View {
        Button(button.label.textContent, role: button.role) {
            button.action?()
            item = nil
            dismissPresentation()
        }
    }
}
