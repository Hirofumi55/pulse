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
            VStack(alignment: .leading, spacing: 10) {
                MetricCard(title: "通信速度", value: downloadValue, subtitle: uploadSubtitle, tint: .cyan) {
                    speedChart
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("インターフェース")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.86))
                        .padding(.horizontal, 2)

                    ForEach(coordinator.latestSnapshot?.network.interfaces ?? []) { interface in
                        interfaceRow(interface)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
    }

    private var downloadValue: String {
        guard let network = coordinator.latestSnapshot?.network else {
            return "--/s"
        }

        return MetricFormatter.bytesPerSecond(network.totalDownloadBytesPerSecond, dataUnit: preferences.dataUnit)
    }

    private var uploadSubtitle: String {
        guard let network = coordinator.latestSnapshot?.network else {
            return "待機中"
        }

        let upload = MetricFormatter.bytesPerSecond(network.totalUploadBytesPerSecond, dataUnit: preferences.dataUnit)
        return "送信 \(upload)"
    }

    private var speedChart: some View {
        Chart {
            ForEach(Array(history.enumerated()), id: \.offset) { point in
                AreaMark(
                    x: .value("時刻", point.element.timestamp),
                    yStart: .value("下限", 0),
                    yEnd: .value("受信", point.element.network.totalDownloadBytesPerSecond)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.26), Color.cyan.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("受信", point.element.network.totalDownloadBytesPerSecond)
                )
                .foregroundStyle(by: .value("方向", "受信"))
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("送信", point.element.network.totalUploadBytesPerSecond)
                )
                .foregroundStyle(by: .value("方向", "送信"))
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartForegroundStyleScale(["受信": Color.cyan, "送信": Color.indigo])
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 108)
    }

    private func interfaceRow(_ interface: InterfaceInfo) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(interface.isActive ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(interface.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    Text(interface.isActive ? "接続中" : "待機中")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(interface.isActive ? .secondary : .tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("↓ \(downloadText(for: interface))")
                    .foregroundStyle(.primary)
                Text("↑ \(uploadText(for: interface))")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .monospacedDigit()
            .contentTransition(.numericText())
        }
        .padding(12)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: interface.isActive ? .cyan : .secondary,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }

    private func downloadText(for interface: InterfaceInfo) -> String {
        MetricFormatter.bytesPerSecond(interface.downloadBytesPerSecond, dataUnit: preferences.dataUnit)
    }

    private func uploadText(for interface: InterfaceInfo) -> String {
        MetricFormatter.bytesPerSecond(interface.uploadBytesPerSecond, dataUnit: preferences.dataUnit)
    }
}
