//
//  CPUTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// CPU 使用率の詳細を表示するタブ。
struct CPUTab: View {
    let coordinator: MetricsCoordinator

    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let coreColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    private var cpu: CPUMetrics? {
        coordinator.latestSnapshot?.cpu
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                summaryCard

                MetricCard(
                    title: "使用率の推移",
                    value: cpu.map { MetricFormatter.percentage($0.totalUsage) } ?? "--",
                    subtitle: cpu.map { "物理 \($0.physicalCoreCount) コア · 論理 \($0.logicalCoreCount) コア" } ?? "取得待ち",
                    tint: .blue
                ) {
                    SparklineChart(snapshots: history, tint: .blue, yDomain: 0...100) { snapshot in
                        snapshot.cpu.totalUsage * 100
                    }
                }

                coresCard
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            GaugeView(value: cpu?.totalUsage ?? 0, title: "合計", tint: .blue)

            VStack(alignment: .leading, spacing: 10) {
                usageRow("ユーザー", value: cpu?.userUsage ?? 0, color: .blue)
                usageRow("システム", value: cpu?.systemUsage ?? 0, color: .indigo)
                usageRow("アイドル", value: cpu?.idleUsage ?? 0, color: .white.opacity(0.32))
            }
        }
        .padding(12)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: .blue,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }

    private var coresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("コア別使用率")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.86))

            LazyVGrid(columns: coreColumns, spacing: 8) {
                ForEach(Array((cpu?.perCoreUsage ?? []).enumerated()), id: \.offset) { item in
                    coreRow(index: item.offset, value: item.element)
                }
            }
        }
        .padding(12)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: .blue,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }

    private func usageRow(_ title: String, value: Double, color: Color) -> some View {
        let clamped = Swift.min(Swift.max(value.isFinite ? value : 0, 0), 1)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(MetricFormatter.percentage(clamped))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .font(.system(size: 11, weight: .medium))

            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.09))
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(color)
                            .frame(width: max(3, proxy.size.width * CGFloat(clamped)))
                    }
            }
            .frame(height: 5)
            .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: clamped)
        }
    }

    private func coreRow(index: Int, value: Double) -> some View {
        let clamped = Swift.min(Swift.max(value.isFinite ? value : 0, 0), 1)
        let color: Color = clamped >= 0.85 ? .orange : .blue
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("コア \(index + 1)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(MetricFormatter.percentage(clamped))
                    .foregroundStyle(.primary.opacity(0.9))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .font(.system(size: 10, weight: .medium))

            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.09))
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(color)
                            .frame(width: max(3, proxy.size.width * CGFloat(clamped)))
                    }
            }
            .frame(height: 5)
            .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: clamped)
        }
    }
}
