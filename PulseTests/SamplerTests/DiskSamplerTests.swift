//
//  DiskSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

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
}
