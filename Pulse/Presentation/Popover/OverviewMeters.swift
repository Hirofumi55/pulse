//
//  OverviewMeters.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 概要と詳細で同じ計測値を見分けるための色。
enum InspectorTint {
    static let amber = Color(red: 1.00, green: 0.70, blue: 0.26)
    static let aqua = Color(red: 0.23, green: 0.80, blue: 0.92)
    static let lavender = Color(red: 0.70, green: 0.60, blue: 0.98)
}

/// 実コア数に合わせた負荷メーター。
struct CoreLoadBars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let values: [Double]

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: min(3, proxy.size.width / CGFloat(max(values.count, 1)) * 0.20)) {
                ForEach(Array(values.enumerated()), id: \.offset) { item in
                    let ratio = min(max(item.element, 0), 1)
                    let shape = RoundedRectangle(cornerRadius: 2)
                    shape.fill(.white.opacity(0.10))
                        .overlay(alignment: .bottom) {
                            shape.fill(InspectorTint.amber)
                                .frame(height: proxy.size.height * ratio)
                        }
                }
            }
        }
        .frame(height: 29)
        .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: values)
    }
}

/// 目盛りを固定した容量バー。
struct CapacityMeter: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let ratio: Double?
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(.white.opacity(0.14))
                .overlay(alignment: .leading) {
                    Capsule().fill(tint)
                        .frame(width: proxy.size.width * min(max(ratio ?? 0, 0), 1))
                }
        }
        .frame(height: 9)
        .animation(PulseMotion.resolve(PulseMotion.smooth, reduceMotion: reduceMotion), value: ratio)
    }
}

/// 同じ時間軸で履歴を描き、サンプルが届いたときだけ表示窓を送る。
struct HistoryTrace: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let samples: [MetricsSnapshot]
    let value: (MetricsSnapshot) -> Double
    let ceiling: Double
    let color: Color
    var filled = false

    var body: some View {
        let points = samples.map {
            CGPoint(x: $0.timestamp.timeIntervalSinceReferenceDate, y: value($0))
        }
        let trace = TracePath(points: points, endTime: Double(points.last?.x ?? 0), ceiling: max(ceiling, 0.001))
        ZStack {
            if filled {
                trace.area.fill(
                    LinearGradient(
                        colors: [color.opacity(0.26), color.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom)
                )
            }
            trace.stroke(color, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        }
        .padding(.vertical, 1)
        .clipped()
        .animation(PulseMotion.resolve(.easeInOut(duration: 0.35), reduceMotion: reduceMotion), value: points.last?.x)
        .accessibilityHidden(true)
    }
}

/// 実測時刻を直近1分の座標に変換する波形。
struct TracePath: Shape {
    let points: [CGPoint]
    var endTime: Double
    var ceiling: Double
    var closesArea = false

    var area: Self {
        var copy = self
        copy.closesArea = true
        return copy
    }

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(endTime, ceiling) }
        set {
            endTime = newValue.first
            ceiling = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var last: CGPoint?
        var startX = 0.0
        var previousTime: Double?
        for point in points {
            let position = CGPoint(
                x: rect.maxX - (endTime - point.x) / 60 * rect.width,
                y: rect.maxY - min(max(point.y / ceiling, 0), 1) * rect.height
            )
            // 一時停止やスリープをまたいで線を結ばない。
            if let previousTime, point.x - previousTime <= 15 {
                path.addLine(to: position)
            } else {
                closeArea(&path, from: startX, to: last, bottom: rect.maxY)
                path.move(to: position)
                path.addLine(to: position)
                startX = position.x
            }
            last = position
            previousTime = point.x
        }
        closeArea(&path, from: startX, to: last, bottom: rect.maxY)
        return path
    }

    private func closeArea(_ path: inout Path, from startX: Double, to last: CGPoint?, bottom: Double) {
        guard closesArea, let last else { return }
        path.addLine(to: CGPoint(x: last.x, y: bottom))
        path.addLine(to: CGPoint(x: startX, y: bottom))
        path.closeSubpath()
    }
}
