//
//  SparklineChart.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Charts
import SwiftUI

/// 履歴スナップショットから Apple 純正調のエリア付き時系列チャートを描画する。
struct SparklineChart: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let snapshots: [MetricsSnapshot]
    let tint: Color
    let yDomain: ClosedRange<Double>
    let value: (MetricsSnapshot) -> Double

    var body: some View {
        Chart {
            ForEach(snapshots, id: \.timestamp) { point in
                let metricValue = value(point)
                AreaMark(
                    x: .value("時刻", point.timestamp),
                    yStart: .value("下限", yDomain.lowerBound),
                    yEnd: .value("値", metricValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(0.28), tint.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("時刻", point.timestamp),
                    y: .value("値", metricValue)
                )
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .animation(
            PulseMotion.resolve(.easeInOut(duration: 0.35), reduceMotion: reduceMotion),
            value: snapshots.last?.timestamp
        )
        .chartYScale(domain: yDomain)
        .frame(height: 64)
    }
}
