import XCTest
@testable import TigerMom

// MARK: - DailyAnalytics Tests

final class DailyAnalyticsTests: XCTestCase {

    func testDefaultValues() {
        let daily = DailyAnalytics()
        XCTAssertEqual(daily.focusScore, 0)
        XCTAssertEqual(daily.deepWorkMinutes, 0)
        XCTAssertEqual(daily.distractionMinutes, 0)
        XCTAssertEqual(daily.shallowWorkMinutes, 0)
        XCTAssertTrue(daily.categories.isEmpty)
        XCTAssertTrue(daily.topDistractors.isEmpty)
        XCTAssertEqual(daily.momGrade, "")
        XCTAssertEqual(daily.momCommentary, "")
        XCTAssertFalse(daily.hasReport)
    }

    func testMutability() {
        var daily = DailyAnalytics()
        daily.focusScore = 78
        daily.deepWorkMinutes = 200
        daily.distractionMinutes = 45
        daily.shallowWorkMinutes = 90
        daily.topDistractors = ["Reddit", "YouTube"]
        daily.momGrade = "B+"
        daily.momCommentary = "Good effort but could be better"
        daily.hasReport = true

        XCTAssertEqual(daily.focusScore, 78)
        XCTAssertEqual(daily.deepWorkMinutes, 200)
        XCTAssertEqual(daily.distractionMinutes, 45)
        XCTAssertEqual(daily.shallowWorkMinutes, 90)
        XCTAssertEqual(daily.topDistractors, ["Reddit", "YouTube"])
        XCTAssertEqual(daily.momGrade, "B+")
        XCTAssertEqual(daily.momCommentary, "Good effort but could be better")
        XCTAssertTrue(daily.hasReport)
    }
}

// MARK: - CategoryData Tests

final class CategoryDataTests: XCTestCase {

    func testCategoryDataInitialization() {
        let cat = CategoryData(name: "Deep Work", minutes: 120, type: .deepWork)
        XCTAssertEqual(cat.name, "Deep Work")
        XCTAssertEqual(cat.minutes, 120)
        XCTAssertEqual(cat.type, .deepWork)
    }

    func testCategoryDataIdentifiable() {
        let a = CategoryData(name: "A", minutes: 10, type: .deepWork)
        let b = CategoryData(name: "A", minutes: 10, type: .deepWork)
        // Each instance should get a unique UUID
        XCTAssertNotEqual(a.id, b.id)
    }
}

// MARK: - TimelineBlock Tests

final class TimelineBlockTests: XCTestCase {

    func testTimelineBlockInitialization() {
        let block = TimelineBlock(startMinute: 540, endMinute: 600, type: .deepWork)
        XCTAssertEqual(block.startMinute, 540)
        XCTAssertEqual(block.endMinute, 600)
        XCTAssertEqual(block.type, .deepWork)
    }

    func testTimelineBlockIdentifiable() {
        let a = TimelineBlock(startMinute: 0, endMinute: 60, type: .deepWork)
        let b = TimelineBlock(startMinute: 0, endMinute: 60, type: .deepWork)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testTimelineBlockDuration() {
        let block = TimelineBlock(startMinute: 100, endMinute: 160, type: .shallowWork)
        XCTAssertEqual(block.endMinute - block.startMinute, 60)
    }
}

// MARK: - WeeklyDay Tests

final class WeeklyDayTests: XCTestCase {

    func testWeeklyDayInitialization() {
        let day = WeeklyDay(label: "Mon", focusHours: 6.5, distractionPercent: 12.3)
        XCTAssertEqual(day.label, "Mon")
        XCTAssertEqual(day.focusHours, 6.5)
        XCTAssertEqual(day.distractionPercent, 12.3)
    }

    func testWeeklyDayIdentifiable() {
        let a = WeeklyDay(label: "Mon", focusHours: 6, distractionPercent: 10)
        let b = WeeklyDay(label: "Mon", focusHours: 6, distractionPercent: 10)
        XCTAssertNotEqual(a.id, b.id)
    }
}

// MARK: - Greeting Tests

final class GreetingTests: XCTestCase {

