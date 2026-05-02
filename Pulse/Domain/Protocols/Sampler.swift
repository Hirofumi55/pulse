//
//  Sampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// メトリクス取得処理の共通インターフェース。
protocol Sampler: Sendable {
    /// Sampler が返すメトリクス型。
    associatedtype Output: Sendable

    /// 現在のメトリクスを非同期に取得する。
    func sample() async throws -> Output
}
