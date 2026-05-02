//
//  OverviewTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 全メトリクスの現在値をまとめて表示するタブ。
struct OverviewTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(90))
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                MetricCard(
                    title: "CPU",
                    value: MetricFormatter.percentage(coordinator.latestSnapshot?.cpu.totalUsage ?? 0),
                    subtitle: cpuSubtitle,
                    tint: .blue
                ) {
                    SparklineChart(snapshots: history, tint: .blue, yDomain: 0...100) { snapshot in
                        snapshot.cpu.totalUsage * 100
                    }
                }

                MetricCard(
                    title: "メモリ",
                    value: MetricFormatter.percentage(coordinator.latestSnapshot?.memory.usageRatio ?? 0),
                    subtitle: memorySubtitle,
                    tint: .green
                ) {
                    SparklineChart(snapshots: history, tint: .green, yDomain: 0...100) { snapshot in
                        snapshot.memory.usageRatio * 100
                    }
                }

                MetricCard(title: "ネットワーク", value: networkValue, subtitle: networkSubtitle, tint: .cyan) {
                    SparklineChart(snapshots: history, tint: .cyan, yDomain: 0...networkChartMax) { snapshot in
                        Double(snapshot.network.totalDownloadBytesPerSecond)
                    }
                }

                MetricCard(
                    title: "ストレージ",
                    value: MetricFormatter.percentage(primaryVolume?.usageRatio ?? 0),
                    subtitle: storageSubtitle,
                    tint: .orange
                ) {
                    SparklineChart(snapshots: history, tint: .orange, yDomain: 0...diskChartMax) { snapshot in
                        Double(snapshot.disk.readBytesPerSecond + snapshot.disk.writeBytesPerSecond)
                    }
                }
            }
            .padding(14)
        }
    }

    private var cpuSubtitle: String {
        guard let cpu = coordinator.latestSnapshot?.cpu else {
            return "待機中"
        }

        return "\(cpu.logicalCoreCount) threads"
    }

    private var memorySubtitle: String {
        guard let memory = coordinator.latestSnapshot?.memory else {
            return "待機中"
        }

        let used = memory.appBytes + memory.wiredBytes + memory.compressedBytes
        let usedText = MetricFormatter.bytes(used, dataUnit: preferences.dataUnit)
        let totalText = MetricFormatter.bytes(memory.totalBytes, dataUnit: preferences.dataUnit)
        return "\(usedText) / \(totalText)"
    }

    private var networkValue: String {
        guard let network = coordinator.latestSnapshot?.network else {
            return "0B/s"
        }

        return MetricFormatter.bytesPerSecond(network.totalDownloadBytesPerSecond, dataUnit: preferences.dataUnit)
    }

    private var networkSubtitle: String {
        guard let network = coordinator.latestSnapshot?.network else {
            return "待機中"
        }

        let upload = MetricFormatter.bytesPerSecond(network.totalUploadBytesPerSecond, dataUnit: preferences.dataUnit)
        return "↑ \(upload)"
    }

    private var storageSubtitle: String {
        guard let primaryVolume else {
            return "待機中"
        }

        let free = MetricFormatter.bytes(primaryVolume.freeBytes, dataUnit: preferences.dataUnit)
        return "空き \(free)"
    }

    private var primaryVolume: VolumeInfo? {
        coordinator.latestSnapshot?.disk.volumes.first { volume in
            volume.isInternal
        } ?? coordinator.latestSnapshot?.disk.volumes.first
    }

    private var networkChartMax: Double {
        max(history.map { Double($0.network.totalDownloadBytesPerSecond) }.max() ?? 1, 1)
    }

    private var diskChartMax: Double {
        max(history.map { Double($0.disk.readBytesPerSecond + $0.disk.writeBytesPerSecond) }.max() ?? 1, 1)
    }
}
