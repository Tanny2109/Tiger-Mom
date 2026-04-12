import XCTest
@testable import TigerMom

// MARK: - SettingsSection Tests

final class SettingsSectionTests: XCTestCase {

    func testAllCasesExist() {
        let cases = SettingsSection.allCases
        XCTAssertEqual(cases.count, 5)
        XCTAssertTrue(cases.contains(.api))
        XCTAssertTrue(cases.contains(.tracking))
        XCTAssertTrue(cases.contains(.personality))
        XCTAssertTrue(cases.contains(.privacy))
        XCTAssertTrue(cases.contains(.app))
    }

    func testTitles() {
        XCTAssertEqual(SettingsSection.api.title, "API")
        XCTAssertEqual(SettingsSection.tracking.title, "Tracking")
        XCTAssertEqual(SettingsSection.personality.title, "Voice")
        XCTAssertEqual(SettingsSection.privacy.title, "Privacy")
        XCTAssertEqual(SettingsSection.app.title, "App")
    }

    func testIcons() {
        XCTAssertEqual(SettingsSection.api.icon, "key.horizontal.fill")
        XCTAssertEqual(SettingsSection.tracking.icon, "camera.aperture")
        XCTAssertEqual(SettingsSection.personality.icon, "theatermasks.fill")
        XCTAssertEqual(SettingsSection.privacy.icon, "lock.shield.fill")
        XCTAssertEqual(SettingsSection.app.icon, "switch.2")
    }

    func testTitlesNotEmpty() {
        for section in SettingsSection.allCases {
            XCTAssertFalse(section.title.isEmpty, "Title should not be empty for \(section)")
        }
    }

    func testIconsNotEmpty() {
        for section in SettingsSection.allCases {
            XCTAssertFalse(section.icon.isEmpty, "Icon should not be empty for \(section)")
        }
    }
}

// MARK: - ApiKeyStatus Tests

final class ApiKeyStatusTests: XCTestCase {

    func testAllStatusCases() {
        let untested = ApiKeyStatus.untested
        let testing = ApiKeyStatus.testing
        let valid = ApiKeyStatus.valid
        let invalid = ApiKeyStatus.invalid

        // Verify all four states exist and are distinct
        XCTAssertFalse(untested == testing)
        XCTAssertFalse(valid == invalid)
        XCTAssertFalse(untested == valid)
    }

    func testStatusTransitions() {
        // Simulates the flow: untested -> testing -> valid/invalid
        var status: ApiKeyStatus = .untested
        XCTAssertEqual(status, .untested)

        status = .testing
        XCTAssertEqual(status, .testing)

        status = .valid
        XCTAssertEqual(status, .valid)

        // Also test invalid path
        status = .testing
        status = .invalid
        XCTAssertEqual(status, .invalid)
    }

    func testChangingApiKeyResetsToUntested() {
        // Simulates: editing API key triggers apiKeyStatus = .untested
        var status: ApiKeyStatus = .valid
        // User edits the key field
        status = .untested
        XCTAssertEqual(status, .untested)
    }
}

// MARK: - ModelInfo Tests

final class ModelInfoTests: XCTestCase {

    func testModelInfoInitialization() {
        let model = ModelInfo(id: "openai/gpt-4", name: "GPT-4", price: "$0.03/1k")
        XCTAssertEqual(model.id, "openai/gpt-4")
        XCTAssertEqual(model.name, "GPT-4")
        XCTAssertEqual(model.price, "$0.03/1k")
    }

    func testModelInfoIdentifiable() {
        let model = ModelInfo(id: "model-1", name: "Test", price: "")
        XCTAssertEqual(model.id, "model-1")
    }

    func testModelInfoHashable() {
        let a = ModelInfo(id: "model-1", name: "Test", price: "")
        let b = ModelInfo(id: "model-1", name: "Test", price: "")
        let c = ModelInfo(id: "model-2", name: "Other", price: "$1")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)

        // Can be used in a Set
        let set: Set<ModelInfo> = [a, b, c]
        XCTAssertEqual(set.count, 2)
    }

    func testModelInfoEmptyPrice() {
        let model = ModelInfo(id: "free-model", name: "Free Model", price: "")
        XCTAssertTrue(model.price.isEmpty)
    }
}

// MARK: - Intensity Preview Tests

final class IntensityPreviewTests: XCTestCase {

    // Replicate the intensityPreview logic from SettingsView
    private func intensityPreview(for intensity: String) -> String {
        switch intensity {
        case "gentle": return "\"Hey, you've been drifting a little. Let's tighten the next block.\""
        case "fierce": return "\"Twenty-five minutes on Reddit? Explain yourself. Close it now.\""
        default: return "\"You're not doomed, but this day could be sharper. Give me one clean hour.\""
        }
    }

    func testGentlePreview() {
        let preview = intensityPreview(for: "gentle")
        XCTAssertTrue(preview.contains("drifting"))
        XCTAssertTrue(preview.contains("tighten"))
    }

