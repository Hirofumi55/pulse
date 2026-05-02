//
//  MetricsSnapshot.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// 1回のサンプリングで取得した全メトリクスのスナップショット。
struct MetricsSnapshot: Sendable, Equatable {
    /// サンプリングした時刻。
    let timestamp: Date

    /// CPU の現在値。
    let cpu: CPUMetrics

    /// メモリの現在値。
    let memory: MemoryMetrics

    /// ディスクの現在値。
    let disk: DiskMetrics

    /// ネットワークの現在値。
    let network: NetworkMetrics

    /// 温度の現在値。
    let thermal: ThermalMetrics
}
