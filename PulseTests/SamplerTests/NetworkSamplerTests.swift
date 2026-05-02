//
//  NetworkSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing
@testable import Pulse

@Suite("Network Sampler Tests")
struct NetworkSamplerTests {
    @Test("Sampler returns filtered interfaces and speeds")
    func returnsValidNetworkMetrics() async throws {
        let sampler = NetworkSampler()

        let firstMetrics = try await sampler.sample()
        try await Task.sleep(for: .milliseconds(100))

        let metrics = try await sampler.sample()

        #expect(firstMetrics.totalDownloadBytesPerSecond == 0)
        #expect(firstMetrics.totalUploadBytesPerSecond == 0)
        #expect(!metrics.interfaces.isEmpty)
        #expect(metrics.interfaces.allSatisfy { !$0.id.hasPrefix("lo") })
        #expect(metrics.interfaces.allSatisfy { !$0.id.hasPrefix("awdl") })
        #expect(metrics.interfaces.allSatisfy { !$0.id.hasPrefix("llw") })
        #expect(metrics.interfaces.allSatisfy { !$0.id.hasPrefix("utun") })
    }
}
