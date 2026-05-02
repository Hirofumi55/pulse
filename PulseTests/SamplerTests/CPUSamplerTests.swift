//
//  CPUSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing
@testable import Pulse

@Suite("CPU Sampler Tests")
struct CPUSamplerTests {
    @Test("Sampler returns valid metrics on second call")
    func returnsValidMetrics() async throws {
        let sampler = CPUSampler()
        _ = try await sampler.sample()
        try await Task.sleep(for: .milliseconds(100))

        let metrics = try await sampler.sample()

        #expect(metrics.totalUsage >= 0.0)
        #expect(metrics.totalUsage <= 1.0)
        #expect(metrics.userUsage >= 0.0)
        #expect(metrics.systemUsage >= 0.0)
        #expect(metrics.idleUsage >= 0.0)
        #expect(metrics.perCoreUsage.count == metrics.logicalCoreCount)
        #expect(metrics.perCoreUsage.allSatisfy { $0 >= 0.0 && $0 <= 1.0 })
    }
}
