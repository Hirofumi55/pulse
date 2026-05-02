//
//  ThermalSamplerTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Testing
import os

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

    @Test("Sampler caches readings within minimum interval")
    func cachesReadingsWithinMinimumInterval() async throws {
        let counter = OSAllocatedUnfairLock(initialState: 0)
        let sampler = ThermalSampler(minimumSampleInterval: 60) {
            let value = counter.withLock { state in
                state += 1
                return Double(state)
            }
            return ThermalMetrics(cpuTemperatureCelsius: nil, batteryTemperatureCelsius: value)
        }
        let firstDate = Date(timeIntervalSinceReferenceDate: 0)

        let first = await sampler.sample(now: firstDate)
        let second = await sampler.sample(now: firstDate.addingTimeInterval(1))
        let third = await sampler.sample(now: firstDate.addingTimeInterval(61))

        #expect(first == second)
        #expect(third.batteryTemperatureCelsius == 2)
    }
}
