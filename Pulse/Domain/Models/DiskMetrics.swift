//
//  DiskMetrics.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// ディスク容量と I/O 速度のメトリクス。
struct DiskMetrics: Sendable, Equatable {
    /// マウント済みボリュームの一覧。
    let volumes: [VolumeInfo]

    /// プライマリボリュームの読み込み速度(bytes/sec)。
    let readBytesPerSecond: UInt64

    /// プライマリボリュームの書き込み速度(bytes/sec)。
    let writeBytesPerSecond: UInt64
}

/// 1つのボリュームに関する容量情報。
struct VolumeInfo: Sendable, Equatable, Identifiable {
    /// 識別子。マウントポイントを使用する。
    let id: String

    /// 表示名。
    let name: String

    /// 総容量(bytes)。
    let totalBytes: UInt64

    /// 空き容量(bytes)。
    let freeBytes: UInt64

    /// 内蔵ボリュームかどうか。
    let isInternal: Bool

    /// 使用済み容量(bytes)。
    var usedBytes: UInt64 {
        totalBytes - freeBytes
    }

    /// 使用率(0.0 - 1.0)。
    var usageRatio: Double {
        guard totalBytes > 0 else {
            return 0
        }
        return Double(usedBytes) / Double(totalBytes)
    }
}
