import Foundation
import JavaScriptKit

/// A view that updates its content based on a timeline schedule.
///
/// `TimelineView` is essential for creating animated canvas content that updates
/// at specific intervals or with animation frame timing. It provides the current
/// date and timeline context to its content, enabling time-based animations and
/// periodic updates.
///
/// ## Overview
///
/// TimelineView uses HTML5's `requestAnimationFrame` for smooth 60fps animations
/// when using `.animation` schedule, ensuring efficient rendering synchronized
/// with the browser's refresh rate.
///
/// ## Creating Animations
///
/// Use TimelineView with Canvas for smooth animations:
///
/// ```swift
/// TimelineView(.animation) { timeline in
///     Canvas { context, size in
///         let elapsed = timeline.date.timeIntervalSince1970
///         let angle = elapsed.truncatingRemainder(dividingBy: 2 * .pi)
///
///         context.rotate(by: Angle(radians: angle))
///         context.fill(
///             Path(CGRect(x: -50, y: -50, width: 100, height: 100)),
///             with: .color(.blue)
///         )
///     }
/// }
/// .frame(width: 200, height: 200)
/// ```
///
/// ## Periodic Updates
///
/// Create periodic updates with explicit intervals:
///
/// ```swift
/// TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
///     Canvas { context, size in
///         // Update every second
///         let seconds = Int(timeline.date.timeIntervalSince1970)
///         context.drawText(
///             "Time: \(seconds)",
///             at: CGPoint(x: 10, y: 30)
///         )
///     }
/// }
/// ```
///
/// ## Explicit Dates
///
/// Use explicit date sequences for scheduled updates:
///
/// ```swift
/// let dates = [Date(), Date().addingTimeInterval(5), Date().addingTimeInterval(10)]
/// TimelineView(.explicit(dates)) { timeline in
///     // Content updates at each specified date
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Timeline Views
/// - ``init(_:content:)``
///
/// ### Schedules
/// - ``Schedule``
/// - ``TimelineSchedule``
///
/// ### Timeline Context
/// - ``Context``
public struct TimelineView<Content: View>: View {
    public typealias Body = Never

    private let schedule: Schedule
    private let content: @Sendable @MainActor (Context) -> Content
    private let id: UUID

    // MARK: - Initialization

    /// Creates a timeline view with a schedule and content.
    ///
    /// - Parameters:
    ///   - schedule: The schedule that determines when to update.
    ///   - content: A closure that creates the view content using the timeline context.
    public init(
        _ schedule: Schedule,
        @ViewBuilder content: @escaping @Sendable @MainActor (Context) -> Content
    ) {
        self.schedule = schedule
        self.content = content
        self.id = UUID()
    }

    // MARK: - Timeline Context

    /// The context provided to timeline view content.
    public struct Context: Sendable {
        /// The current date for this timeline update.
        public let date: Date

        /// The cadence of timeline updates.
        public let cadence: Cadence

        /// Describes how frequently a timeline updates.
        public enum Cadence: Sendable {
            /// Updates at the system's animation frame rate (~60fps).
            case live

            /// Updates at regular intervals.
            case seconds(Double)

            /// Updates at specific dates.
            case minutes(Int)
        }
    }

    // MARK: - Schedule

    /// A schedule that defines when a timeline view updates.
    public struct Schedule: Sendable {
        let type: ScheduleType

        enum ScheduleType: Sendable {
            case animation
            case periodic(from: Date, by: TimeInterval)
            case explicit([Date])
            case everyMinute
        }

        /// A schedule that updates with every animation frame (~60fps).
        public static var animation: Schedule {
            Schedule(type: .animation)
        }

        /// A schedule that updates at regular time intervals.
        ///
        /// - Parameters:
        ///   - startDate: The date to start updates.
        ///   - interval: The time interval between updates.
        /// - Returns: A periodic schedule.
        public static func periodic(from startDate: Date, by interval: TimeInterval) -> Schedule {
            Schedule(type: .periodic(from: startDate, by: interval))
        }

        /// A schedule that updates at specific dates.
        ///
        /// - Parameter dates: The dates at which to update.
        /// - Returns: An explicit schedule.
        public static func explicit(_ dates: [Date]) -> Schedule {
            Schedule(type: .explicit(dates))
        }

        /// A schedule that updates every minute.
        public static var everyMinute: Schedule {
            Schedule(type: .everyMinute)
        }
    }

    // MARK: - Animation Loop Management

    @MainActor
    internal func startAnimationLoop(
        onFrame: @escaping @Sendable @MainActor (Date) -> Void
    ) -> AnimationHandle {
        let handle = AnimationHandle()

        switch schedule.type {
        case .animation:
            startRAFLoop(handle: handle, onFrame: onFrame)

        case .periodic(let startDate, let interval):
            startPeriodicLoop(
                handle: handle,
                startDate: startDate,
                interval: interval,
                onFrame: onFrame
            )

        case .explicit(let dates):
            startExplicitLoop(handle: handle, dates: dates, onFrame: onFrame)

        case .everyMinute:
            startPeriodicLoop(
                handle: handle,
                startDate: Date(),
                interval: 60.0,
                onFrame: onFrame
            )
        }

        return handle
    }

