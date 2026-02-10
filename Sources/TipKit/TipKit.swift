import Foundation
import RavenCore

// MARK: - Stable Type Names (SwiftWasm)

/// SwiftWasm can include unstable "(unknown context at $...)" segments in `String(reflecting:)`
/// for nested/local types. TipKit uses type names as stable identifiers, so we strip these
/// segments to keep persistence keys stable across runs.
fileprivate enum _TipKitTypeName {
    static func stable(_ type: Any.Type) -> String {
        // Example unstable string: "TodoApp.(unknown context at $672f0)._WelcomeTip"
        // Desired stable string:    "TodoApp._WelcomeTip"
        var s = String(reflecting: type)
        while let start = s.range(of: ".(unknown context at $") {
            guard let end = s[start.lowerBound...].firstIndex(of: ")") else { break }
            // Remove from the preceding "." up to and including ")"
            s.removeSubrange(start.lowerBound...end)
        }
        return s
    }
}

// MARK: - TipOption

public protocol TipOption: Sendable {}

// MARK: - Tip

@_typeEraser(AnyTip)
public protocol Tip: Identifiable, Sendable {
    var id: String { get }
    var title: Text { get }
    var message: Text? { get }
    var image: Image? { get }

    @Tips.ActionBuilder var actions: [Self.Action] { get }
    @Tips.RuleBuilder var rules: [Self.Rule] { get }
    @Tips.OptionsBuilder var options: [any TipOption] { get }
}

extension Tip {
    public typealias Status = Tips.Status
    public typealias InvalidationReason = Tips.InvalidationReason
    public typealias Action = Tips.Action
    public typealias Rule = Tips.Rule
    public typealias Event = Tips.Event
    public typealias Option = TipOption

    public var id: String { _TipKitTypeName.stable(Self.self) }
    public var message: Text? { nil }
    public var image: Image? { nil }
    public var actions: [Self.Action] { [] }
    public var rules: [Self.Rule] { [] }
    public var options: [any TipOption] { [] }
}

// MARK: - Tip State / Eligibility

extension Tip {
    @MainActor
    public var status: Self.Status { Tips._shared.status(for: id, rules: rules) }
    @MainActor
    public var shouldDisplay: Bool { status == .available }

    @MainActor
    public var statusUpdates: AsyncStream<Self.Status> {
        Tips._shared.statusUpdates(for: id, rules: rules)
    }

    @MainActor
    public var shouldDisplayUpdates: AsyncMapSequence<AsyncStream<Self.Status>, Bool> {
        statusUpdates.map { $0 == .available }
    }

    @MainActor
    public func invalidate(reason: Self.InvalidationReason) {
        Tips._shared.invalidate(tipID: id, reason: reason)
    }

    @MainActor
    public func resetEligibility() {
        Tips._shared.resetEligibility(tipID: id)
    }

    // Keep the async shape for parity with TipKit callers that use `await`,
    // but avoid forcing async-only usage in Raven (where button actions are sync).
    @MainActor
    public func resetEligibility() async {
        Tips._shared.resetEligibility(tipID: id)
    }
}

// MARK: - AnyTip

public struct AnyTip: Tip {
    private let _id: String
    private let _title: Text
    private let _message: Text?
    private let _image: Image?
    private let _actions: [Tips.Action]
    private let _rules: [Tips.Rule]
    private let storedOptions: [any TipOption]

    public init<T: Tip>(erasing tip: T) {
        self._id = tip.id
        self._title = tip.title
        self._message = tip.message
        self._image = tip.image
        self._actions = tip.actions
        self._rules = tip.rules
        self.storedOptions = tip.options
    }

    public init(_ tip: any Tip) {
        self._id = tip.id
        self._title = tip.title
        self._message = tip.message
        self._image = tip.image
        self._actions = tip.actions
        self._rules = tip.rules
        self.storedOptions = tip.options
    }

