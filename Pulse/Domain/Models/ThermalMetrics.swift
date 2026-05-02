//
//  ThermalMetrics.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// 温度センサーから取得した熱状態のメトリクス。
struct ThermalMetrics: Sendable, Equatable {
    /// CPU 近傍の温度(摂氏)。取得できない場合は nil。
    let cpuTemperatureCelsius: Double?

    /// バッテリー温度(摂氏)。取得できない場合は nil。
    let batteryTemperatureCelsius: Double?

    /// 表示に使う代表温度。
    var primaryTemperatureCelsius: Double? {
        cpuTemperatureCelsius ?? batteryTemperatureCelsius
    }

    /// 代表温度の取得元。
    var primarySourceName: String {
        if cpuTemperatureCelsius != nil {
            return "CPU"
        }

        if batteryTemperatureCelsius != nil {
            return "バッテリー"
        }

        return "未取得"
    }

    /// CPU 温度の取得状態を説明する文言。
    var cpuTemperatureStatusMessage: String {
        if cpuTemperatureCelsius != nil {
            return "CPUセンサー"
        }

        return "このMacではCPU温度を取得できません"
    }
}