    // Replicate the greeting logic from DashboardView
    private func greeting(for hour: Int) -> String {
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<23: return "Good evening"
        default: return "Still awake"
        }
    }

    func testMorningGreeting() {
        XCTAssertEqual(greeting(for: 5), "Good morning")
        XCTAssertEqual(greeting(for: 8), "Good morning")
        XCTAssertEqual(greeting(for: 11), "Good morning")
    }

    func testAfternoonGreeting() {
        XCTAssertEqual(greeting(for: 12), "Good afternoon")
        XCTAssertEqual(greeting(for: 14), "Good afternoon")
        XCTAssertEqual(greeting(for: 16), "Good afternoon")
    }

    func testEveningGreeting() {
        XCTAssertEqual(greeting(for: 17), "Good evening")
        XCTAssertEqual(greeting(for: 20), "Good evening")
        XCTAssertEqual(greeting(for: 22), "Good evening")
    }

    func testLateNightGreeting() {
        XCTAssertEqual(greeting(for: 0), "Still awake")
        XCTAssertEqual(greeting(for: 1), "Still awake")
        XCTAssertEqual(greeting(for: 3), "Still awake")
        XCTAssertEqual(greeting(for: 4), "Still awake")
        XCTAssertEqual(greeting(for: 23), "Still awake")
    }

    func testBoundaryHours() {
        // Hour 5 is first morning hour
        XCTAssertEqual(greeting(for: 5), "Good morning")
        // Hour 4 is still "Still awake"
        XCTAssertEqual(greeting(for: 4), "Still awake")
        // Hour 12 starts afternoon
        XCTAssertEqual(greeting(for: 12), "Good afternoon")
        // Hour 17 starts evening
        XCTAssertEqual(greeting(for: 17), "Good evening")
        // Hour 23 is "Still awake"
        XCTAssertEqual(greeting(for: 23), "Still awake")
    }
}

// MARK: - Grade Color Tests

final class GradeColorTests: XCTestCase {

    // Replicate gradeColor logic from DashboardView
    private func gradeColor(_ grade: String) -> String {
        switch grade.prefix(1) {
        case "A": return "jade"
        case "B": return "gold"
        case "C": return "yellow"
        default: return "coral"
        }
    }

    func testGradeA() {
        XCTAssertEqual(gradeColor("A"), "jade")
        XCTAssertEqual(gradeColor("A+"), "jade")
        XCTAssertEqual(gradeColor("A-"), "jade")
    }

    func testGradeB() {
        XCTAssertEqual(gradeColor("B"), "gold")
        XCTAssertEqual(gradeColor("B+"), "gold")
        XCTAssertEqual(gradeColor("B-"), "gold")
    }

    func testGradeC() {
        XCTAssertEqual(gradeColor("C"), "yellow")
        XCTAssertEqual(gradeColor("C+"), "yellow")
        XCTAssertEqual(gradeColor("C-"), "yellow")
    }

    func testGradeD() {
        XCTAssertEqual(gradeColor("D"), "coral")
        XCTAssertEqual(gradeColor("D+"), "coral")
    }

    func testGradeF() {
        XCTAssertEqual(gradeColor("F"), "coral")
    }

    func testEmptyGrade() {
        XCTAssertEqual(gradeColor(""), "coral")
    }
}

// MARK: - Dashboard Data Parsing Tests

final class DashboardDataParsingTests: XCTestCase {

    // Replicate category parsing from loadData
    private func parseCategories(_ cats: [[String: Any]]) -> [CategoryData] {
        cats.compactMap { cat in
            guard let name = cat["name"] as? String,
                  let mins = cat["minutes"] as? Int,
                  let typeStr = cat["type"] as? String else { return nil }
            let type = ActivityType(rawValue: typeStr) ?? .shallowWork
            return CategoryData(name: name, minutes: mins, type: type)
        }
    }

