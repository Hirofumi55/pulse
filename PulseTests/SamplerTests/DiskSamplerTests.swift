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

    @Test("Unreadable volumes do not hide readable volumes")
    func skipsUnreadableVolumes() async throws {
        let sampler = DiskSampler()
        let rootURL = URL(fileURLWithPath: "/")
        let missingURL = URL(fileURLWithPath: "/pulse-missing-volume-\(UUID().uuidString)")

        let volumes = try await sampler.sampleVolumes(from: [missingURL, rootURL])

        #expect(volumes.contains { $0.id == rootURL.path(percentEncoded: false) })
    }
}
