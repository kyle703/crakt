//
//  DifficultyIndexTests.swift
//  craktTests
//
//  Created by Kyle Thompson on 12/19/24.
//

import XCTest
@testable import crakt

class DifficultyIndexTests: XCTestCase {

    // MARK: - French Grade DI Tests

    func testFrenchGradeDITable() {
        // Test canonical French grades have correct DI values
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("4a"), 0)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("4b"), 10)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("4c"), 20)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("5a"), 30)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("5b"), 40)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("5c"), 50)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("6a"), 60)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("6b"), 80)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("7a"), 120)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("7b"), 140)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("8a"), 180)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("8b"), 200)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("9a"), 240)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("9b"), 260)
        XCTAssertEqual(DifficultyIndex.diForFrenchGrade("9c"), 280)
    }

    func testFrenchGradeForDI() {
        // Test reverse lookup: DI → French grade
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(0), "4a")
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(10), "4b")
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(60), "6a")
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(140), "7b")
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(280), "9c")

        // Test edge cases
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(-10), "4a") // Below range
        XCTAssertEqual(DifficultyIndex.frenchGradeForDI(300), "9c") // Above range
    }

    // MARK: - YDS ↔ French Conversion Tests

    func testYDStoFrenchConversion() {
        // Test Table A conversions
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.6"], "4c")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.8"], "5b")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.10a"], "6a")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.11c"], "7a")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.12a"], "7b")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.13a"], "8a")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.14c"], "9a")
        XCTAssertEqual(DifficultyIndex.ydsToFrench["5.15c"], "9c")
    }

    func testYDSDITable() {
        // Test YDS grades convert to correct DI values
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "5.6", system: .yds, climbType: .lead), 20)  // 4c
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "5.8", system: .yds, climbType: .lead), 40)  // 5b
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "5.10a", system: .yds, climbType: .lead), 60) // 6a
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "5.12a", system: .yds, climbType: .lead), 140) // 7b
    }

    // MARK: - V-Scale ↔ French Conversion Tests

    func testVScaleToFrenchAnchors() {
        // Test Table C anchor points
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V0"], "6a")
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V3"], "6b+")
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V5"], "7a")
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V8"], "7b+")
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V10"], "7c+")
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V14"], "8b+")
        XCTAssertEqual(DifficultyIndex.vToFrenchAnchors["V17"], "9a")
    }

    func testVScaleDITable() {
        // Test V-scale grades convert to correct DI values
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "V0", system: .vscale, climbType: .boulder), 60)   // 6a
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "V3", system: .vscale, climbType: .boulder), 90)   // 6b+
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "V5", system: .vscale, climbType: .boulder), 120)  // 7a
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "V8", system: .vscale, climbType: .boulder), 150)  // 7b+
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "V10", system: .vscale, climbType: .boulder), 170) // 7c+
    }

    // MARK: - Font ↔ V-Scale Conversion Tests

    func testFontToVScaleTable() {
        // Test Table B conversions
        XCTAssertEqual(DifficultyIndex.vToFont["V0"], "5")
        XCTAssertEqual(DifficultyIndex.vToFont["V3"], "6A+")
        XCTAssertEqual(DifficultyIndex.vToFont["V6"], "7A")
        XCTAssertEqual(DifficultyIndex.vToFont["V8"], "7B")
        XCTAssertEqual(DifficultyIndex.vToFont["V10"], "7C+")
    }

    func testFontDITable() {
        // Test Font grades convert to correct DI values via V-scale bridge
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "5", system: .font, climbType: .boulder), 60)      // V0 → 6a
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "6A+", system: .font, climbType: .boulder), 90)   // V3 → 6b+
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "7A", system: .font, climbType: .boulder), 130)   // V6 → 7a+
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "7B", system: .font, climbType: .boulder), 150)   // V8 → 7b+
    }

    // MARK: - Cross-System Conversion Tests

    func testCrossSystemConversions() {
        // Test conversions between different systems

        // V-Scale to YDS
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "V0", fromSystem: .vscale, fromType: .boulder,
                                                  toSystem: .yds, toType: .lead), "5.10a") // Both 6a

        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "V3", fromSystem: .vscale, fromType: .boulder,
                                                  toSystem: .yds, toType: .lead), "5.10c") // V3=6b+ ≈ 5.10c=6b

        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "V5", fromSystem: .vscale, fromType: .boulder,
                                                  toSystem: .yds, toType: .lead), "5.11c") // V5=7a ≈ 5.11c=7a

        // YDS to V-Scale
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "5.10a", fromSystem: .yds, fromType: .lead,
                                                  toSystem: .vscale, toType: .boulder), "V0") // Both 6a

        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "5.11c", fromSystem: .yds, fromType: .lead,
                                                  toSystem: .vscale, toType: .boulder), "V5") // Both 7a

        // Font to YDS
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "7A", fromSystem: .font, fromType: .boulder,
                                                  toSystem: .yds, toType: .lead), "5.11b") // 7A ≈ 5.11b=6c+
    }

    // MARK: - Round-trip Tests

    func testRoundTripConversions() {
        // Test that converting grade A → B → A returns the original grade

        // French round-trips
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "6a", fromSystem: .french, fromType: .lead,
                                                  toSystem: .french, toType: .lead), "6a")

        // YDS round-trips
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "5.10a", fromSystem: .yds, fromType: .lead,
                                                  toSystem: .yds, toType: .lead), "5.10a")

        // V-Scale round-trips
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "V5", fromSystem: .vscale, fromType: .boulder,
                                                  toSystem: .vscale, toType: .boulder), "V5")

        // Font round-trips
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "7A", fromSystem: .font, fromType: .boulder,
                                                  toSystem: .font, toType: .boulder), "7A")
    }

    // MARK: - Monotonicity Tests

    func testMonotonicity() {
        // Test that higher grades in one system convert to higher or equal grades in another system

        // V-Scale to YDS should be monotonic
        let vGrades = ["V0", "V1", "V2", "V3", "V4", "V5"]
        let ydsGrades = ["5.10a", "5.10b", "5.10c", "5.10d", "5.11a", "5.11c"]

        for (vGrade, expectedYDS) in zip(vGrades, ydsGrades) {
            let converted = DifficultyIndex.convertGrade(fromGrade: vGrade, fromSystem: .vscale, fromType: .boulder,
                                                       toSystem: .yds, toType: .lead)
            XCTAssertEqual(converted, expectedYDS, "V-Scale \(vGrade) should convert to YDS \(expectedYDS)")
        }
    }

    // MARK: - Edge Cases

    func testInvalidGrades() {
        // Test handling of invalid grades
        XCTAssertNil(DifficultyIndex.normalizeToDI(grade: "invalid", system: .french, climbType: .lead))
        XCTAssertNil(DifficultyIndex.normalizeToDI(grade: "X99", system: .vscale, climbType: .boulder))
        XCTAssertNil(DifficultyIndex.normalizeToDI(grade: "Z1", system: .yds, climbType: .lead))
    }

    func testCircuitGradesNotSupported() {
        // Circuit grades should not have DI conversions
        XCTAssertNil(DifficultyIndex.normalizeToDI(grade: "someColor", system: .circuit, climbType: .boulder))
    }

    // MARK: - Protocol Extension Tests

    func testProtocolNormalizedDifficulty() {
        let french = FrenchGrade()
        let vscale = VGrade()
        let yds = YDS()

        // Test that protocol methods use DI system
        XCTAssertEqual(french.normalizedDifficulty(for: "6a"), 60.0 / 280.0) // DI 60 → 0.214
        XCTAssertEqual(vscale.normalizedDifficulty(for: "V0"), 60.0 / 280.0) // V0 → 6a → DI 60 → 0.214
        XCTAssertEqual(yds.normalizedDifficulty(for: "5.10a"), 60.0 / 280.0) // 5.10a → 6a → DI 60 → 0.214
    }

    func testProtocolGradeForNormalizedDifficulty() {
        let french = FrenchGrade()
        let vscale = VGrade()
        let yds = YDS()

        // Test reverse conversion through protocol
        let difficulty = 60.0 / 280.0 // DI 60 = 6a
        XCTAssertEqual(french.grade(forNormalizedDifficulty: difficulty), "6a")
        XCTAssertEqual(vscale.grade(forNormalizedDifficulty: difficulty), "V0")
        XCTAssertEqual(yds.grade(forNormalizedDifficulty: difficulty), "5.10a")
    }

    // MARK: - Comprehensive Example Conversions

    func testExampleConversionsFromFeatureDoc() {
        // Test examples from FEATURE_GRADE_SYSTEM_DI.md

        // V4 (boulder) → 6c (route)
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "V4", fromSystem: .vscale, fromType: .boulder,
                                                  toSystem: .french, toType: .lead), "6c")

        // V5 (boulder) → 7a (route)
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "V5", fromSystem: .vscale, fromType: .boulder,
                                                  toSystem: .french, toType: .lead), "7a")

        // 5.12b (route) → V8 (boulder) approximately
        XCTAssertEqual(DifficultyIndex.convertGrade(fromGrade: "5.12b", fromSystem: .yds, fromType: .lead,
                                                  toSystem: .vscale, toType: .boulder), "V8")

        // 6b (route) → DI 80
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "6b", system: .french, climbType: .lead), 80)

        // 6b+ (route) → DI 90
        XCTAssertEqual(DifficultyIndex.normalizeToDI(grade: "6b+", system: .french, climbType: .lead), 90)
    }
}
