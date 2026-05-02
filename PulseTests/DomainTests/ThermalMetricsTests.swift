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
}