    public var id: String { _id }
    public var title: Text { _title }
    public var message: Text? { _message }
    public var image: Image? { _image }
    @Tips.ActionBuilder public var actions: [Tips.Action] { _actions }
    @Tips.RuleBuilder public var rules: [Tips.Rule] { _rules }
    @Tips.OptionsBuilder public var options: [any TipOption] {
        // TODO: Forwarding `TipOption`s through a type-erased wrapper needs a
        // builder shape that Swift accepts for protocol requirements.
    }
}

// MARK: - Tips Namespace

@frozen
public enum Tips {
    // MARK: Configuration
    public struct ConfigurationOption: Sendable {
        public init() {}
    }

    public static func configure(_ configuration: [ConfigurationOption] = []) throws {
        // Raven shim: configuration is currently a no-op.
        _ = configuration
    }

    // MARK: Status / Invalidation
    public enum Status: Hashable, Codable, Sendable {
        case pending
        case available
        case invalidated(InvalidationReason)
    }

    public enum InvalidationReason: String, Hashable, Codable, Sendable {
        case actionPerformed
        case displayCountExceeded
        case displayDurationExceeded
        case tipClosed
    }

    /// Internal helper to let type-erased tips forward `[any TipOption]` through
    /// the `@OptionsBuilder` requirement (which expects concrete `TipOption`s).
    public struct _OptionList: TipOption, Sendable {
        public let options: [any TipOption]
        public init(_ options: [any TipOption]) { self.options = options }
    }

    // MARK: Action
    public struct Action: Identifiable, @unchecked Sendable {
        public let id: String
        public let index: Int?
        public let label: @Sendable () -> Text
        public let handler: @Sendable @MainActor () -> Void

        public init(
            id: String? = nil,
            perform handler: @escaping @Sendable @MainActor () -> Void = {},
            _ label: @escaping @Sendable () -> Text
        ) {
            self.id = id ?? UUID().uuidString
            self.index = nil
            self.label = label
            self.handler = handler
        }

        public init(
            id: String? = nil,
            title: some StringProtocol,
            perform handler: @escaping @Sendable @MainActor () -> Void = {}
        ) {
            let titleString = String(title)
            self.id = id ?? UUID().uuidString
            self.index = nil
            self.label = { Text(titleString) }
            self.handler = handler
        }

        internal func with(index: Int) -> Action {
            Action(id: id, index: index, label: label, handler: handler)
        }

        private init(
            id: String,
            index: Int?,
            label: @escaping @Sendable () -> Text,
            handler: @escaping @Sendable @MainActor () -> Void
        ) {
            self.id = id
            self.index = index
            self.label = label
            self.handler = handler
        }
    }

    // MARK: Rule Inputs
    public protocol RuleInput: Sendable {
        associatedtype Value
        @MainActor var value: Value { get }
    }

    // MARK: Rule
    public struct Rule: Sendable {
        fileprivate let evaluate: @Sendable @MainActor () -> Bool

        public init(_ evaluate: @escaping @Sendable @MainActor () -> Bool) {
            self.evaluate = evaluate
        }

        public init<each Input>(
            _ input: repeat each Input,
            body: @escaping @Sendable @MainActor (repeat (each Input).Value) -> Bool
        ) where repeat each Input: RuleInput {
            self.evaluate = { @MainActor in
                body(repeat (each input).value)
            }
        }
    }

    // MARK: Parameter
    public struct ParameterOption: Hashable, Codable, Sendable {
        fileprivate let isTransient: Bool

        public init(isTransient: Bool = false) {
            self.isTransient = isTransient
        }

        public static var transient: ParameterOption { ParameterOption(isTransient: true) }
    }

    public struct Parameter<Value>: Identifiable, Sendable where Value: Codable & Sendable {
        public typealias ID = String

        private final class Storage: @unchecked Sendable {
            let id: String
            let key: String
            let transient: Bool

            var value: Value
            var readerComponentPaths: Set<String> = []

            init(id: String, key: String, initialValue: Value, transient: Bool) {
                self.id = id
                self.key = key
                self.transient = transient
                self.value = initialValue
                if !transient, let loaded: Value = TipsDatastore.loadValue(key: key) {
                    self.value = loaded
                }
            }
        }

