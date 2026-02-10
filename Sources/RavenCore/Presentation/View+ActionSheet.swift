import Foundation

extension View {
    /// Presents an action sheet when a binding to a Boolean value is true.
    ///
    /// The content closure returns an ``ActionSheet`` describing the title,
    /// optional message, and buttons.
    @MainActor
    public func actionSheet(
        isPresented: Binding<Bool>,
        content: @escaping @MainActor @Sendable () -> ActionSheet
    ) -> some View {
        modifier(ActionSheetModifier(
            isPresented: isPresented,
            makeActionSheet: content
        ))
    }

    /// Presents an action sheet when an identifiable item is non-nil.
    ///
    /// The item is passed into the content closure to build the action sheet.
    @MainActor
    public func actionSheet<Item: Identifiable & Sendable>(
        item: Binding<Item?>,
        content: @escaping @MainActor @Sendable (Item) -> ActionSheet
    ) -> some View where Item.ID: Sendable {
        modifier(ActionSheetItemModifier(
            item: item,
            makeActionSheet: content
        ))
    }
}
