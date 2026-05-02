//
//  MemorySampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Darwin
import Foundation

/// Mach API と sysctl からメモリ使用量を取得する Sampler。
actor MemorySampler: Sampler {
    private var previousPageouts: PageoutSample?

    func sample() async throws -> MemoryMetrics {
        let pageSize = try samplePageSize()
        let stats = try sampleVMStatistics()
        let total = ProcessInfo.processInfo.physicalMemory
        let app = bytes(from: stats.internal_page_count, pageSize: pageSize)
        let wired = bytes(from: stats.wire_count, pageSize: pageSize)
        let compressed = bytes(from: stats.compressor_page_count, pageSize: pageSize)
        let cached = bytes(from: stats.external_page_count, pageSize: pageSize)
        let free = bytes(from: stats.free_count, pageSize: pageSize)
        let swapUsed = try sampleSwapUsage()
        let pressureInput = MemoryPressureInput(
            stats: stats,
            pageSize: pageSize,
            totalBytes: total,
            cachedBytes: cached,
            freeBytes: free,
            compressedBytes: compressed,
            swapUsedBytes: swapUsed,
            timestamp: .now
        )
        let pressure = sampleMemoryPressure(pressureInput)

        return MemoryMetrics(
            totalBytes: total,
            appBytes: app,
            wiredBytes: wired,
            compressedBytes: compressed,
            cachedBytes: cached,
            freeBytes: free,
            swapUsedBytes: swapUsed,
            pressure: pressure
        )
    }

    private func samplePageSize() throws -> UInt64 {
        var pageSize = vm_size_t()
        let result = host_page_size(mach_host_self(), &pageSize)

        guard result == KERN_SUCCESS else {
            throw SamplerError.kernelCallFailed(name: "host_page_size", code: result)
        }

        return UInt64(pageSize)
    }

    private func sampleVMStatistics() throws -> vm_statistics64_data_t {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            throw SamplerError.kernelCallFailed(name: "host_statistics64", code: result)
        }

        return stats
    }

    private func sampleSwapUsage() throws -> UInt64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.stride
        let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)

        guard result == 0 else {
            throw SamplerError.sysctlFailed
        }

        return usage.xsu_used
    }

    private func sampleMemoryPressure(_ input: MemoryPressureInput) -> Double {
        guard input.totalBytes > 0 else {
            return 0
        }

        let availableRatio = ratio(input.cachedBytes + input.freeBytes, to: input.totalBytes)
        let compressedRatio = ratio(input.compressedBytes, to: input.totalBytes)
        let swapRatio = ratio(input.swapUsedBytes, to: input.totalBytes)
        let pageoutRatio = samplePageoutPressure(
            currentPageouts: input.stats.pageouts,
            pageSize: input.pageSize,
            timestamp: input.timestamp
        )
        let pressure =
            ((1 - availableRatio) * 0.35)
            + (compressedRatio * 0.25)
            + (swapRatio * 0.20)
            + (pageoutRatio * 0.20)

        return pressure.clamped(to: 0...1)
    }

    private func samplePageoutPressure(
        currentPageouts: UInt64,
        pageSize: UInt64,
        timestamp: Date
    ) -> Double {
        let current = PageoutSample(pageouts: currentPageouts, timestamp: timestamp)
        defer {
            previousPageouts = current
        }

        guard let previousPageouts else {
            return 0
        }

        let elapsedSeconds = timestamp.timeIntervalSince(previousPageouts.timestamp)
        guard elapsedSeconds > 0 else {
            return 0
        }

        let pageoutDelta = difference(current: currentPageouts, previous: previousPageouts.pageouts)
        let bytesPerSecond = Double(pageoutDelta * pageSize) / elapsedSeconds
        let severePageoutRate = 64.0 * 1024.0 * 1024.0
        return (bytesPerSecond / severePageoutRate).clamped(to: 0...1)
    }

    private func bytes(from pageCount: UInt32, pageSize: UInt64) -> UInt64 {
        UInt64(pageCount) * pageSize
    }

    private func ratio(_ value: UInt64, to total: UInt64) -> Double {
        guard total > 0 else {
            return 0
        }
        return (Double(value) / Double(total)).clamped(to: 0...1)
    }

    private func difference(current: UInt64, previous: UInt64) -> UInt64 {
        if current >= previous {
            current - previous
        } else {
            0
        }
    }
}

private struct PageoutSample: Sendable, Equatable {
    let pageouts: UInt64
    let timestamp: Date
}

private struct MemoryPressureInput {
    let stats: vm_statistics64_data_t
    let pageSize: UInt64
    let totalBytes: UInt64
    let cachedBytes: UInt64
    let freeBytes: UInt64
    let compressedBytes: UInt64
    let swapUsedBytes: UInt64
    let timestamp: Date
}

extension Double {
    fileprivate func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
