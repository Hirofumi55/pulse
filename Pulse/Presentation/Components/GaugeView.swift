//
//  GaugeView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 0.0 から 1.0 の値をリング状に表示するゲージ。
struct GaugeView: View {
    let value: Double
    let title: String
    let tint: Color

    private var clampedValue: Double {
        Swift.min(Swift.max(value, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.16), lineWidth: 12)
            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.45), tint, tint.opacity(0.82)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: clampedValue)
            VStack(spacing: 2) {
                Text(MetricFormatter.percentage(clampedValue))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(tint.opacity(0.16), lineWidth: 1)
        }
        .frame(width: 118, height: 118)
    }
}
