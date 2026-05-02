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

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    GaugeView(value: coordinator.latestSnapshot?.cpu.totalUsage ?? 0, title: "CPU", tint: .blue)
                    VStack(alignment: .leading, spacing: 10) {
                        usageRow("User", value: coordinator.latestSnapshot?.cpu.userUsage ?? 0, color: .blue)
                        usageRow("System", value: coordinator.latestSnapshot?.cpu.systemUsage ?? 0, color: .purple)
                        usageRow("Idle", value: coordinator.latestSnapshot?.cpu.idleUsage ?? 0, color: .secondary)
                    }
                }

                MetricCard(title: "使用率", value: "", tint: .blue) {
                    SparklineChart(snapshots: history, tint: .blue, yDomain: 0...100) { snapshot in
                        snapshot.cpu.totalUsage * 100
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("コア")
                        .font(.system(size: 13, weight: .semibold))
                    ForEach(
                        Array((coordinator.latestSnapshot?.cpu.perCoreUsage ?? []).enumerated()),
                        id: \.offset
                    ) { item in
                        coreRow(index: item.offset, value: item.element)
                    }
                }
            }
            .padding(14)
        }
    }

    private func usageRow(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(MetricFormatter.percentage(value))
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: .medium))

            ProgressView(value: Swift.min(Swift.max(value, 0), 1))
                .tint(color)
        }
    }

    private func coreRow(index: Int, value: Double) -> some View {
        HStack(spacing: 8) {
            Text("Core \(index + 1)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .frame(width: 54, alignment: .leading)
            ProgressView(value: Swift.min(Swift.max(value, 0), 1))
                .tint(.blue)
            Text(MetricFormatter.percentage(value))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .frame(width: 34, alignment: .trailing)
        }
    }
}