    func testParseCategoriesValid() {
        let cats: [[String: Any]] = [
            ["name": "Deep Work", "minutes": 120, "type": "Deep Work"],
            ["name": "Distraction", "minutes": 30, "type": "Distraction"]
        ]
        let result = parseCategories(cats)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Deep Work")
        XCTAssertEqual(result[0].minutes, 120)
        XCTAssertEqual(result[0].type, .deepWork)
        XCTAssertEqual(result[1].name, "Distraction")
        XCTAssertEqual(result[1].minutes, 30)
        XCTAssertEqual(result[1].type, .distraction)
    }

    func testParseCategoriesMissingFieldsSkips() {
        let cats: [[String: Any]] = [
            ["name": "Deep Work", "minutes": 120],  // missing type
            ["minutes": 30, "type": "Distraction"],  // missing name
            ["name": "Shallow", "type": "Shallow Work"]  // missing minutes
        ]
        let result = parseCategories(cats)
        XCTAssertTrue(result.isEmpty)
    }

    func testParseCategoriesUnknownTypeDefaultsToShallowWork() {
        let cats: [[String: Any]] = [
            ["name": "Unknown", "minutes": 10, "type": "InvalidType"]
        ]
        let result = parseCategories(cats)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].type, .shallowWork)
    }

    // Replicate weekly parsing from loadData
    private func parseWeekly(_ days: [[String: Any]]) -> [WeeklyDay] {
        days.compactMap { day in
            guard let label = day["label"] as? String,
                  let hours = day["focus_hours"] as? Double,
                  let distPct = day["distraction_percent"] as? Double else { return nil }
            return WeeklyDay(label: label, focusHours: hours, distractionPercent: distPct)
        }
    }

    func testParseWeeklyValid() {
        let days: [[String: Any]] = [
            ["label": "Mon", "focus_hours": 5.5, "distraction_percent": 15.0],
            ["label": "Tue", "focus_hours": 7.0, "distraction_percent": 8.0]
        ]
        let result = parseWeekly(days)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].label, "Mon")
        XCTAssertEqual(result[0].focusHours, 5.5)
        XCTAssertEqual(result[0].distractionPercent, 15.0)
    }

    func testParseWeeklyMissingFieldsSkips() {
        let days: [[String: Any]] = [
            ["label": "Mon", "focus_hours": 5.5],  // missing distraction_percent
        ]
        let result = parseWeekly(days)
        XCTAssertTrue(result.isEmpty)
    }

    // Replicate timeline parsing from loadData
    private func parseTimeline(_ blocks: [[String: Any]]) -> [TimelineBlock] {
        blocks.compactMap { block in
            guard let start = block["start_minute"] as? Int,
                  let end = block["end_minute"] as? Int,
                  let typeStr = block["type"] as? String else { return nil }
            let type = ActivityType(rawValue: typeStr) ?? .breakTime
            return TimelineBlock(startMinute: start, endMinute: end, type: type)
        }
    }

    func testParseTimelineValid() {
        let blocks: [[String: Any]] = [
            ["start_minute": 540, "end_minute": 600, "type": "Deep Work"],
            ["start_minute": 600, "end_minute": 615, "type": "Break"]
        ]
        let result = parseTimeline(blocks)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].startMinute, 540)
        XCTAssertEqual(result[0].endMinute, 600)
        XCTAssertEqual(result[0].type, .deepWork)
        XCTAssertEqual(result[1].type, .breakTime)
    }

    func testParseTimelineMissingFieldsSkips() {
        let blocks: [[String: Any]] = [
            ["start_minute": 540, "end_minute": 600],  // missing type
        ]
        let result = parseTimeline(blocks)
        XCTAssertTrue(result.isEmpty)
    }

    func testParseTimelineUnknownTypeDefaultsToBreak() {
        let blocks: [[String: Any]] = [
            ["start_minute": 0, "end_minute": 60, "type": "InvalidType"]
        ]
        let result = parseTimeline(blocks)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].type, .breakTime)
    }
}

// MARK: - TimelineBar TotalSpan Tests

final class TimelineBarTotalSpanTests: XCTestCase {

