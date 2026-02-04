import Foundation
import Raven

// Import Raven's ObservableObject explicitly to avoid ambiguity with Foundation
typealias ObservableObject = Raven.ObservableObject
typealias Published = Raven.Published

// MARK: - Dashboard Store

/// Main store managing dashboard state
@MainActor
final class DashboardStore: ObservableObject {
    /// Current statistics
    @Published var stats: [Stat] = []

    /// Photo gallery items
    @Published var photos: [Photo] = []

    /// Recent activities
    @Published var activities: [Activity] = []

    /// Application settings
    @Published var settings: Settings = Settings()

    /// Currently selected section
    @Published var selectedSection: Section = .overview

    /// Available dashboard sections
    enum Section: String, CaseIterable, Sendable {
        case overview = "Overview"
        case gallery = "Gallery"
        case activity = "Activity"
        case settings = "Settings"
    }

    init() {
        setupPublished()
        loadSampleData()
    }

    /// Load sample data for demonstration
    private func loadSampleData() {
        // Sample statistics
        stats = [
            Stat(
                title: "Total Users",
                value: "12,543",
                change: "+12.5%",
                isPositive: true
            ),
            Stat(
                title: "Revenue",
                value: "$45,678",
                change: "+8.3%",
                isPositive: true
            ),
            Stat(
                title: "Active Sessions",
                value: "1,234",
                change: "-3.2%",
                isPositive: false
            ),
            Stat(
                title: "Conversion Rate",
                value: "3.45%",
                change: "+0.5%",
                isPositive: true
            )
        ]

        // Sample photos
        photos = [
            Photo(title: "Sunset", imageURL: "sunset.jpg", author: "Alice"),
            Photo(title: "Mountains", imageURL: "mountains.jpg", author: "Bob"),
            Photo(title: "Ocean", imageURL: "ocean.jpg", author: "Charlie"),
            Photo(title: "Forest", imageURL: "forest.jpg", author: "Diana"),
            Photo(title: "City", imageURL: "city.jpg", author: "Eve"),
            Photo(title: "Desert", imageURL: "desert.jpg", author: "Frank")
        ]

        // Sample activities
        activities = [
            Activity(
                description: "User logged in",
                timestamp: "2 minutes ago",
                type: .login
            ),
            Activity(
                description: "File uploaded: report.pdf",
                timestamp: "15 minutes ago",
                type: .upload
            ),
            Activity(
                description: "Document edited: proposal.doc",
                timestamp: "1 hour ago",
                type: .edit
            ),
            Activity(
                description: "Image downloaded: photo.jpg",
                timestamp: "2 hours ago",
                type: .download
            ),
            Activity(
                description: "Item deleted: old_data.csv",
                timestamp: "3 hours ago",
                type: .delete
            )
        ]
    }

    /// Refresh dashboard data
    func refresh() {
        // In a real app, this would fetch from an API
        loadSampleData()
    }

    /// Update settings
    func updateSettings(_ newSettings: Settings) {
        settings = newSettings
    }
}

// MARK: - Main Dashboard View

/// Main dashboard view with navigation
@MainActor
struct Dashboard: View {
    @StateObject private var store = DashboardStore()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            DashboardHeader(
                currentSection: store.selectedSection,
                onRefresh: { store.refresh() }
            )

            Divider()

            // Navigation
            NavigationBar(
                currentSection: store.selectedSection,
                onSelect: { section in store.selectedSection = section }
            )

            Divider()

            // Main content area
            // This demonstrates conditional rendering based on selected section
            switch store.selectedSection {
            case .overview:
                OverviewSection(
                    stats: store.stats,
                    activities: store.activities
                )
            case .gallery:
                GallerySection(photos: store.photos)
            case .activity:
                ActivitySection(activities: store.activities)
            case .settings:
                SettingsSection(
                    settings: store.settings,
                    onUpdate: { store.updateSettings($0) }
                )
            }
        }
    }
}

// MARK: - Header View

/// Dashboard header with title and refresh button
@MainActor
struct DashboardHeader: View {
    let currentSection: DashboardStore.Section
    let onRefresh: @MainActor () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.title)
                Text(currentSection.rawValue)
                    .font(.caption)
            }

            Spacer()

            Button("Refresh") {
                onRefresh()
            }
        }
    }
}

// MARK: - Navigation Bar

/// Navigation bar for switching between sections
@MainActor
struct NavigationBar: View {
    let currentSection: DashboardStore.Section
    let onSelect: @MainActor (DashboardStore.Section) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DashboardStore.Section.allCases, id: \.self) { section in
                Button(section.rawValue) {
                    onSelect(section)
                }
                // In a real app, you'd style the selected button differently
            }
        }
    }
}

// MARK: - Overview Section

/// Overview section showing stats and recent activity
@MainActor
struct OverviewSection: View {
    let stats: [Stat]
    let activities: [Activity]