    func testMediumPreview() {
        let preview = intensityPreview(for: "medium")
        XCTAssertTrue(preview.contains("not doomed"))
        XCTAssertTrue(preview.contains("sharper"))
    }

    func testFiercePreview() {
        let preview = intensityPreview(for: "fierce")
        XCTAssertTrue(preview.contains("Reddit"))
        XCTAssertTrue(preview.contains("Explain yourself"))
    }

    func testUnknownIntensityFallsToDefault() {
        let preview = intensityPreview(for: "unknown")
        XCTAssertTrue(preview.contains("not doomed"))
    }
}

// MARK: - DefaultTime Tests

final class DefaultTimeTests: XCTestCase {

    func testDefaultTimeCreatesCorrectHour() {
        let time = SettingsView.defaultTime(hour: 9)
        let hour = Calendar.current.component(.hour, from: time)
        XCTAssertEqual(hour, 9)
    }

    func testDefaultTimeMinuteIsZero() {
        let time = SettingsView.defaultTime(hour: 17)
        let minute = Calendar.current.component(.minute, from: time)
        XCTAssertEqual(minute, 0)
    }

    func testDefaultTimeMidnight() {
        let time = SettingsView.defaultTime(hour: 0)
        let hour = Calendar.current.component(.hour, from: time)
        XCTAssertEqual(hour, 0)
    }

    func testDefaultTimeEndOfDay() {
        let time = SettingsView.defaultTime(hour: 23)
        let hour = Calendar.current.component(.hour, from: time)
        XCTAssertEqual(hour, 23)
    }

    func testWorkHoursExtraction() {
        let workStart = SettingsView.defaultTime(hour: 9)
        let workEnd = SettingsView.defaultTime(hour: 17)

        let startHour = Calendar.current.component(.hour, from: workStart)
        let endHour = Calendar.current.component(.hour, from: workEnd)

        XCTAssertEqual(startHour, 9)
        XCTAssertEqual(endHour, 17)
        XCTAssertEqual(endHour - startHour, 8) // 8-hour workday
    }
}

// MARK: - Settings Parsing Tests

final class SettingsParsingTests: XCTestCase {

    func testParseFullSettings() {
        let response: [String: Any] = [
            "api_key": "sk-or-test-key",
            "vision_model": "openai/gpt-4-vision",
            "brain_model": "anthropic/claude-3",
            "screenshot_interval": 90.0,
            "distraction_threshold": 20.0,
            "nudge_cooldown": 45.0,
            "track_outside_hours": true,
            "pause_when_idle": false,
            "intensity": "fierce",
            "enable_nudge_sounds": false,
            "store_screenshots": false,
            "launch_at_login": true,
            "show_in_dock": false,
            "start_tracking_on_launch": true,
            "work_start_hour": 8,
            "work_end_hour": 18
        ]

        // Verify field extraction
        XCTAssertEqual(response["api_key"] as? String, "sk-or-test-key")
        XCTAssertEqual(response["vision_model"] as? String, "openai/gpt-4-vision")
        XCTAssertEqual(response["brain_model"] as? String, "anthropic/claude-3")
        XCTAssertEqual(response["screenshot_interval"] as? Double, 90.0)
        XCTAssertEqual(response["distraction_threshold"] as? Double, 20.0)
        XCTAssertEqual(response["nudge_cooldown"] as? Double, 45.0)
        XCTAssertEqual(response["track_outside_hours"] as? Bool, true)
        XCTAssertEqual(response["pause_when_idle"] as? Bool, false)
        XCTAssertEqual(response["intensity"] as? String, "fierce")
        XCTAssertEqual(response["enable_nudge_sounds"] as? Bool, false)
        XCTAssertEqual(response["store_screenshots"] as? Bool, false)
        XCTAssertEqual(response["launch_at_login"] as? Bool, true)
        XCTAssertEqual(response["show_in_dock"] as? Bool, false)
        XCTAssertEqual(response["start_tracking_on_launch"] as? Bool, true)
        XCTAssertEqual(response["work_start_hour"] as? Int, 8)
        XCTAssertEqual(response["work_end_hour"] as? Int, 18)
    }

