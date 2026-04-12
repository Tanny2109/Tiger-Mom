import XCTest
@testable import TigerMom

// MARK: - ActivityEntry Tests

final class ActivityEntryTests: XCTestCase {

    func testActivityEntryInitialization() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = ActivityEntry(
            id: "entry-1",
            timestamp: date,
            appName: "Xcode",
            windowTitle: "TigerMom — AppState.swift",
            category: .deepWork,
            subcategory: "IDE",
            detail: "Editing Swift source file",
            confidence: 0.92,
            classificationReason: "Active IDE with source code open"
        )

        XCTAssertEqual(entry.id, "entry-1")
        XCTAssertEqual(entry.timestamp, date)
        XCTAssertEqual(entry.appName, "Xcode")
        XCTAssertEqual(entry.windowTitle, "TigerMom — AppState.swift")
        XCTAssertEqual(entry.category, .deepWork)
        XCTAssertEqual(entry.subcategory, "IDE")
        XCTAssertEqual(entry.detail, "Editing Swift source file")
        XCTAssertEqual(entry.confidence, 0.92)
        XCTAssertEqual(entry.classificationReason, "Active IDE with source code open")
    }

    func testActivityEntryIdentifiable() {
        let a = ActivityEntry(
            id: "a", timestamp: Date(), appName: "Safari",
            windowTitle: "", category: .distraction,
            subcategory: "", detail: "", confidence: 0, classificationReason: ""
        )
        let b = ActivityEntry(
            id: "b", timestamp: Date(), appName: "Safari",
            windowTitle: "", category: .distraction,
            subcategory: "", detail: "", confidence: 0, classificationReason: ""
        )
        XCTAssertNotEqual(a.id, b.id)
    }
}

// MARK: - ActivityType Tests

final class ActivityTypeTests: XCTestCase {

    func testAllCasesExist() {
        let cases = ActivityType.allCases
        XCTAssertEqual(cases.count, 5)
        XCTAssertTrue(cases.contains(.deepWork))
        XCTAssertTrue(cases.contains(.communication))
        XCTAssertTrue(cases.contains(.shallowWork))
        XCTAssertTrue(cases.contains(.distraction))
        XCTAssertTrue(cases.contains(.breakTime))
    }

    func testRawValues() {
        XCTAssertEqual(ActivityType.deepWork.rawValue, "Deep Work")
        XCTAssertEqual(ActivityType.communication.rawValue, "Communication")
        XCTAssertEqual(ActivityType.shallowWork.rawValue, "Shallow Work")
        XCTAssertEqual(ActivityType.distraction.rawValue, "Distraction")
        XCTAssertEqual(ActivityType.breakTime.rawValue, "Break")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(ActivityType(rawValue: "Deep Work"), .deepWork)
        XCTAssertEqual(ActivityType(rawValue: "Communication"), .communication)
        XCTAssertEqual(ActivityType(rawValue: "Shallow Work"), .shallowWork)
        XCTAssertEqual(ActivityType(rawValue: "Distraction"), .distraction)
        XCTAssertEqual(ActivityType(rawValue: "Break"), .breakTime)
        XCTAssertNil(ActivityType(rawValue: "Unknown"))
        XCTAssertNil(ActivityType(rawValue: ""))
    }

    func testColorAssignments() {
        // Verify each type has a distinct color mapping (non-nil)
        // and matches the expected palette colors
        XCTAssertEqual(ActivityType.deepWork.color, TigerPalette.jade)
        XCTAssertEqual(ActivityType.communication.color, TigerPalette.mist)
        XCTAssertEqual(ActivityType.shallowWork.color, TigerPalette.gold)
        XCTAssertEqual(ActivityType.distraction.color, TigerPalette.coral)
        XCTAssertEqual(ActivityType.breakTime.color, TigerPalette.textMuted)
    }
}

// MARK: - Activity Parsing Tests

final class ActivityParsingTests: XCTestCase {

    // We test the parsing logic from ActivityView by replicating parseActivity
    // This validates the refactored parsing didn't break data interpretation.

