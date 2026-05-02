//
//  StorageTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Charts
import SwiftUI

/// ストレージ容量と I/O を表示するタブ。
struct StorageTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ボリューム")
                        .font(.system(size: 13, weight: .semibold))
                    ForEach(coordinator.latestSnapshot?.disk.volumes ?? []) { volume in
                        volumeRow(volume)
                    }
                }

                MetricCard(title: "I/O", value: ioValue, subtitle: ioSubtitle, tint: .orange) {
                    ioChart
                }
            }
            .padding(14)
        }
    }

    private var ioValue: String {
        guard let disk = coordinator.latestSnapshot?.disk else {
            return "0B/s"
        }

        return MetricFormatter.bytesPerSecond(disk.readBytesPerSecond, dataUnit: preferences.dataUnit)
    }

    private var ioSubtitle: String {
        guard let disk = coordinator.latestSnapshot?.disk else {
            return "待機中"
        }

        let write = MetricFormatter.bytesPerSecond(disk.writeBytesPerSecond, dataUnit: preferences.dataUnit)
        return "Write \(write)"
    }

    private var ioChart: some View {
        Chart {
            ForEach(Array(history.enumerated()), id: \.offset) { point in
                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("Read", point.element.disk.readBytesPerSecond)
                )
                .foregroundStyle(by: .value("種別", "Read"))
                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("Write", point.element.disk.writeBytesPerSecond)
                )
                .foregroundStyle(by: .value("種別", "Write"))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 80)
    }

    private func volumeRow(_ volume: VolumeInfo) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(volume.name)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(MetricFormatter.percentage(volume.usageRatio))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
            ProgressView(value: volume.usageRatio)
                .tint(volume.isInternal ? .orange : .blue)
            Text(volumeSubtitle(volume))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func volumeSubtitle(_ volume: VolumeInfo) -> String {
        let used = MetricFormatter.bytes(volume.usedBytes, dataUnit: preferences.dataUnit)
        let total = MetricFormatter.bytes(volume.totalBytes, dataUnit: preferences.dataUnit)
        return "\(used) / \(total)"
    }
}
