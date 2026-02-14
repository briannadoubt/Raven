# Selected SwiftUI Parity Updates

Generated on 2026-02-14.

Selected APIs implemented in this pass (previously missing in Raven):

- TableColumnBuilder (result builder)
- TableRowBuilder (result builder)
- TableColumnBuilder.buildExpression
- TableColumnBuilder.buildBlock overloads (1...10)
- TableColumnBuilder.buildEither (first/second)
- TableColumnBuilder.buildIf
- TableColumnBuilder.buildLimitedAvailability
- TableRowBuilder.buildExpression
- TableRowBuilder.buildBlock overloads (1...10)
- TableRowBuilder.buildEither (first/second)
- TableRowBuilder.buildIf
- TableRowBuilder.buildLimitedAvailability

- LabelStyle (protocol + configuration)
- LabelStyle.default (DefaultLabelStyle)
- LabelStyle.iconOnly (IconOnlyLabelStyle)
- LabelStyle.titleOnly (TitleOnlyLabelStyle)
- LabelStyle.titleAndIcon (TitleAndIconLabelStyle)
- LabelStyle.automatic (AutomaticLabelStyle)
- ProgressViewStyle (protocol + configuration)
- ProgressViewStyle.default (DefaultProgressViewStyle)
- ProgressViewStyle.circular (CircularProgressViewStyle)
- ProgressViewStyle.linear (LinearProgressViewStyle)
- ProgressViewStyle.automatic (AutomaticProgressViewStyle)
- GroupBoxStyle (protocol + configuration)
- GroupBoxStyle.default (DefaultGroupBoxStyle)
- GroupBoxStyle.automatic (AutomaticGroupBoxStyle)
- ListStyle (protocol)
- ListStyle.automatic (AutomaticListStyle)
- ListStyle.default (DefaultListStyle)
- ListStyle.plain (PlainListStyle)
- ListStyle.grouped (GroupedListStyle)
- ListStyle.inset (InsetListStyle)
- ListStyle.insetGrouped (InsetGroupedListStyle)
- ListStyle.sidebar (SidebarListStyle)
- NavigationViewStyle (protocol + configuration)
- NavigationViewStyle.automatic (AutomaticNavigationViewStyle)
- NavigationViewStyle.default (DefaultNavigationViewStyle)
- NavigationViewStyle.stack (StackNavigationViewStyle)
- NavigationViewStyle.doubleColumn (DoubleColumnNavigationViewStyle)
- NavigationViewStyle.columns (ColumnNavigationViewStyle)

Validation target:

- Example app: Examples/TodoApp
- Demo sections: Forms -> LabelStyle, ProgressViewStyle, GroupBoxStyle, ListStyle
- Visual checks: light mode + dark mode in browser

## 2026-02-14 parity pass

Comprehensive SwiftUI component inventory for this repo snapshot:
- `Reports/swiftui-api-gap/swiftui_components_complete.md` (401 top-level SwiftUI components)

Selected APIs implemented in this pass (previously missing in Raven):
- WheelDatePickerStyle
- DatePickerStyle.wheel
- TabBarPlacement
- TabBarOnlyTabViewStyle
- SidebarAdaptableTabViewStyle
- TabViewStyle.tabBarOnly
- TabViewStyle.sidebarAdaptable
- View.defaultAdaptableTabBarPlacement(_:)
- AdaptableTabBarPlacement.automatic
- AdaptableTabBarPlacement.topBar
- AdaptableTabBarPlacement.bottomBar

Demo coverage added:
- `Examples/TodoApp/Sources/TodoApp/ContentView.swift`
- Forms -> `DatePickerStyle` section now includes `.wheel`
- Forms -> new `TabViewStyle (Adaptable)` section validates top and bottom bar placement behavior