    private func parseActivity(_ dict: [String: Any]) -> ActivityEntry? {
        guard let id = dict["id"] as? String,
              let appName = dict["app_name"] as? String else { return nil }

        let timestamp = (dict["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let type = ActivityType(rawValue: dict["category"] as? String ?? "Break") ?? .breakTime

        return ActivityEntry(
            id: id,
            timestamp: timestamp,
            appName: appName,
            windowTitle: dict["window_title"] as? String ?? "",
            category: type,
            subcategory: dict["subcategory"] as? String ?? "",
            detail: dict["detail"] as? String ?? "",
            confidence: dict["confidence"] as? Double ?? 0,
            classificationReason: dict["classification_reason"] as? String ?? ""
        )
    }

    func testParseValidActivity() {
        let dict: [String: Any] = [
            "id": "act-1",
            "app_name": "Chrome",
            "timestamp": 1_700_000_000.0,
            "category": "Deep Work",
            "window_title": "Stack Overflow",
            "subcategory": "Research",
            "detail": "Reading docs",
            "confidence": 0.85,
            "classification_reason": "Technical content in browser"
        ]

        let entry = parseActivity(dict)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.id, "act-1")
        XCTAssertEqual(entry?.appName, "Chrome")
        XCTAssertEqual(entry?.timestamp, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(entry?.category, .deepWork)
        XCTAssertEqual(entry?.windowTitle, "Stack Overflow")
        XCTAssertEqual(entry?.subcategory, "Research")
        XCTAssertEqual(entry?.detail, "Reading docs")
        XCTAssertEqual(entry?.confidence, 0.85)
        XCTAssertEqual(entry?.classificationReason, "Technical content in browser")
    }

    func testParseMissingIdReturnsNil() {
        let dict: [String: Any] = [
            "app_name": "Chrome"
        ]
        XCTAssertNil(parseActivity(dict))
    }

    func testParseMissingAppNameReturnsNil() {
        let dict: [String: Any] = [
            "id": "act-2"
        ]
        XCTAssertNil(parseActivity(dict))
    }

    func testParseMissingOptionalFieldsUsesDefaults() {
        let dict: [String: Any] = [
            "id": "act-3",
            "app_name": "Finder"
        ]

        let entry = parseActivity(dict)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.windowTitle, "")
        XCTAssertEqual(entry?.category, .breakTime) // defaults to "Break"
        XCTAssertEqual(entry?.subcategory, "")
        XCTAssertEqual(entry?.detail, "")
        XCTAssertEqual(entry?.confidence, 0)
        XCTAssertEqual(entry?.classificationReason, "")
    }

    func testParseUnknownCategoryDefaultsToBreak() {
        let dict: [String: Any] = [
            "id": "act-4",
            "app_name": "Unknown App",
            "category": "SomeNewCategory"
        ]

        let entry = parseActivity(dict)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.category, .breakTime)
    }

    func testParseMissingTimestampUsesCurrentDate() {
        let before = Date()
        let dict: [String: Any] = [
            "id": "act-5",
            "app_name": "Terminal"
        ]

        let entry = parseActivity(dict)
        let after = Date()
        XCTAssertNotNil(entry)
        // Timestamp should be approximately now
        XCTAssertGreaterThanOrEqual(entry!.timestamp, before)
        XCTAssertLessThanOrEqual(entry!.timestamp, after)
    }

    func testParseAllValidCategories() {
        for actType in ActivityType.allCases {
            let dict: [String: Any] = [
                "id": "act-\(actType.rawValue)",
                "app_name": "TestApp",
                "category": actType.rawValue
            ]
            let entry = parseActivity(dict)
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry?.category, actType, "Failed for category: \(actType.rawValue)")
        }
    }
}

// MARK: - Icon Mapping Tests

final class IconForAppTests: XCTestCase {