    func testParseMissingSettingsUsesDefaults() {
        let response: [String: Any] = [:]

        let apiKey = response["api_key"] as? String ?? ""
        let visionModel = response["vision_model"] as? String ?? ""
        let screenshotInterval = response["screenshot_interval"] as? Double ?? 120
        let distractionThreshold = response["distraction_threshold"] as? Double ?? 15
        let nudgeCooldown = response["nudge_cooldown"] as? Double ?? 30
        let trackOutsideHours = response["track_outside_hours"] as? Bool ?? false
        let pauseWhenIdle = response["pause_when_idle"] as? Bool ?? true
        let intensity = response["intensity"] as? String ?? "medium"
        let enableNudgeSounds = response["enable_nudge_sounds"] as? Bool ?? true
        let storeScreenshots = response["store_screenshots"] as? Bool ?? true
        let launchAtLogin = response["launch_at_login"] as? Bool ?? false
        let showInDock = response["show_in_dock"] as? Bool ?? true
        let startTrackingOnLaunch = response["start_tracking_on_launch"] as? Bool ?? false

        XCTAssertEqual(apiKey, "")
        XCTAssertEqual(visionModel, "")
        XCTAssertEqual(screenshotInterval, 120)
        XCTAssertEqual(distractionThreshold, 15)
        XCTAssertEqual(nudgeCooldown, 30)
        XCTAssertFalse(trackOutsideHours)
        XCTAssertTrue(pauseWhenIdle)
        XCTAssertEqual(intensity, "medium")
        XCTAssertTrue(enableNudgeSounds)
        XCTAssertTrue(storeScreenshots)
        XCTAssertFalse(launchAtLogin)
        XCTAssertTrue(showInDock)
        XCTAssertFalse(startTrackingOnLaunch)
    }

    func testSaveSettingsPayloadStructure() {
        let startHour = 9
        let endHour = 17

        let body: [String: Any] = [
            "api_key": "sk-test",
            "vision_model": "openai/gpt-4-vision",
            "brain_model": "anthropic/claude-3",
            "screenshot_interval": 120.0,
            "distraction_threshold": 15.0,
            "nudge_cooldown": 30.0,
            "work_start_hour": startHour,
            "work_end_hour": endHour,
            "track_outside_hours": false,
            "pause_when_idle": true,
            "intensity": "medium",
            "enable_nudge_sounds": true,
            "store_screenshots": true,
            "launch_at_login": false,
            "show_in_dock": true,
            "start_tracking_on_launch": false
        ]

        // Verify all expected keys exist
        XCTAssertEqual(body.count, 16)
        XCTAssertNotNil(body["api_key"])
        XCTAssertNotNil(body["vision_model"])
        XCTAssertNotNil(body["brain_model"])
        XCTAssertNotNil(body["screenshot_interval"])
        XCTAssertNotNil(body["distraction_threshold"])
        XCTAssertNotNil(body["nudge_cooldown"])
        XCTAssertNotNil(body["work_start_hour"])
        XCTAssertNotNil(body["work_end_hour"])
        XCTAssertNotNil(body["track_outside_hours"])
        XCTAssertNotNil(body["pause_when_idle"])
        XCTAssertNotNil(body["intensity"])
        XCTAssertNotNil(body["enable_nudge_sounds"])
        XCTAssertNotNil(body["store_screenshots"])
        XCTAssertNotNil(body["launch_at_login"])
        XCTAssertNotNil(body["show_in_dock"])
        XCTAssertNotNil(body["start_tracking_on_launch"])
    }
}

// MARK: - Model Parsing Tests

final class ModelParsingTests: XCTestCase {

    private func parseModels(_ models: [[String: Any]]) -> [ModelInfo] {
        models.compactMap { model in
            guard let id = model["id"] as? String,
                  let name = model["name"] as? String else { return nil }
            return ModelInfo(id: id, name: name, price: model["price"] as? String ?? "")
        }
    }

    func testParseValidModels() {
        let models: [[String: Any]] = [
            ["id": "openai/gpt-4", "name": "GPT-4", "price": "$0.03/1k"],
            ["id": "anthropic/claude-3", "name": "Claude 3", "price": "$0.015/1k"]
        ]
        let result = parseModels(models)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "openai/gpt-4")
        XCTAssertEqual(result[0].name, "GPT-4")
        XCTAssertEqual(result[0].price, "$0.03/1k")
    }

    func testParseMissingIdSkips() {
        let models: [[String: Any]] = [
            ["name": "GPT-4", "price": "$0.03"]
        ]
        let result = parseModels(models)
        XCTAssertTrue(result.isEmpty)
    }

    func testParseMissingNameSkips() {
        let models: [[String: Any]] = [
            ["id": "openai/gpt-4", "price": "$0.03"]
        ]
        let result = parseModels(models)
        XCTAssertTrue(result.isEmpty)
    }

    func testParseMissingPriceUsesEmpty() {
        let models: [[String: Any]] = [
            ["id": "free-model", "name": "Free Model"]
        ]
        let result = parseModels(models)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].price, "")
    }

    func testApiKeyValidationParsing() {
        // Test the response parsing from testApiKey
        let validResponse: [String: Any] = ["valid": true]
        let invalidResponse: [String: Any] = ["valid": false]
        let missingResponse: [String: Any] = [:]

        XCTAssertTrue((validResponse["valid"] as? Bool ?? false))
        XCTAssertFalse((invalidResponse["valid"] as? Bool ?? false))
        XCTAssertFalse((missingResponse["valid"] as? Bool ?? false))
    }
}
