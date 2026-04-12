import XCTest
@testable import TigerMom

// MARK: - SidebarTab Tests

final class SidebarTabTests: XCTestCase {

    func testAllCases() {
        let cases = SidebarTab.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertTrue(cases.contains(.dashboard))
        XCTAssertTrue(cases.contains(.chat))
        XCTAssertTrue(cases.contains(.activity))
        XCTAssertTrue(cases.contains(.settings))
    }

    func testRawValues() {
        XCTAssertEqual(SidebarTab.dashboard.rawValue, "Dashboard")
        XCTAssertEqual(SidebarTab.chat.rawValue, "Chat")
        XCTAssertEqual(SidebarTab.activity.rawValue, "Activity")
        XCTAssertEqual(SidebarTab.settings.rawValue, "Settings")
    }

    func testIdentifiable() {
        XCTAssertEqual(SidebarTab.dashboard.id, "Dashboard")
        XCTAssertEqual(SidebarTab.chat.id, "Chat")
        XCTAssertEqual(SidebarTab.activity.id, "Activity")
        XCTAssertEqual(SidebarTab.settings.id, "Settings")
    }

    func testIcons() {
        XCTAssertEqual(SidebarTab.dashboard.icon, "chart.bar.fill")
        XCTAssertEqual(SidebarTab.chat.icon, "bubble.left.and.bubble.right.fill")
        XCTAssertEqual(SidebarTab.activity.icon, "list.bullet.rectangle.fill")
        XCTAssertEqual(SidebarTab.settings.icon, "gear")
    }

    func testSubtitles() {
        XCTAssertEqual(SidebarTab.dashboard.subtitle, "Pulse, trends, and report card")
        XCTAssertEqual(SidebarTab.chat.subtitle, "Live coaching with memory")
        XCTAssertEqual(SidebarTab.activity.subtitle, "A readable stream of behavior")
        XCTAssertEqual(SidebarTab.settings.subtitle, "Models, rules, and privacy")
    }

    func testIconsNotEmpty() {
        for tab in SidebarTab.allCases {
            XCTAssertFalse(tab.icon.isEmpty, "Icon should not be empty for \(tab)")
        }
    }

    func testSubtitlesNotEmpty() {
        for tab in SidebarTab.allCases {
            XCTAssertFalse(tab.subtitle.isEmpty, "Subtitle should not be empty for \(tab)")
        }
    }
}

// MARK: - AppState Tests

final class AppStateTests: XCTestCase {

    func testDefaultValues() {
        let state = AppState()
        XCTAssertFalse(state.isTracking)
        XCTAssertEqual(state.currentActivity, "")
        XCTAssertEqual(state.focusScore, 0)
        XCTAssertEqual(state.selectedTab, .dashboard)
        XCTAssertEqual(state.captureIntervalSeconds, 120)
        XCTAssertNil(state.lastCaptureTime)
        XCTAssertEqual(state.captureCountToday, 0)
        XCTAssertTrue(state.hasScreenRecordingPermission)
        XCTAssertFalse(state.isIdle)
        XCTAssertNil(state.activeNudge)
        XCTAssertFalse(state.isNudgeActive)
    }

    func testTrackingToggle() {
        let state = AppState()
        XCTAssertFalse(state.isTracking)
        state.isTracking = true
        XCTAssertTrue(state.isTracking)
        state.isTracking = false
        XCTAssertFalse(state.isTracking)
    }

    func testSelectedTabChange() {
        let state = AppState()
        XCTAssertEqual(state.selectedTab, .dashboard)
        state.selectedTab = .chat
        XCTAssertEqual(state.selectedTab, .chat)
        state.selectedTab = .activity
        XCTAssertEqual(state.selectedTab, .activity)
        state.selectedTab = .settings
        XCTAssertEqual(state.selectedTab, .settings)
    }

    func testFocusScore() {
        let state = AppState()
        state.focusScore = 85
        XCTAssertEqual(state.focusScore, 85)
    }

    func testCaptureCount() {
        let state = AppState()
        state.captureCountToday = 42
        XCTAssertEqual(state.captureCountToday, 42)
    }

    func testLastCaptureTime() {
        let state = AppState()
        let now = Date()
        state.lastCaptureTime = now
        XCTAssertEqual(state.lastCaptureTime, now)
    }

    func testIdleState() {
        let state = AppState()
        state.isIdle = true
        XCTAssertTrue(state.isIdle)
    }

    func testNudgeActive() {
        let state = AppState()
        XCTAssertFalse(state.isNudgeActive)

        let nudge = NudgeData(
            id: "nudge-1",
            emoji: "🐯",
            message: "Focus up!",
            severity: .yellow,
            trigger: "Reddit open for 15 min"
        )
        state.activeNudge = nudge
        XCTAssertTrue(state.isNudgeActive)
        XCTAssertEqual(state.activeNudge?.id, "nudge-1")

        state.activeNudge = nil
        XCTAssertFalse(state.isNudgeActive)
    }
}

// MARK: - NudgeData Tests

final class NudgeDataTests: XCTestCase {

    func testNudgeDataInitialization() {
        let nudge = NudgeData(
            id: "n1",
            emoji: "⚠️",
            message: "You've been on Twitter for 20 minutes",
            severity: .red,
            trigger: "twitter.com"
        )

        XCTAssertEqual(nudge.id, "n1")
        XCTAssertEqual(nudge.emoji, "⚠️")
        XCTAssertEqual(nudge.message, "You've been on Twitter for 20 minutes")
        XCTAssertEqual(nudge.severity, .red)
        XCTAssertEqual(nudge.trigger, "twitter.com")
    }

    func testNudgeSeverityColors() {
        XCTAssertEqual(NudgeData.NudgeSeverity.green.color, .green)
        XCTAssertEqual(NudgeData.NudgeSeverity.yellow.color, .yellow)
        XCTAssertEqual(NudgeData.NudgeSeverity.red.color, .red)
        XCTAssertEqual(NudgeData.NudgeSeverity.gray.color, .gray)
    }

    func testNudgeSeverityRawValues() {
        XCTAssertEqual(NudgeData.NudgeSeverity.green.rawValue, "green")
        XCTAssertEqual(NudgeData.NudgeSeverity.yellow.rawValue, "yellow")
        XCTAssertEqual(NudgeData.NudgeSeverity.red.rawValue, "red")
        XCTAssertEqual(NudgeData.NudgeSeverity.gray.rawValue, "gray")
    }
}
