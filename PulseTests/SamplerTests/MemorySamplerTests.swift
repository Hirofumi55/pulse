//
//  MemorySamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing
@testable import Pulse

@Suite("Memory Sampler Tests")
struct MemorySamplerTests {
    @Test("Sampler returns valid memory metrics")
    func returnsValidMemoryMetrics() async throws {
        let sampler = MemorySampler()

        let metrics = try await sampler.sample()

        #expect(metrics.totalBytes > 0)
        #expect(metrics.appBytes <= metrics.totalBytes)
        #expect(metrics.wiredBytes <= metrics.totalBytes)
        #expect(metrics.compressedBytes <= metrics.totalBytes)
        #expect(metrics.cachedBytes <= metrics.totalBytes)
        #expect(metrics.freeBytes <= metrics.totalBytes)
        #expect(metrics.usageRatio >= 0.0)
        #expect(metrics.usageRatio <= 1.0)
        #expect(metrics.pressure >= 0.0)
        #expect(metrics.pressure <= 1.0)
    }
}