        private let storage: Storage

        public var id: String { storage.id }

        public var wrappedValue: Value {
            get {
                // Reads commonly happen on MainActor during rendering, but we keep this
                // accessor nonisolated so `@Parameter` can synthesize nonisolated accessors.
                Task { @MainActor in
                    if let path = _RenderScheduler.currentComponentPath {
                        storage.readerComponentPaths.insert(path)
                    }
                }
                return storage.value
            }
            nonmutating set {
                storage.value = newValue
                if !storage.transient {
                    TipsDatastore.saveValue(newValue, key: storage.key)
                }
                let paths = storage.readerComponentPaths
                Task { @MainActor in
                    Tips._shared.markReadersDirty(paths)
                }
            }
        }

        public var value: Value { wrappedValue }

        public init(
            _ enclosingInstance: (some Any).Type,
            _ name: String,
            _ initialValue: Value,
            _ options: ParameterOption...
        ) {
            let isTransient = options.contains(where: { $0.isTransient })
            let id = "\(_TipKitTypeName.stable(enclosingInstance)).\(name)"
            let key = "raven.tipkit.parameter.\(id)"
            self.storage = Storage(id: id, key: key, initialValue: initialValue, transient: isTransient)
        }

        public init<T>(_ keyPath: KeyPath<T, Value>, _ initialValue: Value, _ options: ParameterOption...) {
            let isTransient = options.contains(where: { $0.isTransient })
            let id = "\(_TipKitTypeName.stable(T.self)).\(String(describing: keyPath))"
            let key = "raven.tipkit.parameter.\(id)"
            self.storage = Storage(id: id, key: key, initialValue: initialValue, transient: isTransient)
        }
    }

    // MARK: Event
    public struct EmptyDonation: Codable, Sendable {
        public init() {}
    }

    public struct Event<DonationInfo>: Identifiable, Sendable where DonationInfo: Codable & Sendable {
        public typealias ID = String

        public struct Donation: Codable, Sendable {
            public let date: Date
            public let info: DonationInfo

            public init(date: Date = Date(), info: DonationInfo) {
                self.date = date
                self.info = info
            }
        }

        private final class Storage: @unchecked Sendable {
            let id: String
            let key: String

            var donations: [Donation] = []
            var readerComponentPaths: Set<String> = []

            init(id: String, key: String) {
                self.id = id
                self.key = key
                if let loaded: [Donation] = TipsDatastore.loadValue(key: key) {
                    self.donations = loaded
                }
            }
        }

        private let storage: Storage

        public var id: String { storage.id }

        public var donations: [Donation] {
            Task { @MainActor in
                if let path = _RenderScheduler.currentComponentPath {
                    storage.readerComponentPaths.insert(path)
                }
            }
            return storage.donations
        }

        public init(id: String) {
            let key = "raven.tipkit.event.\(id)"
            self.storage = Storage(id: id, key: key)
        }

        public func donate() async where DonationInfo == EmptyDonation {
            await donate(EmptyDonation())
        }

        public func donate(_ donation: DonationInfo) async {
            await MainActor.run {
                storage.donations.append(Donation(info: donation))
                TipsDatastore.saveValue(storage.donations, key: storage.key)
                Tips._shared.markReadersDirty(storage.readerComponentPaths)
            }
        }

        public var value: Event<DonationInfo> { self }
    }
}

extension Tips.Parameter: Tips.RuleInput {
    public typealias Value = Value
}

extension Tips.Event: Tips.RuleInput {
    public typealias Value = Tips.Event<DonationInfo>
}

// MARK: - Builders

