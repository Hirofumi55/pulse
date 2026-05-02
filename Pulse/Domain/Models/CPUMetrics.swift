//
//  CPUMetrics.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// CPU 使用率とコア数のメトリクス。
struct CPUMetrics: Sendable, Equatable {
    /// 全体の使用率(0.0 - 1.0)。
    let totalUsage: Double

    /// User 時間使用率。
    let userUsage: Double

    /// System 時間使用率。
    let systemUsage: Double

    /// Idle 使用率(参考値)。
    let idleUsage: Double

    /// コア毎の使用率(全コア)。
    let perCoreUsage: [Double]

    /// 物理コア数。
    let physicalCoreCount: Int

    /// 論理コア数。
    let logicalCoreCount: Int
}
