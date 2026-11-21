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
        #expect(!DisplayItem.gpuUsage.isAvailableInPhase1)
    }

    @Test("ガラス表現は透過度とブラー設定を反映する")
    func glassStyleRespondsToOpacityAndBlur() {
        let lowBlur = PulseGlassStyle.backdropMaterialOpacity(for: 0.28, blurRadius: 0)
        let highBlur = PulseGlassStyle.backdropMaterialOpacity(for: 0.28, blurRadius: 30)
        let lowOpacity = PulseGlassStyle.panelMaterialOpacity(for: 0.08, blurRadius: 20)
        let highOpacity = PulseGlassStyle.panelMaterialOpacity(for: 0.9, blurRadius: 20)

        #expect(lowBlur == 0)
        #expect(highBlur - lowBlur > 0.5)
        #expect(highOpacity - lowOpacity > 0.2)
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

    @Test("ポップオーバー背景は透過度設定を十分な幅で反映する")
    func popoverBackdropRespondsToOpacity() {
        let lowOpacity = PulseGlassTone.clearBlack.backdropBaseOpacity(for: 0.08)
        let highOpacity = PulseGlassTone.clearBlack.backdropBaseOpacity(for: 0.9)

        #expect(lowOpacity < 0.25)
        #expect(highOpacity > 0.7)
        #expect(highOpacity - lowOpacity > 0.5)
    }

    @Test("VolumeInfo と NetworkMetrics は境界値で安全に計算される")
    func domainMetricsHandleBoundaryValuesSafely() {
        let volume = VolumeInfo(id: "/Volumes/Test", name: "Test", totalBytes: 100, freeBytes: 150, isInternal: false)
        #expect(volume.usedBytes == 0)
        #expect(volume.usageRatio == 0)

        let network = NetworkMetrics(interfaces: [
            InterfaceInfo(
                id: "en0",
                displayName: "en0",
                downloadBytesPerSecond: .max,
                uploadBytesPerSecond: .max,
                isActive: true
            ),
            InterfaceInfo(
                id: "en1",
                displayName: "en1",
                downloadBytesPerSecond: 10,
                uploadBytesPerSecond: 10,
                isActive: true
            ),
        ])
        #expect(network.totalDownloadBytesPerSecond == .max)
        #expect(network.totalUploadBytesPerSecond == .max)
        #expect(MetricFormatter.percentage(.nan) == "--")
        #expect(MetricFormatter.percentage(.infinity) == "--")
    }

    @Test("メモリの内訳が総量を超えても表示値が範囲内に収まる")
    func boundsMemoryUsage() {
        let memory = MemoryMetrics(
            totalBytes: 100, appBytes: 95, wiredBytes: .max, compressedBytes: 20,
            cachedBytes: 0, freeBytes: 0, swapUsedBytes: 0, pressure: 0
        )
        #expect(memory.usedBytes == 100)
        #expect(memory.usageRatio == 1)
        #expect(MetricFormatter.percentage(.greatestFiniteMagnitude) == "100%")
    }

    @Test("ポップオーバータブ構成と Reduce Motion 設定が正しく機能する")
    func popoverTabsAndMotionRespectAccessibility() {
        #expect(PopoverTab.allCases.map(\.title) == ["概要", "CPU", "メモリ", "ストレージ", "ネットワーク"])
        #expect(PulseMotion.resolve(PulseMotion.snappy, reduceMotion: true) == nil)
        #expect(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: false) != nil)
    }
}
