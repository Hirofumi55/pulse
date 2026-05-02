//
//  MetricsCoordinator.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Observation
import os

private let logger = Logger(category: .sampler)

/// 全 Sampler を統括し、最新スナップショットと短期履歴を管理する。
@Observable
@MainActor
final class MetricsCoordinator {
    private(set) var latestSnapshot: MetricsSnapshot?
    private(set) var history: [MetricsSnapshot] = []

    private let maxHistoryCount: Int
    private let cpuSampler = CPUSampler()
    private let memorySampler = MemorySampler()
    private let diskSampler = DiskSampler()
    private let networkSampler = NetworkSampler()

    private var samplingTask: Task<Void, Never>?
    private var samplingInterval: Duration

    /// Coordinator を作成する。
    init(maxHistoryCount: Int = 300, samplingInterval: Duration = .seconds(1)) {
        self.maxHistoryCount = max(1, maxHistoryCount)
        self.samplingInterval = samplingInterval
    }

    /// 指定間隔でサンプリングを開始する。
    func start(interval: Duration = .seconds(1)) {
        samplingInterval = interval
        samplingTask?.cancel()
        samplingTask = Task { [weak self] in
            await self?.runLoop()
        }
        logger.debug("Sampling started")
    }

    /// サンプリングを停止する。
    func stop() {
        if samplingTask != nil {
            logger.debug("Sampling stopped")
        }
        samplingTask?.cancel()
        samplingTask = nil
    }

    /// サンプリング間隔を更新する。
    func updateInterval(_ interval: Duration) {
        let shouldRestart = samplingTask != nil
        samplingInterval = interval
        logger.debug("Sampling interval updated")

        if shouldRestart {
            start(interval: interval)
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            do {
                let snapshot = try await sampleAll()
                guard !Task.isCancelled else {
                    return
                }
                appendSnapshot(snapshot)
            } catch {
                logger.error("Sampling failed: \(String(describing: error), privacy: .public)")
            }

            do {
                try await Task.sleep(for: samplingInterval)
            } catch {
                return
            }
        }
    }

    private func sampleAll() async throws -> MetricsSnapshot {
        async let cpu = cpuSampler.sample()
        async let memory = memorySampler.sample()
        async let disk = diskSampler.sample()
        async let network = networkSampler.sample()

        return MetricsSnapshot(
            timestamp: .now,
            cpu: try await cpu,
            memory: try await memory,
            disk: try await disk,
            network: try await network
        )
    }

    private func appendSnapshot(_ snapshot: MetricsSnapshot) {
        latestSnapshot = snapshot
        history.append(snapshot)

        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }
}
