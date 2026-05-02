//
//  ThermalSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing

@testable import Pulse

@Suite("Thermal Sampler Tests")
struct ThermalSamplerTests {
    @Test("Sampler returns optional thermal metrics without throwing")
    func returnsOptionalThermalMetrics() async throws {
        let sampler = ThermalSampler()
        let metrics = try await sampler.sample()

        if let temperature = metrics.primaryTemperatureCelsius {
            #expect(temperature >= -20)
            #expect(temperature <= 120)
        }
    }
}
