import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case chat = "Chat"
    case activity = "Activity"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .activity: return "list.bullet.rectangle.fill"
        case .settings: return "gear"
        }
    }
}

@Observable
class AppState {
    var isTracking: Bool = false
    var currentActivity: String = ""
    var focusScore: Int = 0
    var selectedTab: SidebarTab = .dashboard

    // Screenshot capture
    var captureIntervalSeconds: Int = 120
    var lastCaptureTime: Date? = nil
    var captureCountToday: Int = 0
    var hasScreenRecordingPermission: Bool = true
    var isIdle: Bool = false

    // Nudge
    var activeNudge: NudgeData? = nil
    var isNudgeActive: Bool { activeNudge != nil }
}

struct NudgeData: Identifiable {
    let id: String
    let emoji: String
    let message: String
    let severity: NudgeSeverity
    let trigger: String

    enum NudgeSeverity: String {
        case green, yellow, red, gray

        var color: Color {
            switch self {
            case .green: return .green
            case .yellow: return .yellow
            case .red: return .red
            case .gray: return .gray
            }
        }
    }
}
