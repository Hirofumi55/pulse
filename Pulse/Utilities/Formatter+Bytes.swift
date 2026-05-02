//
//  Formatter+Bytes.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// バイト数を Pulse の UI 表示用文字列に変換する。
enum ByteFormatter {
    /// 単位表記の長さ。
    enum UnitStyle: Sendable {
        /// KB/MB のような通常表記。
        case standard
        /// K/M のようなメニューバー向け短縮表記。
        case compact
    }

    /// バイト数を読みやすい単位に変換する。
    static func string(
        from bytes: UInt64,
        dataUnit: DataUnit,
        unitStyle: UnitStyle = .standard
    ) -> String {
        let base = dataUnit == .si ? 1000.0 : 1024.0
        let units = units(for: unitStyle)
        var value = Double(bytes)
        var unitIndex = 0

        while value >= base, unitIndex < units.count - 1 {
            value /= base
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value))\(units[unitIndex])"
        }

        if value >= 10 {
            return "\(Int(value.rounded()))\(units[unitIndex])"
        }

        return String(format: "%.1f%@", value, units[unitIndex])
    }

    /// 1秒あたりのバイト数を読みやすい単位に変換する。
    static func rateString(
        from bytes: UInt64,
        dataUnit: DataUnit,
        unitStyle: UnitStyle = .standard
    ) -> String {
        "\(string(from: bytes, dataUnit: dataUnit, unitStyle: unitStyle))/s"
    }

    private static func units(for unitStyle: UnitStyle) -> [String] {
        switch unitStyle {
        case .standard:
            ["B", "KB", "MB", "GB", "TB"]
        case .compact:
            ["B", "K", "M", "G", "T"]
        }
    }
}
