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
    private let thermalSampler = ThermalSampler()

    private var samplingTask: Task<Void, Never>?
    private var samplingInterval: Duration

    /// Coordinator を作成する。
    init(maxHistoryCount: Int = 300, samplingInterval: Duration = .seconds(1)) {
        self.maxHistoryCount = max(1, maxHistoryCount)
        self.samplingInterval = samplingInterval
    }

    /// 指定間隔でサンプリングを開始する。
    func start(interval: Duration = .seconds(1)) {
        if samplingTask != nil, samplingInterval == interval {
            return
        }

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
        guard samplingInterval != interval else {
            return
        }

        let shouldRestart = samplingTask != nil
        samplingInterval = interval
        logger.debug("Sampling interval updated")

        if shouldRestart {
            start(interval: interval)
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            let snapshot = await sampleAll()
            guard !Task.isCancelled else {
                return
            }
            appendSnapshot(snapshot)

            do {
                try await Task.sleep(for: samplingInterval)
            } catch {
                return
            }
        }
    }

    private func sampleAll() async -> MetricsSnapshot {
        let previousSnapshot = latestSnapshot

        async let cpu = sampleCPU(previous: previousSnapshot?.cpu)
        async let memory = sampleMemory(previous: previousSnapshot?.memory)
        async let disk = sampleDisk(previous: previousSnapshot?.disk)
        async let network = sampleNetwork(previous: previousSnapshot?.network)
        async let thermal = sampleThermal(previous: previousSnapshot?.thermal)

        return MetricsSnapshot(
            timestamp: .now,
            cpu: await cpu,
            memory: await memory,
            disk: await disk,
            network: await network,
            thermal: await thermal
        )
    }

    private func sampleCPU(previous: CPUMetrics?) async -> CPUMetrics {
        do {
            return try await cpuSampler.sample()
        } catch {
            logger.error("CPU sampling failed: \(String(describing: error), privacy: .public)")
            return previous ?? Self.emptyCPU()
        }
    }

    private func sampleMemory(previous: MemoryMetrics?) async -> MemoryMetrics {
        do {
            return try await memorySampler.sample()
        } catch {
            logger.error("Memory sampling failed: \(String(describing: error), privacy: .public)")
            return previous ?? Self.emptyMemory()
        }
    }

    private func sampleDisk(previous: DiskMetrics?) async -> DiskMetrics {
        do {
            return try await diskSampler.sample()
        } catch {
            logger.error("Disk sampling failed: \(String(describing: error), privacy: .public)")
            return previous ?? DiskMetrics(volumes: [], readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }
    }

    private func sampleNetwork(previous: NetworkMetrics?) async -> NetworkMetrics {
        do {
            return try await networkSampler.sample()
        } catch {
            logger.error("Network sampling failed: \(String(describing: error), privacy: .public)")
            return previous ?? NetworkMetrics(interfaces: [])
        }
    }

    private func sampleThermal(previous: ThermalMetrics?) async -> ThermalMetrics {
        do {
            return try await thermalSampler.sample()
        } catch {
            logger.error("Thermal sampling failed: \(String(describing: error), privacy: .public)")
            return previous ?? ThermalMetrics(cpuTemperatureCelsius: nil, batteryTemperatureCelsius: nil)
        }
    }

    private func appendSnapshot(_ snapshot: MetricsSnapshot) {
        latestSnapshot = snapshot
        history.append(snapshot)

        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }

    private static func emptyCPU() -> CPUMetrics {
        let logicalCoreCount = ProcessInfo.processInfo.activeProcessorCount
        return CPUMetrics(
            totalUsage: 0,
            userUsage: 0,
            systemUsage: 0,
            idleUsage: 0,
            perCoreUsage: Array(repeating: 0, count: logicalCoreCount),
            physicalCoreCount: ProcessInfo.processInfo.processorCount,
            logicalCoreCount: logicalCoreCount
        )
    }

    private static func emptyMemory() -> MemoryMetrics {
        MemoryMetrics(
            totalBytes: ProcessInfo.processInfo.physicalMemory,
            appBytes: 0,
            wiredBytes: 0,
            compressedBytes: 0,
            cachedBytes: 0,
            freeBytes: 0,
            swapUsedBytes: 0,
            pressure: 0
        )
    }
}
