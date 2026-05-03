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
        #expect(DisplayItem.cpuTemperature.isAvailableInPhase1)
        #expect(!DisplayItem.gpuUsage.isAvailableInPhase1)
    }

    @Test("ガラス表現は透過度とブラー設定を反映する")
    func glassStyleRespondsToOpacityAndBlur() {
        let lowBlur = PulseGlassStyle.backdropMaterialOpacity(for: 0.28, blurRadius: 2)
        let highBlur = PulseGlassStyle.backdropMaterialOpacity(for: 0.28, blurRadius: 30)
        let lowOpacity = PulseGlassStyle.panelMaterialOpacity(for: 0.2, blurRadius: 20)
        let highOpacity = PulseGlassStyle.panelMaterialOpacity(for: 0.8, blurRadius: 20)

        #expect(highBlur > lowBlur)
        #expect(highOpacity > lowOpacity)
    }

    @Test("黒基調ガラスは通常トーンより濃く表示される")
    func clearBlackGlassToneIsDarkerThanAdaptiveTone() {
        #expect(
            PulseGlassTone.clearBlack.baseOpacityMultiplier > PulseGlassTone.adaptive.baseOpacityMultiplier
        )
        #expect(PulseGlassTone.clearBlack.shadowOpacity > PulseGlassTone.adaptive.shadowOpacity)
    }
}
