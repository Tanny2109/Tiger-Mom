import XCTest
import SwiftUI
@testable import TigerMom

// MARK: - Color Hex Extension Tests

final class ColorHexTests: XCTestCase {

    func testBlackColor() {
        let color = Color(hex: 0x000000)
        // Verify it doesn't crash and creates a valid color
        XCTAssertNotNil(color)
    }

    func testWhiteColor() {
        let color = Color(hex: 0xFFFFFF)
        XCTAssertNotNil(color)
    }

    func testPureRed() {
        let color = Color(hex: 0xFF0000)
        XCTAssertNotNil(color)
    }

    func testPureGreen() {
        let color = Color(hex: 0x00FF00)
        XCTAssertNotNil(color)
    }

    func testPureBlue() {
        let color = Color(hex: 0x0000FF)
        XCTAssertNotNil(color)
    }

    func testCustomAlpha() {
        let color = Color(hex: 0xFF0000, alpha: 0.5)
        XCTAssertNotNil(color)
    }

    func testPaletteColors() {
        // Verify palette hex values create valid colors
        XCTAssertNotNil(Color(hex: 0x0A0A0B))  // background
        XCTAssertNotNil(Color(hex: 0xF5C563))  // gold
        XCTAssertNotNil(Color(hex: 0xE87B6B))  // coral
        XCTAssertNotNil(Color(hex: 0x3ECF8E))  // jade
        XCTAssertNotNil(Color(hex: 0x7DD3FC))  // mist
        XCTAssertNotNil(Color(hex: 0xA78BFA))  // violet
    }
}

// MARK: - Int Duration Extension Tests

final class IntDurationTests: XCTestCase {

    func testZeroMinutes() {
        XCTAssertEqual(0.tigerDuration, "0m")
    }

    func testMinutesOnly() {
        XCTAssertEqual(30.tigerDuration, "30m")
        XCTAssertEqual(59.tigerDuration, "59m")
    }

    func testExactHour() {
        XCTAssertEqual(60.tigerDuration, "1h 0m")
    }

    func testHoursAndMinutes() {
        XCTAssertEqual(90.tigerDuration, "1h 30m")
        XCTAssertEqual(150.tigerDuration, "2h 30m")
    }

    func testMultipleHours() {
        XCTAssertEqual(180.tigerDuration, "3h 0m")
        XCTAssertEqual(480.tigerDuration, "8h 0m")
    }

    func testLargeDuration() {
        XCTAssertEqual(1440.tigerDuration, "24h 0m")
    }

    func testOneMinute() {
        XCTAssertEqual(1.tigerDuration, "1m")
    }
}

// MARK: - Int Clock Extension Tests

final class IntClockTests: XCTestCase {

    func testZeroMinutes() {
        XCTAssertEqual(0.tigerClock, "0:00")
    }

    func testMinutesOnly() {
        XCTAssertEqual(5.tigerClock, "0:05")
        XCTAssertEqual(30.tigerClock, "0:30")
    }

    func testExactHour() {
        XCTAssertEqual(60.tigerClock, "1:00")
    }

    func testHoursAndMinutes() {
        XCTAssertEqual(90.tigerClock, "1:30")
        XCTAssertEqual(125.tigerClock, "2:05")
    }

    func testLeadingZeroPadding() {
        XCTAssertEqual(61.tigerClock, "1:01")
        XCTAssertEqual(62.tigerClock, "1:02")
        XCTAssertEqual(69.tigerClock, "1:09")
    }

    func testLargeClock() {
        XCTAssertEqual(600.tigerClock, "10:00")
    }
}

// MARK: - TigerSpacing Tests

final class TigerSpacingTests: XCTestCase {

    func testSpacingValues() {
        XCTAssertEqual(TigerSpacing.xs, 4)
        XCTAssertEqual(TigerSpacing.sm, 8)
        XCTAssertEqual(TigerSpacing.md, 12)
        XCTAssertEqual(TigerSpacing.lg, 16)
        XCTAssertEqual(TigerSpacing.xl, 20)
        XCTAssertEqual(TigerSpacing.xxl, 24)
        XCTAssertEqual(TigerSpacing.xxxl, 32)
    }

    func testSpacingIsMonotonicallyIncreasing() {
        XCTAssertLessThan(TigerSpacing.xs, TigerSpacing.sm)
        XCTAssertLessThan(TigerSpacing.sm, TigerSpacing.md)
        XCTAssertLessThan(TigerSpacing.md, TigerSpacing.lg)
        XCTAssertLessThan(TigerSpacing.lg, TigerSpacing.xl)
        XCTAssertLessThan(TigerSpacing.xl, TigerSpacing.xxl)
        XCTAssertLessThan(TigerSpacing.xxl, TigerSpacing.xxxl)
    }

    func testSpacingValuesArePositive() {
        XCTAssertGreaterThan(TigerSpacing.xs, 0)
        XCTAssertGreaterThan(TigerSpacing.sm, 0)
        XCTAssertGreaterThan(TigerSpacing.md, 0)
        XCTAssertGreaterThan(TigerSpacing.lg, 0)
        XCTAssertGreaterThan(TigerSpacing.xl, 0)
        XCTAssertGreaterThan(TigerSpacing.xxl, 0)
        XCTAssertGreaterThan(TigerSpacing.xxxl, 0)
    }
}

// MARK: - TigerPalette Tests

final class TigerPaletteTests: XCTestCase {

    func testPaletteColorsExist() {
        // Verify all palette colors can be accessed without crashing
        _ = TigerPalette.background
        _ = TigerPalette.backgroundSecondary
        _ = TigerPalette.backgroundTertiary
        _ = TigerPalette.surface
        _ = TigerPalette.surfaceElevated
        _ = TigerPalette.surfaceHover
        _ = TigerPalette.panel
        _ = TigerPalette.panelStrong
        _ = TigerPalette.border
        _ = TigerPalette.borderStrong
        _ = TigerPalette.line
        _ = TigerPalette.textPrimary
        _ = TigerPalette.textSecondary
        _ = TigerPalette.textMuted
        _ = TigerPalette.textDisabled
        _ = TigerPalette.gold
        _ = TigerPalette.amber
        _ = TigerPalette.coral
        _ = TigerPalette.jade
        _ = TigerPalette.mist
        _ = TigerPalette.violet
        _ = TigerPalette.obsidian
    }
}

// MARK: - TigerTypography Tests

final class TigerTypographyTests: XCTestCase {

    func testTypographyFontsExist() {
        _ = TigerTypography.displayLarge
        _ = TigerTypography.displayMedium
        _ = TigerTypography.headline
        _ = TigerTypography.title
        _ = TigerTypography.body
        _ = TigerTypography.bodySmall
        _ = TigerTypography.caption
        _ = TigerTypography.overline
    }
}

// MARK: - TigerButtonProminence Tests

final class TigerButtonProminenceTests: XCTestCase {

    func testAllCasesExist() {
        let primary = TigerButtonProminence.primary
        let secondary = TigerButtonProminence.secondary
        let quiet = TigerButtonProminence.quiet

        // All cases should be distinct
        XCTAssertFalse(primary == secondary)
        XCTAssertFalse(secondary == quiet)
        XCTAssertFalse(primary == quiet)
    }
}
