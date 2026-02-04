# Views API

Core view components for building UIs in Raven.

## Text

Display text content with customizable styling.

```swift
public struct Text: View {
    /// Creates a text view displaying a string
    public init(_ content: String)

    /// Creates a text view from a localized string key
    public init(_ key: LocalizedStringKey)
}
```

### Modifiers

```swift
extension Text {
    /// Sets the font
    func font(_ font: Font) -> Text

    /// Sets the text color
    func foregroundColor(_ color: Color) -> Text

    /// Sets the font weight
    func fontWeight(_ weight: Font.Weight) -> Text

    /// Sets whether text should be bold
    func bold() -> Text

    /// Sets whether text should be italic
    func italic() -> Text

    /// Adds strikethrough styling
    func strikethrough(_ active: Bool = true, color: Color? = nil) -> Text

    /// Adds underline styling
    func underline(_ active: Bool = true, color: Color? = nil) -> Text
}
```

### Example

```swift
Text("Hello, World!")
    .font(.title)
    .fontWeight(.bold)
    .foregroundColor(.blue)
```

---

## Image

Display images from various sources.

```swift
public struct Image: View {
    /// Creates an image from a system symbol name
    public init(systemName: String)

    /// Creates an image from a named resource
    public init(_ name: String)

    /// Creates an image from a URL
    public init(url: String)
}
```

### Modifiers

```swift
extension Image {
    /// Sets how the image should be resized
    func resizable() -> Image

    /// Sets the aspect ratio mode
    func aspectRatio(_ ratio: CGFloat?, contentMode: ContentMode) -> Image

    /// Sets the rendering mode (template or original)
    func renderingMode(_ mode: Image.TemplateRenderingMode) -> Image
}
```

### Example

```swift
Image(systemName: "star.fill")
    .foregroundColor(.yellow)
    .font(.largeTitle)

Image(url: "https://example.com/image.png")
    .resizable()
    .aspectRatio(16/9, contentMode: .fit)
    .frame(width: 300)
```

---

## Button

An interactive button that triggers an action.

```swift
public struct Button<Label: View>: View {
    /// Creates a button with a text label
    public init(
        _ titleKey: String,
        action: @escaping () -> Void
    )

    /// Creates a button with a custom label
    public init(
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    )
}
```

### Button Styles

```swift
enum ButtonStyle {
    case automatic
    case plain
    case bordered
    case borderedProminent
    case borderless
}

extension View {
    func buttonStyle(_ style: ButtonStyle) -> some View
}
```

### Example

```swift
Button("Click Me") {
    print("Button clicked!")
}
.buttonStyle(.bordered)

Button(action: submit) {
    HStack {
        Image(systemName: "paperplane.fill")
        Text("Send")
    }
}
.buttonStyle(.borderedProminent)
```

---

## Toggle

A control that toggles between on and off states.

```swift
public struct Toggle: View {
    /// Creates a toggle with a text label
    public init(
        _ titleKey: String,
        isOn: Binding<Bool>
    )

    /// Creates a toggle with a custom label
    public init(
        isOn: Binding<Bool>,
        @ViewBuilder label: () -> Label
    )
}
```

### Example

```swift
@State private var isEnabled = false

Toggle("Enable notifications", isOn: $isEnabled)

Toggle(isOn: $isEnabled) {
    HStack {
        Image(systemName: "bell.fill")
        Text("Notifications")
    }
}
```

---

## TextField

A control for entering and editing text.

```swift
public struct TextField: View {
    /// Creates a text field with a placeholder
    public init(
        _ placeholder: String,
        text: Binding<String>
    )
}
```

### Modifiers

```swift
extension View {
    /// Sets the keyboard type
    func keyboardType(_ type: UIKeyboardType) -> some View

    /// Sets autocapitalization
    func textInputAutocapitalization(_ style: TextInputAutocapitalization) -> some View

    /// Disables autocorrection
    func autocorrectionDisabled(_ disabled: Bool = true) -> some View

    /// Called when user presses return/enter
    func onSubmit(of triggers: SubmitTriggers = .text, _ action: @escaping () -> Void) -> some View
}
```

### Example

```swift
@State private var email = ""
@State private var password = ""

VStack {
    TextField("Email", text: $email)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()

    SecureField("Password", text: $password)
        .onSubmit {
            login()
        }
}
```

---

## SecureField

A text field that obscures the entered text (for passwords).