extension Tips {
    @_documentation(visibility: private)
    @resultBuilder
    public struct ActionBuilder {
        public static func buildBlock() -> [Tips.Action] { [] }
        public static func buildExpression(_ element: Tips.Action) -> [Tips.Action] { [element] }
        public static func buildExpression(_ component: [Tips.Action]) -> [Tips.Action] { component }
        public static func buildPartialBlock(first: [Tips.Action]) -> [Tips.Action] { first }
        public static func buildPartialBlock(accumulated: [Tips.Action], next: [Tips.Action]) -> [Tips.Action] { accumulated + next }
        public static func buildArray(_ components: [[Tips.Action]]) -> [Tips.Action] { components.flatMap { $0 } }
        public static func buildEither(first component: [Tips.Action]) -> [Tips.Action] { component }
        public static func buildEither(second component: [Tips.Action]) -> [Tips.Action] { component }
        public static func buildLimitedAvailability(_ component: [Tips.Action]) -> [Tips.Action] { component }
    }

    @_documentation(visibility: private)
    @resultBuilder
    public struct RuleBuilder {
        public static func buildBlock() -> [Tips.Rule] { [] }
        public static func buildExpression(_ element: Tips.Rule) -> [Tips.Rule] { [element] }
        public static func buildExpression(_ component: [Tips.Rule]) -> [Tips.Rule] { component }
        public static func buildPartialBlock(first: [Tips.Rule]) -> [Tips.Rule] { first }
        public static func buildPartialBlock(accumulated: [Tips.Rule], next: [Tips.Rule]) -> [Tips.Rule] { accumulated + next }
        public static func buildArray(_ components: [[Tips.Rule]]) -> [Tips.Rule] { components.flatMap { $0 } }
        public static func buildEither(first component: [Tips.Rule]) -> [Tips.Rule] { component }
        public static func buildEither(second component: [Tips.Rule]) -> [Tips.Rule] { component }
        public static func buildLimitedAvailability(_ component: [Tips.Rule]) -> [Tips.Rule] { component }
    }

    @_documentation(visibility: private)
    @resultBuilder
    public struct OptionsBuilder {
        public static func buildBlock() -> [any TipOption] { [] }
        public static func buildExpression<T: TipOption>(_ element: T) -> [any TipOption] { [element] }
        public static func buildExpression(_ list: Tips._OptionList) -> [any TipOption] { list.options }
        public static func buildArray(_ components: [[any TipOption]]) -> [any TipOption] { components.flatMap { $0 } }
        public static func buildEither(first component: [any TipOption]) -> [any TipOption] { component }
        public static func buildEither(second component: [any TipOption]) -> [any TipOption] { component }
        public static func buildOptional(_ component: [any TipOption]?) -> [any TipOption] { component ?? [] }
    }
}

// MARK: - TipView

@MainActor
public struct TipView<Content>: View where Content: Tip {
    private let tip: (any Tip)?
    private let isPresented: Binding<Bool>?
    private let arrowEdge: Edge?
    private let action: @Sendable @MainActor (Tips.Action) -> Void

    public init(
        _ tip: Content,
        arrowEdge: Edge? = nil,
        action: @escaping @Sendable @MainActor (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip
        self.isPresented = nil
        self.arrowEdge = arrowEdge
        self.action = action
    }

    public var body: some View {
        if let tip, tip.shouldDisplay, (isPresented?.wrappedValue ?? true) {
            _TipCardView(tip: tip, action: action) { reason in
                tip.invalidate(reason: reason)
                isPresented?.wrappedValue = false
            }
        } else {
            EmptyView()
        }
    }
}

extension TipView where Content == AnyTip {
    public init(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        arrowEdge: Edge? = nil,
        action: @escaping @Sendable @MainActor (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip
        self.isPresented = isPresented
        self.arrowEdge = arrowEdge
        self.action = action
    }
}

@MainActor
private struct _TipCardView: View {
    let tip: any Tip
    let action: @Sendable @MainActor (Tips.Action) -> Void
    let onClose: @Sendable @MainActor (Tips.InvalidationReason) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                if let image = tip.image {
                    image
                        .frame(width: 20, height: 20)
                }
                tip.title
                    .font(.headline)
                Spacer()
                Button(action: {
                    onClose(.tipClosed)
                }) {
                    Text("x")
                }
                .buttonStyle(.borderless)
            }
            if let message = tip.message {
                message
                    .font(.subheadline)
            }
            if !tip.actions.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(tip.actions.enumerated()), id: \.offset) { idx, action in
                        Button(action: {
                            action.handler()
                            self.action(action.with(index: idx))
                            onClose(.actionPerformed)
                        }) {
                            action.label()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14, opacity: 0.96))
        .cornerRadius(10)
    }
}

