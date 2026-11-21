//
//  MemoryTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// メモリ使用量の詳細を表示するタブ。
struct MemoryTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                summaryCard
                memoryCompositionCard

                MetricCard(
                    title: "使用率の推移",
                    value: latestMemory.map { MetricFormatter.percentage($0.usageRatio) } ?? "--",
                    subtitle: memoryTotalSubtitle,
                    tint: .teal
                ) {
                    SparklineChart(snapshots: history, tint: .teal, yDomain: 0...100) { snapshot in
                        snapshot.memory.usageRatio * 100
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            GaugeView(value: latestMemory?.pressure ?? 0, title: "圧力", tint: pressureTint)

            VStack(alignment: .leading, spacing: 8) {
                memoryText("使用中", bytes: latestMemory?.usedBytes)
                memoryText("キャッシュ", bytes: latestMemory?.cachedBytes)
                memoryText("空き", bytes: latestMemory?.freeBytes)
                memoryText("スワップ", bytes: latestMemory?.swapUsedBytes)
            }
        }
        .padding(12)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: .teal,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }

    private var memoryCompositionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("メモリ内訳")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.86))

            GeometryReader { proxy in
                HStack(spacing: 2) {
                    segment(width: proxy.size.width, bytes: appBytes, color: .teal)
                    segment(width: proxy.size.width, bytes: wiredBytes, color: .blue)
                    segment(width: proxy.size.width, bytes: compressedBytes, color: .purple)
                    segment(width: proxy.size.width, bytes: cachedBytes, color: .white.opacity(0.32))
                    segment(width: proxy.size.width, bytes: freeBytes, color: .white.opacity(0.10))
                }
            }
            .frame(height: 10)
            .clipShape(Capsule(style: .continuous))
            .animation(
                PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: latestMemory?.usedBytes)

            HStack(spacing: 10) {
                legend("App", color: .teal)
                legend("確保", color: .blue)
                legend("圧縮", color: .purple)
                legend("キャッシュ", color: .white.opacity(0.45))
                legend("空き", color: .white.opacity(0.18))
            }
        }
        .padding(12)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: .teal,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }

    private var latestMemory: MemoryMetrics? {
        coordinator.latestSnapshot?.memory
    }

    private var pressureTint: Color {
        let pressure = latestMemory?.pressure ?? 0
        if pressure >= 0.75 {
            return .red
        }
        if pressure >= 0.50 {
            return .orange
        }
        return .teal
    }

    private var memoryTotalSubtitle: String {
        guard let latestMemory else {
            return "取得待ち"
        }

        let used = MetricFormatter.bytes(latestMemory.usedBytes, dataUnit: preferences.dataUnit)
        let total = MetricFormatter.bytes(latestMemory.totalBytes, dataUnit: preferences.dataUnit)
        return "\(used) / \(total)"
    }

    private var appBytes: UInt64 {
        latestMemory?.appBytes ?? 0
    }

    private var wiredBytes: UInt64 {
        latestMemory?.wiredBytes ?? 0
    }

    private var compressedBytes: UInt64 {
        latestMemory?.compressedBytes ?? 0
    }

    private var cachedBytes: UInt64 {
        latestMemory?.cachedBytes ?? 0
    }

    private var freeBytes: UInt64 {
        latestMemory?.freeBytes ?? 0
    }

    private func memoryText(_ title: String, bytes: UInt64?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(bytes.map { MetricFormatter.bytes($0, dataUnit: preferences.dataUnit) } ?? "--")
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .font(.system(size: 11, weight: .medium))
    }

    private func segment(width: CGFloat, bytes: UInt64, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(width * CGFloat(ratio(bytes)), 1))
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func ratio(_ bytes: UInt64) -> Double {
        guard let total = latestMemory?.totalBytes, total > 0 else {
            return 0
        }

        return Swift.min(Double(bytes) / Double(total), 1)
    }
}
