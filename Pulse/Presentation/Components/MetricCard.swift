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

/// 概要ダッシュボードで使うインタラクティブな Liquid Glass Bento タイル。
struct BentoTileCard<Content: View>: View {
    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let systemImage: String
    let tint: Color
    let height: CGFloat
    let action: (() -> Void)?
    let content: Content

    @State private var isHovered = false

    init(
        title: String,
        systemImage: String,
        tint: Color,
        height: CGFloat,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.height = height
        self.action = action
        self.content = content()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardSurface
                }
                .buttonStyle(.plain)
            } else {
                cardSurface
            }
        }
        .scaleEffect(isHovered && action != nil && !reduceMotion ? 1.012 : 1.0)
        .animation(PulseMotion.resolve(PulseMotion.snappy, reduceMotion: reduceMotion), value: isHovered)
        .onHover { hovering in
            guard action != nil else {
                return
            }
            isHovered = hovering
        }
    }

    private var cardSurface: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.82))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(isHovered ? 0.95 : 0.35))
                        .offset(x: isHovered && !reduceMotion ? 1.5 : 0)
                        .accessibilityHidden(true)
                }
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(height: height, alignment: .topLeading)
        .pulseGlassPanel(
            cornerRadius: 16,
            tint: tint,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack,
            isInteractive: action != nil,
            isHovered: isHovered
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    /// ポップオーバー表示時の控えめなスタガード出現モーションを適用する。
    func pulseStaggeredEntrance(appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 7)
            .animation(
                reduceMotion ? nil : PulseMotion.smooth.delay(delay),
                value: appeared
            )
    }
}
