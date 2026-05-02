//
//  PulseTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing
@testable import Pulse

@Suite("Pulse 初期テスト")
struct PulseTests {
    @Test("ログカテゴリ名が保持される")
    func logCategoryRawValue() {
        #expect(LogCategory.app.rawValue == "App")
    }

    @Test("Phase 1 の表示項目が判定できる")
    func phaseOneDisplayItems() {
        #expect(DisplayItem.cpuUsage.isAvailableInPhase1)
        #expect(DisplayItem.memoryUsage.displayName == "メモリ使用率")
        #expect(!DisplayItem.cpuTemperature.isAvailableInPhase1)
        #expect(!DisplayItem.gpuUsage.isAvailableInPhase1)
    }
}
