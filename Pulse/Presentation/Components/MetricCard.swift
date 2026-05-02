//
//  MetricCard.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// メトリクスの現在値と補助情報を表示するカード。
struct MetricCard<Content: View>: View {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            content
                .frame(maxWidth: .infinity)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        }
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
        let percent = Int((ratio * 100).rounded())
        return "\(clamp(percent, lowerBound: 0, upperBound: 100))%"
    }

    static func bytes(_ bytes: UInt64, dataUnit: DataUnit) -> String {
        ByteFormatter.string(from: bytes, dataUnit: dataUnit)
    }

    static func bytesPerSecond(_ bytes: UInt64, dataUnit: DataUnit) -> String {
        ByteFormatter.rateString(from: bytes, dataUnit: dataUnit)
    }

    private static func clamp(_ value: Int, lowerBound: Int, upperBound: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
