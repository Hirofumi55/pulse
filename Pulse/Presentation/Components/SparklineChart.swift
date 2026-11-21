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
    let snapshots: [MetricsSnapshot]
    let tint: Color
    let yDomain: ClosedRange<Double>
    let value: (MetricsSnapshot) -> Double

    var body: some View {
        Chart {
            ForEach(Array(snapshots.enumerated()), id: \.offset) { point in
                let metricValue = value(point.element)
                AreaMark(
                    x: .value("時刻", point.element.timestamp),
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
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("値", metricValue)
                )
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .frame(height: 64)
    }
}
