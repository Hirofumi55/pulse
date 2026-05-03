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
        #expect(
            PulseGlassTone.clearBlack.backdropBaseOpacity(for: 0.28)
                > PulseGlassTone.adaptive.backdropBaseOpacity(for: 0.28)
        )
        #expect(
            PulseGlassTone.clearBlack.backdropBaseOpacity(for: 0.8)
                > PulseGlassTone.clearBlack.backdropBaseOpacity(for: 0.2)
        )
        #expect(
            PulseGlassTone.clearBlack.panelBaseOpacity(for: 0.42)
                > PulseGlassTone.adaptive.panelBaseOpacity(for: 0.42)
        )
        #expect(PulseGlassTone.clearBlack.shadowOpacity > PulseGlassTone.adaptive.shadowOpacity)
    }

    @Test("ポップオーバーマテリアルは透過度とブラー設定を反映する")
    func popoverMaterialRespondsToOpacityAndBlur() {
        let lowOpacity = PulseGlassStyle.popoverWindowMaterialAlpha(for: 0.2, blurRadius: 14)
        let highOpacity = PulseGlassStyle.popoverWindowMaterialAlpha(for: 0.8, blurRadius: 14)
        let lowBlur = PulseGlassStyle.popoverWindowMaterialAlpha(for: 0.4, blurRadius: 2)
        let highBlur = PulseGlassStyle.popoverWindowMaterialAlpha(for: 0.4, blurRadius: 30)
        let lowBackground = PulseGlassStyle.popoverWindowBackgroundAlpha(for: 0.2)
        let highBackground = PulseGlassStyle.popoverWindowBackgroundAlpha(for: 0.8)

        #expect(highOpacity > lowOpacity)
        #expect(highBlur > lowBlur)
        #expect(highBackground > lowBackground)
        #expect(lowBackground > 0.5)
        #expect(PulseGlassTone.clearBlack.backdropBlurRadius(for: 30) > 0)
    }
}