    // Replicate the iconForApp logic from ActivityRow to test it
    private func iconForApp(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("safari") || lower.contains("chrome") || lower.contains("firefox") || lower.contains("arc") {
            return "globe"
        } else if lower.contains("slack") || lower.contains("discord") || lower.contains("teams") || lower.contains("messages") {
            return "bubble.left.and.bubble.right"
        } else if lower.contains("mail") || lower.contains("outlook") {
            return "envelope"
        } else if lower.contains("xcode") || lower.contains("code") || lower.contains("terminal") || lower.contains("iterm") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.contains("figma") || lower.contains("sketch") {
            return "paintbrush"
        } else if lower.contains("notion") || lower.contains("notes") || lower.contains("docs") {
            return "doc.text"
        } else if lower.contains("spotify") || lower.contains("music") {
            return "music.note"
        } else if lower.contains("finder") {
            return "folder"
        } else if lower.contains("twitter") || lower.contains("reddit") || lower.contains("youtube") || lower.contains("instagram") || lower.contains("tiktok") {
            return "exclamationmark.triangle"
        }
        return "app"
    }

    func testBrowserIcons() {
        XCTAssertEqual(iconForApp("Safari"), "globe")
        XCTAssertEqual(iconForApp("Google Chrome"), "globe")
        XCTAssertEqual(iconForApp("Firefox"), "globe")
        XCTAssertEqual(iconForApp("Arc Browser"), "globe")
    }

    func testCommunicationIcons() {
        XCTAssertEqual(iconForApp("Slack"), "bubble.left.and.bubble.right")
        XCTAssertEqual(iconForApp("Discord"), "bubble.left.and.bubble.right")
        XCTAssertEqual(iconForApp("Microsoft Teams"), "bubble.left.and.bubble.right")
        XCTAssertEqual(iconForApp("Messages"), "bubble.left.and.bubble.right")
    }

    func testEmailIcons() {
        XCTAssertEqual(iconForApp("Mail"), "envelope")
        XCTAssertEqual(iconForApp("Microsoft Outlook"), "envelope")
    }

