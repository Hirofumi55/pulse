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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                MetricCard(title: "ディスクI/O", value: ioValue, subtitle: ioSubtitle, tint: .purple) {
                    ioChart
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ボリューム")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.86))
                        .padding(.horizontal, 2)

                    ForEach(coordinator.latestSnapshot?.disk.volumes ?? []) { volume in
                        volumeRow(volume)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
    }

    private var ioValue: String {
        guard let disk = coordinator.latestSnapshot?.disk else {
            return "--/s"
        }

        let (total, overflow) = disk.readBytesPerSecond.addingReportingOverflow(disk.writeBytesPerSecond)
        return MetricFormatter.bytesPerSecond(overflow ? .max : total, dataUnit: preferences.dataUnit)
    }

    private var ioSubtitle: String {
        guard let disk = coordinator.latestSnapshot?.disk else {
            return "待機中"
        }

        let read = MetricFormatter.bytesPerSecond(disk.readBytesPerSecond, dataUnit: preferences.dataUnit)
        let write = MetricFormatter.bytesPerSecond(disk.writeBytesPerSecond, dataUnit: preferences.dataUnit)
        return "読込 \(read) · 書込 \(write)"
    }

    private var ioChart: some View {
        Chart {
            ForEach(Array(history.enumerated()), id: \.offset) { point in
                AreaMark(
                    x: .value("時刻", point.element.timestamp),
                    yStart: .value("下限", 0),
                    yEnd: .value("読込", point.element.disk.readBytesPerSecond)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.24), Color.teal.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("読込", point.element.disk.readBytesPerSecond)
                )
                .foregroundStyle(by: .value("種別", "読込"))
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("書込", point.element.disk.writeBytesPerSecond)
                )
                .foregroundStyle(by: .value("種別", "書込"))
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartForegroundStyleScale(["読込": Color.teal, "書込": Color.purple])
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 92)
    }

    private func volumeRow(_ volume: VolumeInfo) -> some View {
        let clampedRatio = Swift.min(Swift.max(volume.usageRatio, 0), 1)
        let tint: Color = clampedRatio >= 0.9 ? .orange : (volume.isInternal ? .indigo : .blue)
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: volume.isInternal ? "internaldrive" : "externaldrive")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(tint)
                    Text(volume.name)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer()
                Text(MetricFormatter.percentage(clampedRatio))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.09))
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(tint)
                            .frame(width: max(6, proxy.size.width * CGFloat(clampedRatio)))
                    }
            }
            .frame(height: 7)
            .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: clampedRatio)

            HStack {
                Text(volumeSubtitle(volume))
                Spacer()
                Text("空き \(MetricFormatter.bytes(volume.freeBytes, dataUnit: preferences.dataUnit))")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(12)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: tint,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }

    private func volumeSubtitle(_ volume: VolumeInfo) -> String {
        let used = MetricFormatter.bytes(volume.usedBytes, dataUnit: preferences.dataUnit)
        let total = MetricFormatter.bytes(volume.totalBytes, dataUnit: preferences.dataUnit)
        return "\(used) / \(total)"
    }
}
