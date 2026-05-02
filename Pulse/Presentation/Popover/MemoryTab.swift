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

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    GaugeView(value: coordinator.latestSnapshot?.memory.pressure ?? 0, title: "圧力", tint: .green)
                    VStack(alignment: .leading, spacing: 8) {
                        memoryText("使用中", bytes: usedBytes)
                        memoryText("キャッシュ", bytes: cachedBytes)
                        memoryText("空き", bytes: freeBytes)
                        memoryText("Swap", bytes: coordinator.latestSnapshot?.memory.swapUsedBytes ?? 0)
                    }
                }

                memoryComposition

                MetricCard(
                    title: "使用率",
                    value: MetricFormatter.percentage(coordinator.latestSnapshot?.memory.usageRatio ?? 0),
                    tint: .green
                ) {
                    SparklineChart(snapshots: history, tint: .green, yDomain: 0...100) { snapshot in
                        snapshot.memory.usageRatio * 100
                    }
                }
            }
            .padding(14)
        }
    }

    private var memoryComposition: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内訳")
                .font(.system(size: 13, weight: .semibold))
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    segment(width: proxy.size.width, bytes: appBytes, color: .blue)
                    segment(width: proxy.size.width, bytes: wiredBytes, color: .purple)
                    segment(width: proxy.size.width, bytes: compressedBytes, color: .green)
                    segment(width: proxy.size.width, bytes: cachedBytes, color: .orange)
                    segment(width: proxy.size.width, bytes: freeBytes, color: .secondary.opacity(0.6))
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            HStack {
                legend("App", color: .blue)
                legend("Wired", color: .purple)
                legend("Comp", color: .green)
                legend("Cache", color: .orange)
                legend("Free", color: .secondary)
            }
        }
    }

    private var latestMemory: MemoryMetrics? {
        coordinator.latestSnapshot?.memory
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

    private var usedBytes: UInt64 {
        appBytes + wiredBytes + compressedBytes
    }

    private func memoryText(_ title: String, bytes: UInt64) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(MetricFormatter.bytes(bytes, dataUnit: preferences.dataUnit))
                .monospacedDigit()
        }
        .font(.system(size: 12, weight: .medium))
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
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func ratio(_ bytes: UInt64) -> Double {
        guard let total = latestMemory?.totalBytes, total > 0 else {
            return 0
        }

        return Swift.min(Double(bytes) / Double(total), 1)
    }
}
