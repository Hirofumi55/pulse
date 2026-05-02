//
//  MemoryMetrics.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// メモリ使用量とメモリプレッシャーのメトリクス。
struct MemoryMetrics: Sendable, Equatable {
    /// 物理メモリ総量(bytes)。
    let totalBytes: UInt64

    /// アプリ使用量(bytes)。Activity Monitor の App Memory に相当する。
    let appBytes: UInt64

    /// Wired Memory(bytes)。
    let wiredBytes: UInt64

    /// Compressed Memory(bytes)。
    let compressedBytes: UInt64

    /// キャッシュ(bytes)。Activity Monitor の Cached Files に相当する。
    let cachedBytes: UInt64

    /// 空きメモリ(bytes)。
    let freeBytes: UInt64

    /// Swap 使用量(bytes)。
    let swapUsedBytes: UInt64

    /// メモリプレッシャー(0.0 = 低 - 1.0 = 高)。
    let pressure: Double

    /// 使用率。Activity Monitor 準拠で app + wired + compressed を物理メモリで割る。
    var usageRatio: Double {
        guard totalBytes > 0 else {
            return 0
        }
        return Double(appBytes + wiredBytes + compressedBytes) / Double(totalBytes)
    }
}
