//
//  MenuBarRenderer.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Foundation

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
        case .cpuTemperature, .gpuUsage:
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
            showIcon ? "TMP --" : "--"
        case .gpuUsage:
            showIcon ? "GPU --%" : "--%"
        }
    }

    private static func percentageTitle(prefix: String, value: Double) -> String {
        let percent = Int((value * 100).rounded()).clamped(to: 0...100)
        return "\(prefix)\(percent)%"
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
            showIcon ? "TMP 100C" : "100C"
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
