//
//  SparklineChart.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Charts
import SwiftUI

/// 履歴スナップショットから小さな時系列チャートを描画する。
struct SparklineChart: View {
    let snapshots: [MetricsSnapshot]
    let tint: Color
    let yDomain: ClosedRange<Double>
    let value: (MetricsSnapshot) -> Double

    var body: some View {
        Chart {
            ForEach(Array(snapshots.enumerated()), id: \.offset) { point in
                LineMark(
                    x: .value("時刻", point.element.timestamp),
                    y: .value("値", value(point.element))
                )
                .foregroundStyle(tint)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .frame(height: 46)
    }
}