    var body: some View {
        VStack(spacing: 24) {
            // Stats grid - demonstrates LazyVGrid usage
            Text("Statistics")
                .font(.headline)

            // Create a 2-column grid for stats
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                ForEach(stats) { stat in
                    StatCard(stat: stat)
                }
            }

            Divider()

            // Recent activity preview
            Text("Recent Activity")
                .font(.headline)

            // Show first 3 activities
            VStack(spacing: 8) {
                ForEach(activities.prefix(3)) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
    }
}

// MARK: - Stat Card

/// Individual stat card component
@MainActor
struct StatCard: View {
    let stat: Stat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stat.title)
                .font(.caption)

            Text(stat.value)
                .font(.title)

            HStack(spacing: 4) {
                Text(stat.isPositive ? "↑" : "↓")
                Text(stat.change)
                    .font(.caption)
            }
        }
        // In a real app, you'd add padding and background styling
    }
}

// MARK: - Gallery Section

/// Photo gallery section with grid layout
@MainActor
struct GallerySection: View {
    let photos: [Photo]

    var body: some View {
        VStack(spacing: 16) {
            Text("Photo Gallery")
                .font(.headline)

            // Demonstrates GeometryReader for responsive layout
            GeometryReader { geometry in
                // Calculate column count based on available width
                let columnCount = max(2, Int(geometry.size.width / 200))

                // Create flexible columns
                let columns = Array(
                    repeating: GridItem(.flexible()),
                    count: columnCount
                )

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(photos) { photo in
                        PhotoCard(photo: photo)
                    }
                }
            }
        }
    }
}

// MARK: - Photo Card

/// Individual photo card in the gallery
@MainActor
struct PhotoCard: View {
    let photo: Photo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder for image
            // In a real app, this would be Image(url: photo.imageURL)
            Text("[Image: \(photo.imageURL)]")

            Text(photo.title)
                .font(.headline)

            Text("by \(photo.author)")
                .font(.caption)
        }
    }
}

// MARK: - Activity Section

/// Full activity feed section
@MainActor
struct ActivitySection: View {
    let activities: [Activity]

    var body: some View {
        VStack(spacing: 16) {
            Text("Activity Feed")
                .font(.headline)

            List(activities) { activity in
                ActivityRow(activity: activity)
            }
        }
    }
}

// MARK: - Activity Row

/// Individual activity row component
@MainActor
struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on activity type
            Text(activity.type.icon)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                Text(activity.timestamp)
                    .font(.caption)
            }

            Spacer()
        }
    }
}

// MARK: - Settings Section

/// Settings form section
@MainActor
struct SettingsSection: View {
    let settings: Settings
    let onUpdate: @MainActor (Settings) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)

            // Form demonstrates Form and Section usage
            Form {
                Section {
                    // Toggle switches for boolean settings
                    ToggleRow(
                        title: "Notifications",
                        isOn: settings.notificationsEnabled
                    ) { newValue in
                        var updated = settings
                        updated.notificationsEnabled = newValue
                        onUpdate(updated)
                    }

                    ToggleRow(
                        title: "Dark Mode",
                        isOn: settings.darkModeEnabled
                    ) { newValue in
                        var updated = settings
                        updated.darkModeEnabled = newValue
                        onUpdate(updated)
                    }

                    ToggleRow(
                        title: "Auto Save",
                        isOn: settings.autoSaveEnabled
                    ) { newValue in
                        var updated = settings
                        updated.autoSaveEnabled = newValue
                        onUpdate(updated)
                    }
                }

                Section {
                    Text("Refresh Interval")

                    // Picker for refresh interval
                    VStack(spacing: 4) {
                        ForEach(Settings.RefreshInterval.allCases, id: \.self) { interval in
                            Button(interval.rawValue) {
                                var updated = settings
                                updated.refreshInterval = interval
                                onUpdate(updated)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Toggle Row

/// Reusable toggle row component
@MainActor
struct ToggleRow: View {
    let title: String
    let isOn: Bool
    let onChange: @MainActor (Bool) -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            // Use a button to simulate toggle for now
            Button(isOn ? "ON" : "OFF") {
                onChange(!isOn)
            }
        }
    }
}

// MARK: - Usage Notes

/*
 This Dashboard app demonstrates advanced Raven/SwiftUI concepts:

 1. Complex Layout:
    - LazyVGrid: Grid layout with flexible columns
    - GeometryReader: Responsive layout based on available space
    - Form + Section: Structured form layout
    - HStack/VStack: Flexible box layout

 2. Navigation:
    - Section-based navigation without NavigationView
    - State-driven content switching
    - Shared state across sections

 3. Responsive Design:
    - GeometryReader to calculate column count
    - Flexible grid items that adapt to container
    - Proper spacing and alignment

 4. Component Architecture:
    - Small, focused components
    - Reusable pieces (StatCard, PhotoCard, ActivityRow)
    - Clear separation of concerns

 5. Data Flow:
    - Central store managing all state
    - Props down, callbacks up pattern
    - Immutable settings updates

 Key Learning Points:
 - LazyVGrid creates efficient grid layouts
 - GeometryReader provides size information for responsive design
 - Form and Section create structured input areas
 - Switch statements enable conditional view rendering
 - Complex UIs are built from simple components
*/
