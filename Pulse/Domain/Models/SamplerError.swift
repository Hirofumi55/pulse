//
//  SamplerError.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Darwin
import Foundation

/// Sampler がシステム API から値を取得できなかった場合のエラー。
enum SamplerError: Error, Equatable, LocalizedError, Sendable {
    /// Mach カーネル API の呼び出しに失敗した。
    case kernelCallFailed(name: String, code: kern_return_t)

    /// sysctl の呼び出しに失敗した。
    case sysctlFailed

    /// IOKit の呼び出しに失敗した。
    case ioKitFailed

    /// 差分計算に必要なサンプルが不足している。
    case insufficientData

    /// システム API の戻り値が想定外の形式だった。
    case unexpectedFormat

    var errorDescription: String? {
        switch self {
        case .kernelCallFailed(let name, let code):
            "\(name) failed with code \(code)"
        case .sysctlFailed:
            "sysctl call failed"
        case .ioKitFailed:
            "IOKit call failed"
        case .insufficientData:
            "Insufficient sample data"
        case .unexpectedFormat:
            "Unexpected data format"
        }
    }
}