    @MainActor
    private func startRAFLoop(
        handle: AnimationHandle,
        onFrame: @escaping @Sendable @MainActor (Date) -> Void
    ) {
        let closure = JSClosure { [weak handle] _ -> JSValue in
            guard let handle = handle, !handle.isCancelled else {
                return .undefined
            }

            Task { @MainActor in
                onFrame(Date())

                // Request next frame
                if !handle.isCancelled, let closureToSchedule = handle.closure {
                    handle.animationID = JSObject.global.requestAnimationFrame!(closureToSchedule)
                }
            }

            return .undefined
        }

        handle.closure = closure
        handle.animationID = JSObject.global.requestAnimationFrame!(closure)
    }

    @MainActor
    private func startPeriodicLoop(
        handle: AnimationHandle,
        startDate: Date,
        interval: TimeInterval,
        onFrame: @escaping @Sendable @MainActor (Date) -> Void
    ) {
        // Calculate delay until start date
        let now = Date()
        let delay = max(0, startDate.timeIntervalSince(now))

        let closure = JSClosure { [weak handle] _ -> JSValue in
            guard let handle = handle, !handle.isCancelled else {
                return .undefined
            }

            Task { @MainActor in
                onFrame(Date())
            }

            return .undefined
        }

        handle.closure = closure

        // Use setTimeout for periodic updates
        let intervalMs = interval * 1000
        let delayMs = delay * 1000

        if delayMs > 0 {
            // Delay until start date, then start interval
            let startClosure = JSClosure { _ -> JSValue in
                let intervalID = JSObject.global.setInterval!(closure, intervalMs)
                handle.intervalID = intervalID
                return .undefined
            }
            handle.timeoutID = JSObject.global.setTimeout!(startClosure, delayMs)
        } else {
            // Start immediately
            handle.intervalID = JSObject.global.setInterval!(closure, intervalMs)
        }
    }

    @MainActor
    private func startExplicitLoop(
        handle: AnimationHandle,
        dates: [Date],
        onFrame: @escaping @Sendable @MainActor (Date) -> Void
    ) {
        let now = Date()
        let futureDates = dates.filter { $0 > now }.sorted()

        var currentIndex = 0

        func scheduleNext() {
            guard currentIndex < futureDates.count else { return }
            guard !handle.isCancelled else { return }

            let nextDate = futureDates[currentIndex]
            let delay = nextDate.timeIntervalSince(Date())

            guard delay > 0 else {
                currentIndex += 1
                scheduleNext()
                return
            }

            let closure = JSClosure { _ -> JSValue in
                Task { @MainActor in
                    onFrame(nextDate)
                    currentIndex += 1
                    scheduleNext()
                }
                return .undefined
            }

            handle.timeoutID = JSObject.global.setTimeout!(closure, delay * 1000)
        }

        scheduleNext()
    }

    // MARK: - Animation Handle

    /// A handle for controlling an animation loop.
    @MainActor
    internal final class AnimationHandle {
        nonisolated(unsafe) var isCancelled = false
        nonisolated(unsafe) var closure: JSClosure?
        nonisolated(unsafe) var animationID: JSValue?
        nonisolated(unsafe) var intervalID: JSValue?
        nonisolated(unsafe) var timeoutID: JSValue?

        func cancel() {
            isCancelled = true

            if let animationID = animationID {
                _ = JSObject.global.cancelAnimationFrame!(animationID)
            }

            if let intervalID = intervalID {
                _ = JSObject.global.clearInterval!(intervalID)
            }

            if let timeoutID = timeoutID {
                _ = JSObject.global.clearTimeout!(timeoutID)
            }

            closure = nil
            animationID = nil
            intervalID = nil
            timeoutID = nil
        }

        deinit {
            // Note: Cannot call actor-isolated cancel() from deinit
            // The handle will be cleaned up by garbage collection
            // In production, consider using a cleanup handler
        }
    }
}

// MARK: - TimelineSchedule Protocol

/// A protocol that defines when a timeline view updates.
public protocol TimelineSchedule: Sendable {
    /// The entries that define update times.
    associatedtype Entries: Sequence where Entries.Element == Date

    /// Returns the sequence of dates when the view should update.
    ///
    /// - Parameter context: The schedule context.
    /// - Returns: A sequence of update dates.
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries
}

/// The mode for timeline schedule entries.
public enum TimelineScheduleMode: Sendable {
    /// Request entries for normal operation.
    case normal

    /// Request entries for low-power mode.
    case lowFrequency
}

// MARK: - Animation Schedule

/// A schedule that updates with animation frames.
public struct AnimationSchedule: TimelineSchedule {
    public func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        // Animation schedule uses requestAnimationFrame, not date-based entries
        return []
    }
}

// MARK: - Periodic Schedule

/// A schedule that updates at regular intervals.
public struct PeriodicSchedule: TimelineSchedule {
    let interval: TimeInterval

    public func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate

        // Generate next 60 seconds worth of dates
        let endDate = startDate.addingTimeInterval(60)

        while currentDate < endDate {
            dates.append(currentDate)
            currentDate = currentDate.addingTimeInterval(interval)
        }

        return dates
    }
}
