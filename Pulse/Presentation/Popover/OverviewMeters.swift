//
//  OverviewMeters.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 温度を横長ゲージとして表示するビュー。
struct TemperatureGaugeView: View {
    let temperature: Double?
    let unit: TemperatureUnit

    private var ratio: Double {
        guard let temperature else {
            return 0.05
        }

        return Swift.min(Swift.max((temperature - 20) / 70, 0.05), 1)
    }

    var body: some View {
        Group {
            if temperature == nil {
                Label("温度データなし", systemImage: "questionmark.circle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.10), lineWidth: 0.5)
                    }
            } else {
                VStack(spacing: 7) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.10))
                        Capsule()
                            .fill(temperatureGradient)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(x: ratio, y: 1, anchor: .leading)
                    }
                    .frame(height: 18)

                    HStack {
                        Text(temperatureScaleText(celsius: 20))
                        Spacer()
                        Text(temperatureScaleText(celsius: 60))
                        Spacer()
                        Text(temperatureScaleText(celsius: 90))
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 43)
    }

    private var temperatureGradient: LinearGradient {
        LinearGradient(colors: [.cyan, .green, .yellow, .orange], startPoint: .leading, endPoint: .trailing)
    }

    private func temperatureScaleText(celsius: Double) -> String {
        switch unit {
        case .celsius:
            "\(Int(celsius))℃"
        case .fahrenheit:
            "\(Int((celsius * 9 / 5 + 32).rounded()))℉"
        }
    }
}

/// 受信と送信を上下に分けて表示する固定幅のネットワークチャート。
struct NetworkActivityView: View {
    let history: [MetricsSnapshot]
    let dataUnit: DataUnit

    private let sampleCount = 22

    private var samples: [NetworkActivitySample] {
        let snapshots = Array(history.suffix(sampleCount))
        let missingCount = max(sampleCount - snapshots.count, 0)
        let emptySamples = Array(repeating: NetworkActivitySample.zero, count: missingCount)
        let liveSamples = snapshots.map { snapshot in
            NetworkActivitySample(
                download: snapshot.network.totalDownloadBytesPerSecond,
                upload: snapshot.network.totalUploadBytesPerSecond
            )
        }
        return emptySamples + liveSamples
    }

    private var maximum: Double {
        max(
            samples.map { sample in
                Double(max(sample.download, sample.upload))
            }.max() ?? 1,
            1
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                ZStack {
                    Rectangle()
                        .fill(.white.opacity(0.10))
                        .frame(height: 1)

                    HStack(alignment: .center, spacing: 2) {
                        ForEach(Array(samples.enumerated()), id: \.offset) { entry in
                            sampleColumn(entry.element, height: proxy.size.height)
                        }
                    }
                }
            }
            .frame(height: 37)

            HStack(spacing: 8) {
                legend("受信", color: .cyan)
                legend("送信", color: .indigo)
                Spacer(minLength: 0)
                Text("ピーク \(peakText)")
                    .monospacedDigit()
            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
        }
    }

    private var peakText: String {
        ByteFormatter.rateString(from: UInt64(maximum), dataUnit: dataUnit, unitStyle: .compact)
    }

    private func sampleColumn(_ sample: NetworkActivitySample, height: CGFloat) -> some View {
        let halfHeight = max((height - 1) / 2, 1)
        return VStack(spacing: 1) {
            Color.clear
                .overlay(alignment: .bottom) {
                    activityBar(value: sample.download, color: .cyan, maximumHeight: halfHeight)
                }
            Color.clear
                .overlay(alignment: .top) {
                    activityBar(value: sample.upload, color: .indigo, maximumHeight: halfHeight)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func activityBar(value: UInt64, color: Color, maximumHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(color.opacity(value == 0 ? 0.16 : 0.92))
            .frame(height: max(1.5, maximumHeight * CGFloat(Double(value) / maximum)))
    }

    private func legend(_ text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
            Text(text)
        }
    }
}

private struct NetworkActivitySample {
    static let zero = NetworkActivitySample(download: 0, upload: 0)

    let download: UInt64
    let upload: UInt64
}

/// ディスク読み書き速度を2本のバーで表示するビュー。
struct IOMeterView: View {
    let read: UInt64
    let write: UInt64

    private var maximum: Double {
        max(Double(max(read, write)), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            meter(label: "読込", value: read, color: .cyan)
            meter(label: "書込", value: write, color: .purple)
        }
        .frame(height: 43)
    }

    private func meter(label: String, value: UInt64, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
            GeometryReader { proxy in
                Capsule()
                    .fill(.white.opacity(0.10))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(color)
                            .frame(width: max(4, proxy.size.width * CGFloat(Double(value) / maximum)))
                    }
            }
            .frame(height: 10)
        }
    }
}

struct WidgetPill: View {
    @Environment(PreferencesStore.self) private var preferences
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.primary.opacity(0.70))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .pulseGlassPanel(
            cornerRadius: 5,
            tint: .secondary,
            materialOpacity: PulseGlassStyle.pillMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
    }
}
