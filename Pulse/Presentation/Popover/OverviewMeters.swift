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

    private var ratio: Double {
        guard let temperature else {
            return 0.05
        }

        return Swift.min(Swift.max((temperature - 20) / 70, 0.05), 1)
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.18))
                Capsule()
                    .fill(temperatureGradient)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: ratio, y: 1, anchor: .leading)
            }
            .frame(height: 18)

            HStack {
                Text("20℃")
                Spacer()
                Text("60℃")
                Spacer()
                Text("90℃")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .frame(height: 43)
    }

    private var temperatureGradient: LinearGradient {
        LinearGradient(colors: [.cyan, .green, .yellow, .orange], startPoint: .leading, endPoint: .trailing)
    }
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
            meter(label: "Read", value: read, color: .cyan)
            meter(label: "Write", value: write, color: .purple)
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
                    .fill(.secondary.opacity(0.16))
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
