//
//  DiskSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Testing

@testable import Pulse

@Suite("Disk Sampler Tests")
struct DiskSamplerTests {
    @Test("Sampler returns mounted volumes and IO speeds")
    func returnsValidDiskMetrics() async throws {
        let sampler = DiskSampler()

        let firstMetrics = try await sampler.sample()
        try await Task.sleep(for: .milliseconds(100))

        let metrics = try await sampler.sample()

        #expect(firstMetrics.readBytesPerSecond == 0)
        #expect(firstMetrics.writeBytesPerSecond == 0)
        #expect(!metrics.volumes.isEmpty)
        #expect(metrics.volumes.allSatisfy { $0.totalBytes > 0 })
        #expect(metrics.volumes.allSatisfy { $0.freeBytes <= $0.totalBytes })
        #expect(metrics.volumes.allSatisfy { $0.usageRatio >= 0.0 && $0.usageRatio <= 1.0 })
    }

    @Test("ディスクの着脱時は継続して観測できたデバイスの差分だけを集計する")
    func handlesDeviceChanges() async {
        let sampler = DiskSampler()
        let first = await sampler.calculateSpeed(counters: [1: DiskIOCounters(read: 100, write: 200)], uptime: 10)
        #expect(first.read == 0 && first.write == 0)

        let both = await sampler.calculateSpeed(
            counters: [1: DiskIOCounters(read: 140, write: 210), 2: DiskIOCounters(read: 800, write: 900)],
            uptime: 12
        )
        #expect(both.read == 20 && both.write == 5)

        let remaining = await sampler.calculateSpeed(counters: [2: DiskIOCounters(read: 810, write: 932)], uptime: 14)
        #expect(remaining.read == 5 && remaining.write == 16)
    }

    @Test("Unreadable volumes do not hide readable volumes")
    func skipsUnreadableVolumes() async throws {
        let sampler = DiskSampler()
        let rootURL = URL(fileURLWithPath: "/")
        let missingURL = URL(fileURLWithPath: "/pulse-missing-volume-\(UUID().uuidString)")

        let volumes = try await sampler.sampleVolumes(from: [missingURL, rootURL])

        #expect(volumes.contains { $0.id == rootURL.path(percentEncoded: false) })
    }
}
