//
//  NetworkSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
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

    @Test("Duplicate interface names are deduplicated without double counting")
    func deduplicatesInterfaceNames() async {
        let sampler = NetworkSampler()
        let firstDate = Date(timeIntervalSinceReferenceDate: 100)
        let secondDate = firstDate.addingTimeInterval(1)

        _ = await sampler.makeMetrics(from: [
            NetworkRawStats(name: "en0", downloadBytes: 1_000, uploadBytes: 500, flags: 0, timestamp: firstDate)
        ])

        let metrics = await sampler.makeMetrics(from: [
            NetworkRawStats(name: "en0", downloadBytes: 2_000, uploadBytes: 1_000, flags: 0, timestamp: secondDate),
            NetworkRawStats(name: "en0", downloadBytes: 3_000, uploadBytes: 1_500, flags: 0, timestamp: secondDate),
        ])

        #expect(metrics.interfaces.count == 1)
        #expect(metrics.interfaces.first?.id == "en0")
        #expect(metrics.totalDownloadBytesPerSecond == 2_000)
        #expect(metrics.totalUploadBytesPerSecond == 1_000)
    }
}
