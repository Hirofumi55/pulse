//
//  OverviewMeters.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// コア別の負荷を滑らかなバー配列で表示するビュー。
struct CoreLoadBars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let values: [Double]

    private var displayValues: [Double] {
        values.isEmpty ? Array(repeating: 0, count: 8) : values
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: displayValues.count > 12 ? 2.5 : 4) {
                ForEach(Array(displayValues.enumerated()), id: \.offset) { item in
                    let clamped = Swift.min(Swift.max(item.element.isFinite ? item.element : 0, 0), 1)
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(.white.opacity(0.08))

                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(barColor(for: clamped))
                            .frame(height: max(proxy.size.height * CGFloat(clamped), 2.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 36)
        .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: displayValues)
    }

    private func barColor(for ratio: Double) -> Color {
        if ratio >= 0.85 {
            return .orange
        }
        if ratio >= 0.65 {
            return Color.blue.opacity(0.95)
        }
        return Color.blue.opacity(0.78)
    }
}

/// 複数セグメントを滑らかに描画するドーナツゲージ。
struct DonutMetricView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let segments: [DonutSegment]
    let centerText: String
    let centerCaption: String

    private var total: Double {
        max(segments.reduce(0) { result, segment in result + max(segment.value, 0) }, 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.09), lineWidth: 9.5)

            ForEach(Array(segments.enumerated()), id: \.offset) { item in
                let start = startTrim(at: item.offset)
                let end = endTrim(at: item.offset)
                if end > start {
                    Circle()
                        .trim(from: start, to: max(start, end - 0.006))
                        .stroke(
                            item.element.color,
                            style: StrokeStyle(lineWidth: 9.5, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }

            VStack(spacing: 1) {
                Text(centerText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(centerCaption)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 66, height: 66)
        .frame(maxWidth: .infinity)
        .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: segments)
    }

    private func startTrim(at index: Int) -> Double {
        segments.prefix(index).reduce(0) { result, segment in
            result + max(segment.value, 0) / total
        }
    }

    private func endTrim(at index: Int) -> Double {
        startTrim(at: index) + max(segments[index].value, 0) / total
    }
}

/// ドーナツゲージの1セグメント。
struct DonutSegment: Equatable {
    let value: Double
    let color: Color
}

/// ストレージ使用率をシステム設定風のカプセルバーで表示するビュー。
struct StorageSegmentBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let usageRatio: Double?
    let freeText: String

    private var clampedRatio: Double {
        guard let usageRatio, usageRatio.isFinite else {
            return 0
        }
        return Swift.min(Swift.max(usageRatio, 0), 1)
    }

    private var barColor: Color {
        if clampedRatio >= 0.9 {
            return .orange
        }
        return .indigo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.09))

                    if usageRatio != nil {
                        Capsule(style: .continuous)
                            .fill(barColor)
                            .frame(width: max(6, proxy.size.width * CGFloat(clampedRatio)))
                    }
                }
            }
            .frame(height: 10)
            .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: clampedRatio)

            HStack {
                Text("空き")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(freeText)
                    .foregroundStyle(.primary.opacity(0.88))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .font(.system(size: 10, weight: .medium))
        }
    }
}

/// 受信と送信を上下に分けて表示する固定幅のネットワークチャート。
struct NetworkActivityView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let history: [MetricsSnapshot]
    let dataUnit: DataUnit

    private let sampleCount = 22

    private var samples: [NetworkActivitySample] {
        let snapshots = history.suffix(sampleCount)
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

    var body: some View {
        let samples = self.samples
        let peakBytes = samples.reduce(UInt64.zero) { currentPeak, sample in
            max(currentPeak, max(sample.download, sample.upload))
        }
        let maximum = max(Double(peakBytes), 1)
        VStack(spacing: 5) {
            GeometryReader { proxy in
                ZStack {
                    Rectangle()
                        .fill(.white.opacity(0.09))
                        .frame(height: 0.75)

                    HStack(alignment: .center, spacing: 2) {
                        ForEach(Array(samples.enumerated()), id: \.offset) { entry in
                            sampleColumn(entry.element, height: proxy.size.height, maximum: maximum)
                        }
                    }
                }
            }
            .frame(height: 36)
            .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: samples)

            HStack(spacing: 8) {
                legend("受信", color: .cyan)
                legend("送信", color: .indigo)
                Spacer(minLength: 0)
                Text("ピーク \(peakText(for: peakBytes))")
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }

    private func peakText(for peakBytes: UInt64) -> String {
        guard !history.isEmpty else {
            return "--/s"
        }

        return ByteFormatter.rateString(from: peakBytes, dataUnit: dataUnit, unitStyle: .compact)
    }

    private func sampleColumn(_ sample: NetworkActivitySample, height: CGFloat, maximum: Double) -> some View {
        let halfHeight = max((height - 1) / 2, 1)
        return VStack(spacing: 1) {
            Color.clear
                .overlay(alignment: .bottom) {
                    activityBar(ratio: Double(sample.download) / maximum, color: .cyan, maximumHeight: halfHeight)
                }
            Color.clear
                .overlay(alignment: .top) {
                    activityBar(ratio: Double(sample.upload) / maximum, color: .indigo, maximumHeight: halfHeight)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func activityBar(ratio: Double, color: Color, maximumHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(color.opacity(ratio == 0 ? 0.14 : 0.90))
            .frame(height: max(1.5, maximumHeight * CGFloat(ratio)))
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

private struct NetworkActivitySample: Equatable {
    static let zero = NetworkActivitySample(download: 0, upload: 0)

    let download: UInt64
    let upload: UInt64
}

/// ディスク読み書き速度を2本のバーで表示するビュー。
struct IOMeterView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let read: UInt64
    let write: UInt64

    private var maximum: Double {
        max(Double(max(read, write)), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            meter(label: "読込", value: read, color: .teal)
            meter(label: "書込", value: write, color: .purple)
        }
        .frame(height: 36)
        .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: read)
        .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: write)
    }

    private func meter(label: String, value: UInt64, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)
            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.09))
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(color.opacity(value == 0 ? 0.30 : 0.92))
                            .frame(width: max(4, proxy.size.width * CGFloat(Double(value) / maximum)))
                    }
            }
            .frame(height: 8)
        }
    }
}

/// カード内の補助情報をガラスの入れ子なしで静かに表示するインライン要素。
struct MetricInlineStat: View {
    let label: String
    let value: String
    let dotColor: Color?

    init(label: String, value: String, dotColor: Color? = nil) {
        self.label = label
        self.value = value
        self.dotColor = dotColor
    }

    var body: some View {
        HStack(spacing: 4) {
            if let dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 5, height: 5)
            }
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary.opacity(0.88))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .font(.system(size: 10, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}