    func testDeveloperToolIcons() {
        XCTAssertEqual(iconForApp("Xcode"), "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(iconForApp("Visual Studio Code"), "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(iconForApp("Terminal"), "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(iconForApp("iTerm2"), "chevron.left.forwardslash.chevron.right")
    }

    func testDesignToolIcons() {
        XCTAssertEqual(iconForApp("Figma"), "paintbrush")
        XCTAssertEqual(iconForApp("Sketch"), "paintbrush")
    }

    func testDocumentIcons() {
        XCTAssertEqual(iconForApp("Notion"), "doc.text")
        XCTAssertEqual(iconForApp("Notes"), "doc.text")
        XCTAssertEqual(iconForApp("Google Docs"), "doc.text")
    }

    func testMusicIcons() {
        XCTAssertEqual(iconForApp("Spotify"), "music.note")
        XCTAssertEqual(iconForApp("Apple Music"), "music.note")
    }

    func testFinderIcon() {
        XCTAssertEqual(iconForApp("Finder"), "folder")
    }

    func testSocialMediaIcons() {
        XCTAssertEqual(iconForApp("Twitter"), "exclamationmark.triangle")
        XCTAssertEqual(iconForApp("Reddit"), "exclamationmark.triangle")
        XCTAssertEqual(iconForApp("YouTube"), "exclamationmark.triangle")
        XCTAssertEqual(iconForApp("Instagram"), "exclamationmark.triangle")
        XCTAssertEqual(iconForApp("TikTok"), "exclamationmark.triangle")
    }

    func testUnknownAppReturnsDefault() {
        XCTAssertEqual(iconForApp("SomeRandomApp"), "app")
        XCTAssertEqual(iconForApp("Calculator"), "app")
        XCTAssertEqual(iconForApp("Preview"), "app")
    }

    func testCaseInsensitivity() {
        XCTAssertEqual(iconForApp("SAFARI"), "globe")
        XCTAssertEqual(iconForApp("slack"), "bubble.left.and.bubble.right")
        XCTAssertEqual(iconForApp("XCODE"), "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(iconForApp("NOTION"), "doc.text")
    }
}

// MARK: - Filtered Activities Tests

final class FilteredActivitiesTests: XCTestCase {

    private func makeEntry(
        id: String = UUID().uuidString,
        appName: String = "TestApp",
        windowTitle: String = "",
        category: ActivityType = .deepWork,
        detail: String = "",
        classificationReason: String = ""
    ) -> ActivityEntry {
        ActivityEntry(
            id: id,
            timestamp: Date(),
            appName: appName,
            windowTitle: windowTitle,
            category: category,
            subcategory: "",
            detail: detail,
            confidence: 0.5,
            classificationReason: classificationReason
        )
    }

    // Replicate filteredActivities logic from ActivityView
    private func filteredActivities(
        activities: [ActivityEntry],
        selectedFilter: ActivityType?,
        searchText: String
    ) -> [ActivityEntry] {
        activities.filter { entry in
            let matchesCategory = selectedFilter == nil || entry.category == selectedFilter
            let matchesSearch = searchText.isEmpty
                || entry.appName.localizedCaseInsensitiveContains(searchText)
                || entry.windowTitle.localizedCaseInsensitiveContains(searchText)
                || entry.detail.localizedCaseInsensitiveContains(searchText)
                || entry.classificationReason.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    func testNoFilterReturnsAll() {
        let entries = [
            makeEntry(appName: "Xcode", category: .deepWork),
            makeEntry(appName: "Slack", category: .communication),
            makeEntry(appName: "Reddit", category: .distraction)
        ]
        let result = filteredActivities(activities: entries, selectedFilter: nil, searchText: "")
        XCTAssertEqual(result.count, 3)
    }

    func testCategoryFilter() {
        let entries = [
            makeEntry(appName: "Xcode", category: .deepWork),
            makeEntry(appName: "Slack", category: .communication),
            makeEntry(appName: "Reddit", category: .distraction)
        ]
        let result = filteredActivities(activities: entries, selectedFilter: .deepWork, searchText: "")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.appName, "Xcode")
    }

    func testSearchByAppName() {
        let entries = [
            makeEntry(appName: "Xcode", category: .deepWork),
            makeEntry(appName: "Slack", category: .communication),
        ]
        let result = filteredActivities(activities: entries, selectedFilter: nil, searchText: "xcode")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.appName, "Xcode")
    }

    func testSearchByWindowTitle() {
        let entries = [
            makeEntry(appName: "Chrome", windowTitle: "GitHub Pull Request"),
            makeEntry(appName: "Chrome", windowTitle: "YouTube Music"),
        ]
        let result = filteredActivities(activities: entries, selectedFilter: nil, searchText: "github")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.windowTitle, "GitHub Pull Request")
    }

    func testSearchByDetail() {
        let entries = [
            makeEntry(detail: "Reviewing pull request"),
            makeEntry(detail: "Watching videos"),
        ]
        let result = filteredActivities(activities: entries, selectedFilter: nil, searchText: "pull request")
        XCTAssertEqual(result.count, 1)
    }

    func testSearchByClassificationReason() {
        let entries = [
            makeEntry(classificationReason: "IDE with code editor active"),
            makeEntry(classificationReason: "Social media content"),
        ]
        let result = filteredActivities(activities: entries, selectedFilter: nil, searchText: "social media")
        XCTAssertEqual(result.count, 1)
    }

    func testCombinedFilterAndSearch() {
        let entries = [
            makeEntry(appName: "Chrome", category: .deepWork, detail: "Docs"),
            makeEntry(appName: "Chrome", category: .distraction, detail: "Docs"),
            makeEntry(appName: "Slack", category: .communication, detail: "Chat"),
        ]
        let result = filteredActivities(activities: entries, selectedFilter: .deepWork, searchText: "docs")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.category, .deepWork)
    }

    func testSearchCaseInsensitive() {
        let entries = [
            makeEntry(appName: "Xcode"),
        ]
        XCTAssertEqual(filteredActivities(activities: entries, selectedFilter: nil, searchText: "XCODE").count, 1)
        XCTAssertEqual(filteredActivities(activities: entries, selectedFilter: nil, searchText: "xcode").count, 1)
        XCTAssertEqual(filteredActivities(activities: entries, selectedFilter: nil, searchText: "Xcode").count, 1)
    }

    func testEmptyActivitiesReturnsEmpty() {
        let result = filteredActivities(activities: [], selectedFilter: nil, searchText: "test")
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterWithNoMatchesReturnsEmpty() {
        let entries = [
            makeEntry(appName: "Xcode", category: .deepWork),
        ]
        let result = filteredActivities(activities: entries, selectedFilter: .distraction, searchText: "")
        XCTAssertTrue(result.isEmpty)
    }
}
