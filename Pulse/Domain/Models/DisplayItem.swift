//
//  DisplayItem.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// メニューバーに表示できるメトリクス項目。
enum DisplayItem: String, CaseIterable, Codable, Sendable, Identifiable {
    /// CPU 使用率。
    case cpuUsage

    /// メモリ使用率。
    case memoryUsage

    /// ネットワーク速度。
    case networkSpeed

    /// ディスク使用率。
    case diskUsage

    /// ディスク I/O。
    case diskIO

    /// 温度。
    case cpuTemperature

    /// GPU 使用率。Phase 2 で有効化する。
    case gpuUsage

    /// 識別子。
    var id: String {
        rawValue
    }

    /// UI に表示する日本語名。
    var displayName: String {
        switch self {
        case .cpuUsage:
            "CPU使用率"
        case .memoryUsage:
            "メモリ使用率"
        case .networkSpeed:
            "ネットワーク速度"
        case .diskUsage:
            "ディスク使用率"
        case .diskIO:
            "ディスクI/O"
        case .cpuTemperature:
            "温度"
        case .gpuUsage:
            "GPU使用率"
        }
    }

    /// Phase 1 で利用可能な項目かどうか。
    var isAvailableInPhase1: Bool {
        switch self {
        case .cpuUsage, .memoryUsage, .networkSpeed, .diskUsage, .diskIO, .cpuTemperature:
            true
        case .gpuUsage:
            false
        }
    }
}
