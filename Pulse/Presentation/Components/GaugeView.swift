//
//  GaugeView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 0.0 から 1.0 の値をリング状に表示するゲージ。
struct GaugeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Double
    let title: String
    let tint: Color

    private var clampedValue: Double {
        guard value.isFinite else {
            return 0
        }
        return Swift.min(Swift.max(value, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.11), lineWidth: 10)
            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: clampedValue)

            VStack(spacing: 2) {
                Text(MetricFormatter.percentage(clampedValue))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(
                        PulseMotion.resolve(PulseMotion.numeric, reduceMotion: reduceMotion),
                        value: clampedValue
                    )
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(width: 112, height: 112)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(MetricFormatter.percentage(clampedValue))
    }
}
