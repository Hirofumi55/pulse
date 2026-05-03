//
//  ThermalMetricsTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing

@testable import Pulse

@Suite("Thermal Metrics Tests")
struct ThermalMetricsTests {
    @Test("CPU temperature status explains unavailable readings")
    func cpuTemperatureStatusExplainsUnavailableReadings() {
        let metrics = ThermalMetrics(cpuTemperatureCelsius: nil, batteryTemperatureCelsius: 31)

        #expect(metrics.cpuTemperatureStatusMessage == "このMacではCPU温度を取得できません")
    }

    @Test("CPU temperature status explains available readings")
    func cpuTemperatureStatusExplainsAvailableReadings() {
        let metrics = ThermalMetrics(cpuTemperatureCelsius: 48, batteryTemperatureCelsius: 31)

        #expect(metrics.cpuTemperatureStatusMessage == "CPUセンサー")
    }

    @Test("CPU temperature normalizer prefers plausible Kelvin conversion")
    func cpuTemperatureNormalizerPrefersPlausibleKelvinConversion() {
        let temperature = ThermalValueNormalizer.cpuTemperatureCelsius(from: 310) ?? 0

        #expect(abs(temperature - 36.85) < 0.001)
    }

    @Test("CPU temperature normalizer keeps centi celsius values")
    func cpuTemperatureNormalizerKeepsCentiCelsiusValues() {
        #expect(ThermalValueNormalizer.cpuTemperatureCelsius(from: 3100) == 31)
    }
}
