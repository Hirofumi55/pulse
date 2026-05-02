//
//  ThermalSampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
@preconcurrency import IOKit

/// 公開 IOKit API から温度情報を取得する Sampler。
actor ThermalSampler: Sampler {
    func sample() async throws -> ThermalMetrics {
        ThermalMetrics(
            cpuTemperatureCelsius: nil,
            batteryTemperatureCelsius: sampleAppleSmartBatteryTemperature()
        )
    }

    private func sampleAppleSmartBatteryTemperature() -> Double? {
        guard let matching = IOServiceMatching("AppleSmartBattery") else {
            return nil
        }

        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != IO_OBJECT_NULL else {
            return nil
        }

        defer {
            IOObjectRelease(service)
        }

        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        guard
            result == KERN_SUCCESS,
            let dictionary = properties?.takeRetainedValue() as? [String: Any],
            let rawTemperature = doubleValue(from: dictionary["Temperature"])
        else {
            return nil
        }

        return normalizedBatteryTemperature(from: rawTemperature)
    }

    private func normalizedBatteryTemperature(from rawValue: Double) -> Double? {
        let candidates = [
            rawValue / 100,
            rawValue / 10 - 273.15,
        ]

        return candidates.first { temperature in
            (-20...120).contains(temperature)
        }
    }

    private func doubleValue(from value: Any?) -> Double? {
        switch value {
        case let value as Double:
            value
        case let value as Float:
            Double(value)
        case let value as Int:
            Double(value)
        case let value as Int64:
            Double(value)
        case let value as UInt64:
            Double(value)
        case let value as NSNumber:
            value.doubleValue
        default:
            nil
        }
    }
}