// MARK: - View Modifiers

extension View {
    @preconcurrency
    public func popoverTip(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge? = nil,
        action: @escaping @Sendable @MainActor (Tips.Action) -> Void = { _ in }
    ) -> some View {
        _TipPopoverModifier(
            content: self,
            tip: tip,
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge,
            action: action
        )
    }

    @preconcurrency
    public func popoverTip(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdges: Edge.Set,
        action: @escaping @Sendable @MainActor (Tips.Action) -> Void = { _ in }
    ) -> some View {
        let edge = arrowEdges.contains(.top) ? Edge.top
            : arrowEdges.contains(.bottom) ? Edge.bottom
            : arrowEdges.contains(.leading) ? Edge.leading
            : arrowEdges.contains(.trailing) ? Edge.trailing
            : nil
        return popoverTip(
            tip,
            isPresented: isPresented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: edge,
            action: action
        )
    }
}

@MainActor
private struct _TipPopoverModifier<Content: View>: View {
    let content: Content
    let tip: (any Tip)?
    let isPresented: Binding<Bool>?
    let attachmentAnchor: PopoverAttachmentAnchor
    let arrowEdge: Edge?
    let action: @Sendable @MainActor (Tips.Action) -> Void

    var body: some View {
        let effectiveTip = tip
        // TipKit's implicit presentation is driven by eligibility. If the user supplies an `isPresented`
        // binding, treat it as an additional gate.
        let shouldShow = (effectiveTip?.shouldDisplay ?? false) && (isPresented?.wrappedValue ?? true)

        let presented = Binding<Bool>(
            get: { shouldShow },
            set: { newValue in
                isPresented?.wrappedValue = newValue
                // If the popover is dismissed by outside interaction (not via TipView's close/action),
                // we still need to invalidate it as "closed". Avoid overriding an existing invalidation
                // reason that TipView may have already recorded (e.g. `.actionPerformed`).
                if !newValue, let tip = effectiveTip {
                    if case .invalidated = tip.status {
                        // already invalidated
                    } else {
                        tip.invalidate(reason: .tipClosed)
                    }
                }
            }
        )

        return content.popover(
            isPresented: presented,
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge ?? .top
        ) {
            TipView<AnyTip>(effectiveTip, isPresented: presented, arrowEdge: arrowEdge, action: action)
        }
    }
}

private struct _EmptyTip: Tip {
    var title: Text { Text("") }
}

// MARK: - TipKit Macros

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`$`))
public macro Parameter(_ options: Tips.ParameterOption...) = #externalMacro(module: "TipKitMacros", type: "ParameterMacro")

@freestanding(expression)
public macro Rule<each Input>(
    _ input: repeat each Input,
    _ body: (repeat (each Input).Value) -> Bool
) -> Tips.Rule = #externalMacro(module: "TipKitMacros", type: "RuleMacro") where repeat each Input: Tips.RuleInput

// MARK: - Storage

fileprivate enum TipsDatastore {
    static func loadValue<T: Codable>(key: String) -> T? {
        #if arch(wasm32)
        // Keep this file WASM-friendly: TipKit is a shim module, so we only use
        // localStorage when present.
        if let raw = JSLocalStorage.getItem(key), let data = raw.data(using: .utf8) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
        #else
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
        #endif
    }

    static func saveValue<T: Codable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        #if arch(wasm32)
        let raw = String(data: data, encoding: .utf8) ?? ""
        JSLocalStorage.setItem(key, raw)
        #else
        UserDefaults.standard.set(data, forKey: key)
        #endif
    }
}

