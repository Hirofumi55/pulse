//
//  MetricCard.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// メトリクスの現在値と補助情報を表示するカード。
struct MetricCard<Content: View>: View {
    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let value: String
    let subtitle: String
    let tint: Color
    let content: Content

    init(
        title: String,
        value: String,
        subtitle: String = "",
        tint: Color = .accentColor,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.86))
                }
                Spacer(minLength: 8)
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(
                            PulseMotion.resolve(PulseMotion.numeric, reduceMotion: reduceMotion),
                            value: value
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            content
                .frame(maxWidth: .infinity)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
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
}

extension MetricCard where Content == EmptyView {
    init(
        title: String,
        value: String,
        subtitle: String = "",
        tint: Color = .accentColor
    ) {
        self.init(title: title, value: value, subtitle: subtitle, tint: tint) {
            EmptyView()
        }
    }
}

/// ポップオーバー内で使う数値フォーマット。
enum MetricFormatter {
    static func percentage(_ ratio: Double) -> String {
        guard ratio.isFinite else {
            return "--"
        }

        let percent = Int((min(max(ratio, 0), 1) * 100).rounded())
        return "\(percent)%"
    }

    static func bytes(_ bytes: UInt64, dataUnit: DataUnit) -> String {
        ByteFormatter.string(from: bytes, dataUnit: dataUnit)
    }

    static func bytesPerSecond(_ bytes: UInt64, dataUnit: DataUnit) -> String {
        ByteFormatter.rateString(from: bytes, dataUnit: dataUnit)
    }
}
