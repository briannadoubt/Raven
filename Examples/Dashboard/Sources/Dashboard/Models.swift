import Foundation

// MARK: - Stat Model

/// Represents a statistic card showing a metric
struct Stat: Identifiable, Sendable {
    let id: UUID
    let title: String
    let value: String
    let change: String
    let isPositive: Bool

    init(
        id: UUID = UUID(),
        title: String,
        value: String,
        change: String,
        isPositive: Bool
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.change = change
        self.isPositive = isPositive
    }
}

// MARK: - Photo Model

/// Represents a photo in the gallery
struct Photo: Identifiable, Sendable {
    let id: UUID
    let title: String
    let imageURL: String
    let author: String

    init(
        id: UUID = UUID(),
        title: String,
        imageURL: String,
        author: String
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.author = author
    }
}

// MARK: - Settings Model

/// Application settings
struct Settings: Sendable {
    var notificationsEnabled: Bool
    var darkModeEnabled: Bool
    var autoSaveEnabled: Bool
    var refreshInterval: RefreshInterval

    enum RefreshInterval: String, CaseIterable, Sendable {
        case manual = "Manual"
        case fiveMinutes = "5 Minutes"
        case fifteenMinutes = "15 Minutes"
        case thirtyMinutes = "30 Minutes"
        case hourly = "Hourly"

        var seconds: Int {
            switch self {
            case .manual: return 0
            case .fiveMinutes: return 300
            case .fifteenMinutes: return 900
            case .thirtyMinutes: return 1800
            case .hourly: return 3600
            }
        }
    }

    init(
        notificationsEnabled: Bool = true,
        darkModeEnabled: Bool = false,
        autoSaveEnabled: Bool = true,
        refreshInterval: RefreshInterval = .fifteenMinutes
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.autoSaveEnabled = autoSaveEnabled
        self.refreshInterval = refreshInterval
    }
}

// MARK: - Activity Model

/// Represents a recent activity item
struct Activity: Identifiable, Sendable {
    let id: UUID
    let description: String
    let timestamp: String
    let type: ActivityType

    enum ActivityType: Sendable {
        case login
        case upload
        case download
        case edit
        case delete

        var icon: String {
            switch self {
            case .login: return "→"
            case .upload: return "↑"
            case .download: return "↓"
            case .edit: return "✎"
            case .delete: return "×"
            }
        }
    }

    init(
        id: UUID = UUID(),
        description: String,
        timestamp: String,
        type: ActivityType
    ) {
        self.id = id
        self.description = description
        self.timestamp = timestamp
        self.type = type
    }
}
