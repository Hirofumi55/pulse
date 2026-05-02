//
//  NetworkMetrics.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// ネットワークインターフェース別の通信速度メトリクス。
struct NetworkMetrics: Sendable, Equatable {
    /// 対象ネットワークインターフェースの一覧。
    let interfaces: [InterfaceInfo]

    /// 全インターフェース合計の受信速度(bytes/sec)。
    var totalDownloadBytesPerSecond: UInt64 {
        interfaces.reduce(0) { $0 + $1.downloadBytesPerSecond }
    }

    /// 全インターフェース合計の送信速度(bytes/sec)。
    var totalUploadBytesPerSecond: UInt64 {
        interfaces.reduce(0) { $0 + $1.uploadBytesPerSecond }
    }
}

/// 1つのネットワークインターフェースに関する通信速度情報。
struct InterfaceInfo: Sendable, Equatable, Identifiable {
    /// 識別子。`en0` などのインターフェース名を使用する。
    let id: String

    /// UI に表示する名称。
    let displayName: String

    /// 受信速度(bytes/sec)。
    let downloadBytesPerSecond: UInt64

    /// 送信速度(bytes/sec)。
    let uploadBytesPerSecond: UInt64

    /// 現在アクティブなインターフェースかどうか。
    let isActive: Bool
}