    // Replicate totalSpan logic from TimelineBar
    private func totalSpan(blocks: [TimelineBlock]) -> Int {
        guard let first = blocks.first, let last = blocks.last else { return 1 }
        return max(last.endMinute - first.startMinute, 1)
    }

    func testEmptyBlocksReturnsOne() {
        XCTAssertEqual(totalSpan(blocks: []), 1)
    }

    func testSingleBlockSpan() {
        let blocks = [TimelineBlock(startMinute: 100, endMinute: 200, type: .deepWork)]
        XCTAssertEqual(totalSpan(blocks: blocks), 100)
    }

    func testMultipleBlocksSpan() {
        let blocks = [
            TimelineBlock(startMinute: 540, endMinute: 600, type: .deepWork),
            TimelineBlock(startMinute: 600, endMinute: 660, type: .communication),
            TimelineBlock(startMinute: 660, endMinute: 720, type: .shallowWork)
        ]
        XCTAssertEqual(totalSpan(blocks: blocks), 180) // 720 - 540
    }

    func testZeroDurationReturnsOne() {
        let blocks = [TimelineBlock(startMinute: 100, endMinute: 100, type: .breakTime)]
        XCTAssertEqual(totalSpan(blocks: blocks), 1) // max(0, 1) = 1
    }
}

// MARK: - Focus Ring Progress Tests

final class FocusRingProgressTests: XCTestCase {

    func testFocusRingProgressCalculation() {
        // focusRingProgress = Double(daily.focusScore) / 100.0
        XCTAssertEqual(Double(0) / 100.0, 0.0)
        XCTAssertEqual(Double(50) / 100.0, 0.5)
        XCTAssertEqual(Double(75) / 100.0, 0.75)
        XCTAssertEqual(Double(100) / 100.0, 1.0)
    }
}

// MARK: - Report Parsing Tests

final class ReportParsingTests: XCTestCase {

    func testReportPresentSetsValues() {
        let response: [String: Any] = [
            "focus_score": 82,
            "deep_work_minutes": 200,
            "distraction_minutes": 35,
            "shallow_work_minutes": 60,
            "mom_report": [
                "grade": "B+",
                "commentary": "Not bad, but you wasted time on Reddit."
            ] as [String: Any]
        ]

        var daily = DailyAnalytics()
        daily.focusScore = response["focus_score"] as? Int ?? 0
        daily.deepWorkMinutes = response["deep_work_minutes"] as? Int ?? 0
        daily.distractionMinutes = response["distraction_minutes"] as? Int ?? 0
        daily.shallowWorkMinutes = response["shallow_work_minutes"] as? Int ?? 0

        if let report = response["mom_report"] as? [String: Any] {
            daily.momGrade = report["grade"] as? String ?? ""
            daily.momCommentary = report["commentary"] as? String ?? ""
            daily.hasReport = true
        }

        XCTAssertEqual(daily.focusScore, 82)
        XCTAssertEqual(daily.deepWorkMinutes, 200)
        XCTAssertEqual(daily.distractionMinutes, 35)
        XCTAssertEqual(daily.shallowWorkMinutes, 60)
        XCTAssertEqual(daily.momGrade, "B+")
        XCTAssertEqual(daily.momCommentary, "Not bad, but you wasted time on Reddit.")
        XCTAssertTrue(daily.hasReport)
    }

    func testReportAbsentClearsValues() {
        let response: [String: Any] = [
            "focus_score": 50,
            "deep_work_minutes": 100
        ]

        var daily = DailyAnalytics()
        daily.focusScore = response["focus_score"] as? Int ?? 0

        if let report = response["mom_report"] as? [String: Any] {
            daily.momGrade = report["grade"] as? String ?? ""
            daily.momCommentary = report["commentary"] as? String ?? ""
            daily.hasReport = true
        } else {
            daily.momGrade = ""
            daily.momCommentary = ""
            daily.hasReport = false
        }

        XCTAssertEqual(daily.momGrade, "")
        XCTAssertEqual(daily.momCommentary, "")
        XCTAssertFalse(daily.hasReport)
    }
}