#if arch(wasm32)
import JavaScriptKit

fileprivate enum JSLocalStorage {
    static func getItem(_ key: String) -> String? {
        JSObject.global.window.object?.localStorage.object?.getItem?(key).string
    }

    static func setItem(_ key: String, _ value: String) {
        _ = JSObject.global.window.object?.localStorage.object?.setItem?(key, value)
    }
}
#endif

// MARK: - Internal Store

@MainActor
fileprivate final class _TipsSharedState: @unchecked Sendable {
    static let shared = _TipsSharedState()

    private struct TipState: Codable {
        var invalidatedReason: Tips.InvalidationReason?
    }

    private struct LiveState {
        var persisted: TipState
        var readerComponentPaths: Set<String> = []
        var streams: [UUID: (continuation: AsyncStream<Tips.Status>.Continuation, evaluator: @Sendable @MainActor () -> Tips.Status)] = [:]
    }

    private var states: [String: LiveState] = [:]

    func status(for tipID: String, rules: [Tips.Rule]) -> Tips.Status {
        let state = liveState(for: tipID)
        registerRead(tipID: tipID)
        if let reason = state.persisted.invalidatedReason {
            return .invalidated(reason)
        }
        if rules.allSatisfy({ $0.evaluate() }) {
            return .available
        }
        return .pending
    }

    func statusUpdates(for tipID: String, rules: [Tips.Rule]) -> AsyncStream<Tips.Status> {
        AsyncStream { continuation in
            let id = UUID()
            var state = liveState(for: tipID)
            state.streams[id] = (
                continuation: continuation,
                evaluator: { [weak self] in
                    guard let self else { return .pending }
                    return self.status(for: tipID, rules: rules)
                }
            )
            states[tipID] = state

            // Immediately yield the current value.
            continuation.yield(status(for: tipID, rules: rules))
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    var st = self.liveState(for: tipID)
                    st.streams.removeValue(forKey: id)
                    self.states[tipID] = st
                }
            }
        }
    }

    func invalidate(tipID: String, reason: Tips.InvalidationReason) {
        var state = liveState(for: tipID)
        state.persisted.invalidatedReason = reason
        persistState(state.persisted, tipID: tipID)
        states[tipID] = state
        notify(tipID: tipID)
    }

    func resetEligibility(tipID: String) {
        var state = liveState(for: tipID)
        state.persisted.invalidatedReason = nil
        persistState(state.persisted, tipID: tipID)
        states[tipID] = state
        notify(tipID: tipID)
    }

    func markReadersDirty(_ paths: Set<String>) {
        if paths.isEmpty {
            _RenderScheduler.current?.scheduleRender()
            return
        }
        for path in paths {
            _RenderScheduler.current?.markDirty(path: path)
        }
    }

    // MARK: Private

    private func liveState(for tipID: String) -> LiveState {
        if let existing = states[tipID] { return existing }
        let persisted = loadState(tipID: tipID)
        let created = LiveState(persisted: persisted)
        states[tipID] = created
        return created
    }

    private func registerRead(tipID: String) {
        guard let path = _RenderScheduler.currentComponentPath else { return }
        var state = liveState(for: tipID)
        state.readerComponentPaths.insert(path)
        states[tipID] = state
    }

    private func notify(tipID: String) {
        let state = liveState(for: tipID)
        markReadersDirty(state.readerComponentPaths)
        for entry in state.streams.values {
            entry.continuation.yield(entry.evaluator())
        }
    }

    private func loadState(tipID: String) -> TipState {
        TipsDatastore.loadValue(key: "raven.tipkit.tip.\(tipID)") ?? TipState(invalidatedReason: nil)
    }

    private func persistState(_ state: TipState, tipID: String) {
        TipsDatastore.saveValue(state, key: "raven.tipkit.tip.\(tipID)")
    }
}

extension Tips {
    @MainActor fileprivate static var _shared: _TipsSharedState { _TipsSharedState.shared }
}
