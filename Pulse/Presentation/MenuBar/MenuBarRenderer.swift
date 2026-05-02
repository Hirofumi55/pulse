//
//  MenuBarRenderer.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Foundation

/// メニューバー画像描画の設定。
struct MenuBarRenderOptions: Equatable, Sendable {
    /// アイコンラベルを表示するかどうか。
    let showIcon: Bool

    /// バー表示の方向。
    let barLayout: MenuBarBarLayout

    /// バー内にパーセントを表示するかどうか。
    let showBarPercentage: Bool
}

/// メニューバーに表示する短いメトリクス文字列を生成する。
enum MenuBarRenderer {
    @MainActor
    private static var titleAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ]
    }

    /// メニューバー項目群の固定幅を返す。
    @MainActor
    static func preferredLength(for items: [DisplayItem], showIcon: Bool) -> CGFloat {
        preferredLength(
            for: items,
            style: .text,
            options: MenuBarRenderOptions(
                showIcon: showIcon,
                barLayout: .horizontal,
                showBarPercentage: false
            )
        )
    }

    /// メニューバー項目群の固定幅を返す。
    @MainActor
    static func preferredLength(
        for items: [DisplayItem],
        style: MenuBarDisplayStyle,
        options: MenuBarRenderOptions
    ) -> CGFloat {
        switch style {
        case .bar:
            let widthPerItem: CGFloat =
                switch options.barLayout {
                case .vertical:
                    options.showBarPercentage ? 34 : 24
                case .horizontal:
                    options.showIcon ? 44 : 28
                }
            return max(28, ceil(CGFloat(items.count) * widthPerItem + 8))
        case .graph:
            let widthPerItem: CGFloat = options.showIcon ? 42 : 34
            return max(34, ceil(CGFloat(items.count) * widthPerItem + 8))
        case .text:
            return textPreferredLength(for: items, showIcon: options.showIcon)
        }
    }

    @MainActor
    private static func textPreferredLength(for items: [DisplayItem], showIcon: Bool) -> CGFloat {
        let titleSample = items.map { item in
            sampleTitle(for: item, showIcon: showIcon)
        }.joined(separator: "  ")
        return ceil(attributedTitle(for: titleSample).size().width + 12)
    }

    /// メニューバー用の装飾済みタイトルを生成する。
    @MainActor
    static func attributedTitle(for title: String) -> NSAttributedString {
        NSAttributedString(string: title, attributes: titleAttributes)
    }

    /// メニューバー用の装飾済みタイトルを生成する。
    @MainActor
    static func attributedTitle(
        for item: DisplayItem,
        snapshot: MetricsSnapshot?,
        showIcon: Bool,
        dataUnit: DataUnit
    ) -> NSAttributedString {
        attributedTitle(
            for: title(for: item, snapshot: snapshot, showIcon: showIcon, dataUnit: dataUnit)
        )
    }

    /// メニューバー用のプレーン文字列を生成する。
    static func title(
        for items: [DisplayItem],
        snapshot: MetricsSnapshot?,
        showIcon: Bool,
        dataUnit: DataUnit
    ) -> String {
        items.map { item in
            title(for: item, snapshot: snapshot, showIcon: showIcon, dataUnit: dataUnit)
        }.joined(separator: "  ")
    }

    /// メニューバー用のプレーン文字列を生成する。
    static func title(
        for item: DisplayItem,
        snapshot: MetricsSnapshot?,
        showIcon: Bool,
        dataUnit: DataUnit
    ) -> String {
        guard let snapshot else {
            return placeholderTitle(for: item, showIcon: showIcon)
        }

        switch item {
        case .cpuUsage:
            return percentageTitle(
                prefix: showIcon ? "CPU " : "",
                value: snapshot.cpu.totalUsage
            )
        case .memoryUsage:
            return percentageTitle(
                prefix: showIcon ? "MEM " : "",
                value: snapshot.memory.usageRatio
            )
        case .networkSpeed:
            let down = ByteFormatter.string(
                from: snapshot.network.totalDownloadBytesPerSecond,
                dataUnit: dataUnit,
                unitStyle: .compact
            )
            let up = ByteFormatter.string(
                from: snapshot.network.totalUploadBytesPerSecond,
                dataUnit: dataUnit,
                unitStyle: .compact
            )
            return "↓ \(down) ↑ \(up)"
        case .diskUsage:
            return percentageTitle(
                prefix: showIcon ? "DSK " : "",
                value: primaryVolume(from: snapshot.disk.volumes)?.usageRatio ?? 0
            )
        case .diskIO:
            let read = ByteFormatter.string(
                from: snapshot.disk.readBytesPerSecond,
                dataUnit: dataUnit,
                unitStyle: .compact
            )
            let write = ByteFormatter.string(
                from: snapshot.disk.writeBytesPerSecond,
                dataUnit: dataUnit,
                unitStyle: .compact
            )
            return "↓ \(read) ↑ \(write)"
        case .cpuTemperature:
            return temperatureTitle(
                prefix: showIcon ? "温度 " : "",
                value: snapshot.thermal.cpuTemperatureCelsius
            )
        case .gpuUsage:
            return placeholderTitle(for: item, showIcon: showIcon)
        }
    }

    private static func placeholderTitle(for item: DisplayItem, showIcon: Bool) -> String {
        switch item {
        case .cpuUsage:
            showIcon ? "CPU --%" : "--%"
        case .memoryUsage:
            showIcon ? "MEM --%" : "--%"
        case .networkSpeed:
            "↓ -- ↑ --"
        case .diskUsage:
            showIcon ? "DSK --%" : "--%"
        case .diskIO:
            "↓ -- ↑ --"
        case .cpuTemperature:
            showIcon ? "温度 --℃" : "--℃"
        case .gpuUsage:
            showIcon ? "GPU --%" : "--%"
        }
    }

    private static func percentageTitle(prefix: String, value: Double) -> String {
        let percent = Int((value * 100).rounded()).clamped(to: 0...100)
        return "\(prefix)\(percent)%"
    }

    private static func temperatureTitle(prefix: String, value: Double?) -> String {
        guard let value else {
            return "\(prefix)--℃"
        }

        return "\(prefix)\(Int(value.rounded()))℃"
    }

    private static func primaryVolume(from volumes: [VolumeInfo]) -> VolumeInfo? {
        volumes.first { volume in
            volume.isInternal
        } ?? volumes.first
    }

    private static func sampleTitle(for item: DisplayItem, showIcon: Bool) -> String {
        switch item {
        case .cpuUsage:
            showIcon ? "CPU 100%" : "100%"
        case .memoryUsage:
            showIcon ? "MEM 100%" : "100%"
        case .networkSpeed:
            "↓ 999M ↑ 999M"
        case .diskUsage:
            showIcon ? "DSK 100%" : "100%"
        case .diskIO:
            "↓ 999M ↑ 999M"
        case .cpuTemperature:
            showIcon ? "温度 42℃" : "42℃"
        case .gpuUsage:
            showIcon ? "GPU 100%" : "100%"
        }
    }
}

extension Int {
    fileprivate func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