```swift
public struct SecureField: View {
    /// Creates a secure field with a placeholder
    public init(
        _ placeholder: String,
        text: Binding<String>
    )
}
```

### Example

```swift
@State private var password = ""

SecureField("Password", text: $password)
    .textFieldStyle(.roundedBorder)
```

---

## Picker

A control for selecting from a set of mutually exclusive values.

```swift
public struct Picker<SelectionValue, Label, Content>: View
    where SelectionValue: Hashable, Label: View, Content: View
{
    /// Creates a picker with a selection binding
    public init(
        _ titleKey: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    )
}
```

### Picker Styles

```swift
enum PickerStyle {
    case automatic
    case menu
    case segmented
    case wheel
}

extension View {
    func pickerStyle(_ style: PickerStyle) -> some View
}
```

### Example

```swift
@State private var selectedColor = "Red"

Picker("Color", selection: $selectedColor) {
    Text("Red").tag("Red")
    Text("Green").tag("Green")
    Text("Blue").tag("Blue")
}
.pickerStyle(.segmented)
```

---

## DatePicker

A control for selecting dates and times.

```swift
public struct DatePicker: View {
    /// Creates a date picker
    public init(
        _ titleKey: String,
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = [.date, .hourAndMinute]
    )

    /// Creates a date picker with a range
    public init(
        _ titleKey: String,
        selection: Binding<Date>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePickerComponents = [.date, .hourAndMinute]
    )
}
```

### Example

```swift
@State private var selectedDate = Date()

DatePicker(
    "Event Date",
    selection: $selectedDate,
    displayedComponents: [.date]
)
```

---

## ColorPicker

A control for selecting colors.

```swift
public struct ColorPicker: View {
    /// Creates a color picker
    public init(
        _ titleKey: String,
        selection: Binding<Color>
    )
}
```

### Example

```swift
@State private var selectedColor = Color.blue

ColorPicker("Choose a color", selection: $selectedColor)
```

---

## Slider

A control for selecting a value from a bounded linear range.

```swift
public struct Slider<Value: BinaryFloatingPoint>: View {
    /// Creates a slider
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        step: Value.Stride = 1
    )
}
```

### Example

```swift
@State private var volume: Double = 0.5

VStack {
    Slider(value: $volume, in: 0...1, step: 0.1)
    Text("Volume: \(Int(volume * 100))%")
}
```

---

## Stepper

A control for incrementing or decrementing a value.

```swift
public struct Stepper: View {
    /// Creates a stepper
    public init(
        _ titleKey: String,
        value: Binding<Int>,
        in bounds: ClosedRange<Int>
    )
}
```

### Example

```swift
@State private var quantity = 1

Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
```

---

## ProgressView

A view that shows progress toward completion of a task.

```swift
public struct ProgressView: View {
    /// Creates an indeterminate progress view
    public init()

    /// Creates a determinate progress view
    public init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0)
}
```

### Example

```swift
// Indeterminate
ProgressView()

// Determinate
@State private var progress = 0.7

ProgressView(value: progress)
    .progressViewStyle(.linear)
```

---

## Link

A control that navigates to a URL.

```swift
public struct Link<Label: View>: View {
    /// Creates a link with a text label
    public init(
        _ titleKey: String,
        destination: URL
    )

    /// Creates a link with a custom label
    public init(
        destination: URL,
        @ViewBuilder label: () -> Label
    )
}
```

### Example

```swift
Link("Visit our website", destination: URL(string: "https://example.com")!)

Link(destination: URL(string: "https://github.com")!) {
    HStack {
        Image(systemName: "link")
        Text("GitHub")
    }
}
```

---

## Common View Modifiers

All views inherit these modifiers:

```swift
extension View {
    /// Sets the frame
    func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View

    /// Sets padding
    func padding(_ length: CGFloat? = nil) -> some View
    func padding(_ edges: Edge.Set, _ length: CGFloat? = nil) -> some View

    /// Sets background
    func background<S: ShapeStyle>(_ style: S) -> some View

    /// Sets corner radius
    func cornerRadius(_ radius: CGFloat) -> some View

    /// Sets opacity
    func opacity(_ opacity: Double) -> some View

    /// Hides the view
    func hidden() -> some View

    /// Disables user interaction
    func disabled(_ disabled: Bool) -> some View
}
```

---

*See also: [Layout](./Layout.md), [Modifiers](./Modifiers.md), [State](./State.md)*
