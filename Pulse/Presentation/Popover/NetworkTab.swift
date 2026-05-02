//
//  NetworkTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Charts
import SwiftUI

/// ネットワークインターフェースと通信速度を表示するタブ。
struct NetworkTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(120))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                MetricCard(title: "通信速度", value: downloadValue, subtitle: uploadSubtitle, tint: .cyan) {
                    speedChart
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("インターフェース")
                        .font(.system(size: 13, weight: .semibold))
                    ForEach(coordinator.latestSnapshot?.network.interfaces ?? []) { interface in
                        interfaceRow(interface)
                    }
                }
            }
            .padding(14)
        }
    }

    private var downloadValue: String {
        let bytes = coordinator.latestSnapshot?.network.totalDownloadBytesPerSecond ?? 0
        return MetricFormatter.bytesPerSecond(bytes, dataUnit: preferences.dataUnit)
    }

    private var uploadSubtitle: String {
        let bytes = coordinator.latestSnapshot?.network.totalUploadBytesPerSecond ?? 0
        return "↑ \(MetricFormatter.bytesPerSecond(bytes, dataUnit: preferences.dataUnit))"
    }

    private var speedChart: some View {
        Chart {
            ForEach(Array(history.enumerated()), id: \.offset) { point in
                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("Down", point.element.network.totalDownloadBytesPerSecond)
                )
                .foregroundStyle(by: .value("方向", "Down"))
                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("Up", point.element.network.totalUploadBytesPerSecond)
                )
                .foregroundStyle(by: .value("方向", "Up"))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 110)
    }

    private func interfaceRow(_ interface: InterfaceInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(interface.displayName)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Text(interface.isActive ? "Active" : "Idle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(interface.isActive ? .green : .secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("↓ \(downloadText(for: interface))")
                Text("↑ \(uploadText(for: interface))")
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func downloadText(for interface: InterfaceInfo) -> String {
        MetricFormatter.bytesPerSecond(interface.downloadBytesPerSecond, dataUnit: preferences.dataUnit)
    }

    private func uploadText(for interface: InterfaceInfo) -> String {
        MetricFormatter.bytesPerSecond(interface.uploadBytesPerSecond, dataUnit: preferences.dataUnit)
    }
}
