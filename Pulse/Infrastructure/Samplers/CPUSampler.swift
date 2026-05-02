//
//  CPUSampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

@preconcurrency import Darwin
import Foundation

/// Mach API から CPU 使用率を取得する Sampler。
actor CPUSampler: Sampler {
    private var previousTotalTicks: CPUTicks?
    private var previousPerCoreTicks: [CPUTicks] = []

    func sample() async throws -> CPUMetrics {
        let total = try sampleTotal()
        let perCore = try samplePerCore()
        let physicalCount = ProcessInfo.processInfo.processorCount
        let logicalCount = ProcessInfo.processInfo.activeProcessorCount

        return CPUMetrics(
            totalUsage: total.total,
            userUsage: total.user,
            systemUsage: total.system,
            idleUsage: total.idle,
            perCoreUsage: perCore,
            physicalCoreCount: physicalCount,
            logicalCoreCount: logicalCount
        )
    }

    private func sampleTotal() throws -> CPUUsageBreakdown {
        var cpuLoadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            throw SamplerError.kernelCallFailed(name: "host_statistics", code: result)
        }

        let currentTicks = CPUTicks(cpuLoadInfo)
        guard let previousTicks = previousTotalTicks else {
            previousTotalTicks = currentTicks
            return .zero
        }

        previousTotalTicks = currentTicks
        return calculateUsage(current: currentTicks, previous: previousTicks)
    }

    private func samplePerCore() throws -> [Double] {
        var processorCount: natural_t = 0
        var processorInfo: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &infoCount
        )

        guard result == KERN_SUCCESS, let info = processorInfo else {
            throw SamplerError.kernelCallFailed(name: "host_processor_info", code: result)
        }

        defer {
            let byteCount = vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            let address = vm_address_t(UInt(bitPattern: info))
            vm_deallocate(mach_task_self_, address, byteCount)
        }

        let coreCount = Int(processorCount)
        let currentTicks = info.withMemoryRebound(to: processor_cpu_load_info.self, capacity: coreCount) { pointer in
            (0..<coreCount).map { index in
                CPUTicks(pointer[index])
            }
        }

        guard previousPerCoreTicks.count == currentTicks.count else {
            previousPerCoreTicks = currentTicks
            return Array(repeating: 0, count: coreCount)
        }

        let usage = zip(currentTicks, previousPerCoreTicks).map { current, previous in
            calculateUsage(current: current, previous: previous).total
        }
        previousPerCoreTicks = currentTicks
        return usage
    }

    private func calculateUsage(
        current: CPUTicks,
        previous: CPUTicks
    ) -> CPUUsageBreakdown {
        let userDiff = current.user.difference(from: previous.user)
        let systemDiff = current.system.difference(from: previous.system)
        let idleDiff = current.idle.difference(from: previous.idle)
        let niceDiff = current.nice.difference(from: previous.nice)
        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff

        guard totalTicks > 0 else {
            return .zero
        }

        let user = Double(userDiff) / Double(totalTicks)
        let system = Double(systemDiff) / Double(totalTicks)
        let idle = Double(idleDiff) / Double(totalTicks)
        let total = Double(userDiff + systemDiff + niceDiff) / Double(totalTicks)

        return CPUUsageBreakdown(total: total, user: user, system: system, idle: idle)
    }
}

private struct CPUUsageBreakdown: Sendable, Equatable {
    static let zero = CPUUsageBreakdown(total: 0, user: 0, system: 0, idle: 0)

    let total: Double
    let user: Double
    let system: Double
    let idle: Double
}

private struct CPUTicks: Sendable, Equatable {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64

    init(_ info: host_cpu_load_info_data_t) {
        self.user = UInt64(cpuTick: info.cpu_ticks.0)
        self.system = UInt64(cpuTick: info.cpu_ticks.1)
        self.idle = UInt64(cpuTick: info.cpu_ticks.2)
        self.nice = UInt64(cpuTick: info.cpu_ticks.3)
    }

    init(_ info: processor_cpu_load_info) {
        self.user = UInt64(cpuTick: info.cpu_ticks.0)
        self.system = UInt64(cpuTick: info.cpu_ticks.1)
        self.idle = UInt64(cpuTick: info.cpu_ticks.2)
        self.nice = UInt64(cpuTick: info.cpu_ticks.3)
    }
}

extension UInt64 {
    fileprivate init(cpuTick value: UInt32) {
        self = UInt64(value)
    }

    fileprivate func difference(from previous: UInt64) -> UInt64 {
        if self >= previous {
            self - previous
        } else {
            0
        }
    }
}
