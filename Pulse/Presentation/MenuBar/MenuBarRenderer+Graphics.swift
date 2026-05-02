//
//  MenuBarRenderer+Graphics.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Foundation

extension MenuBarRenderer {
    private static var imageHeight: CGFloat {
        18
    }

    /// メニューバー用のグラフィカルな画像を生成する。
    @MainActor
    static func image(
        for items: [DisplayItem],
        snapshot: MetricsSnapshot?,
        history: [MetricsSnapshot],
        showIcon: Bool,
        style: MenuBarDisplayStyle
    ) -> NSImage {
        let width = preferredLength(for: items, showIcon: showIcon, style: style)
        let size = NSSize(width: width, height: imageHeight)
        let image = NSImage(size: size)

        image.lockFocus()
        defer {
            image.unlockFocus()
        }

        guard let context = NSGraphicsContext.current?.cgContext else {
            return image
        }

        context.clear(CGRect(origin: .zero, size: size))

        let contentRect = NSRect(x: 4, y: 1, width: width - 8, height: imageHeight - 2)
        let itemWidth = contentRect.width / CGFloat(max(items.count, 1))

        for (index, item) in items.enumerated() {
            let itemRect = NSRect(
                x: contentRect.minX + CGFloat(index) * itemWidth,
                y: contentRect.minY,
                width: itemWidth,
                height: contentRect.height
            ).insetBy(dx: 2, dy: 0)

            switch style {
            case .bar:
                drawBarItem(item, snapshot: snapshot, in: itemRect, showIcon: showIcon)
            case .graph:
                drawGraphItem(item, history: history, snapshot: snapshot, in: itemRect, showIcon: showIcon)
            case .text:
                drawFallbackText(
                    for: item,
                    snapshot: snapshot,
                    showIcon: showIcon,
                    dataUnit: .iec,
                    in: itemRect
                )
            }
        }

        image.isTemplate = false
        return image
    }

    private static func drawBarItem(
        _ item: DisplayItem,
        snapshot: MetricsSnapshot?,
        in rect: NSRect,
        showIcon: Bool
    ) {
        let labelHeight: CGFloat = showIcon ? 7 : 0
        if showIcon {
            let labelRect = NSRect(x: rect.minX, y: rect.maxY - 8, width: rect.width, height: 8)
            drawLabel(shortLabel(for: item), in: labelRect)
        }

        let barRect = NSRect(
            x: rect.minX,
            y: rect.minY + 1,
            width: rect.width,
            height: max(5, rect.height - labelHeight - 3)
        )
        let ratios = barRatios(for: item, snapshot: snapshot)
        let colors = accentColors(for: item)

        drawRoundedRect(barRect, color: NSColor.labelColor.withAlphaComponent(0.10), radius: 2.5)

        let segmentHeight = max(2, (barRect.height - CGFloat(ratios.count - 1)) / CGFloat(max(ratios.count, 1)))
        for (index, ratio) in ratios.enumerated() {
            let yPosition = barRect.minY + CGFloat(index) * (segmentHeight + 1)
            let fillRect = NSRect(
                x: barRect.minX,
                y: yPosition,
                width: max(2, barRect.width * ratio),
                height: segmentHeight
            )
            drawRoundedRect(fillRect, color: colors[index % colors.count], radius: 2.5)
        }
    }

    private static func drawGraphItem(
        _ item: DisplayItem,
        history: [MetricsSnapshot],
        snapshot: MetricsSnapshot?,
        in rect: NSRect,
        showIcon: Bool
    ) {
        let labelWidth: CGFloat = showIcon ? 16 : 0
        if showIcon {
            let labelRect = NSRect(x: rect.minX, y: rect.minY + 4, width: labelWidth, height: 8)
            drawLabel(shortLabel(for: item), in: labelRect)
        }

        let graphRect = NSRect(
            x: rect.minX + labelWidth,
            y: rect.minY + 2,
            width: max(10, rect.width - labelWidth),
            height: rect.height - 4
        )
        drawRoundedRect(graphRect, color: NSColor.labelColor.withAlphaComponent(0.08), radius: 3)

        let values = graphValues(for: item, history: history, snapshot: snapshot)
        guard values.count >= 2 else {
            drawRoundedRect(
                NSRect(x: graphRect.minX, y: graphRect.midY - 1, width: graphRect.width, height: 2),
                color: color(for: item).withAlphaComponent(0.45),
                radius: 1
            )
            return
        }

        let path = NSBezierPath()
        for (index, value) in values.enumerated() {
            let xPosition = graphRect.minX + graphRect.width * CGFloat(index) / CGFloat(values.count - 1)
            let yPosition = graphRect.minY + graphRect.height * CGFloat(value.clamped(to: 0...1))
            let point = NSPoint(x: xPosition, y: yPosition)
            if index == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }

        color(for: item).setStroke()
        path.lineWidth = 1.4
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    private static func drawFallbackText(
        for item: DisplayItem,
        snapshot: MetricsSnapshot?,
        showIcon: Bool,
        dataUnit: DataUnit,
        in rect: NSRect
    ) {
        let title = title(for: item, snapshot: snapshot, showIcon: showIcon, dataUnit: dataUnit)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ]
        NSAttributedString(string: title, attributes: attributes).draw(in: rect.insetBy(dx: 0, dy: 2))
    }

    private static func drawLabel(_ label: String, in rect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 7, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        NSAttributedString(string: label, attributes: attributes).draw(in: rect)
    }

    private static func drawRoundedRect(_ rect: NSRect, color: NSColor, radius: CGFloat) {
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }

    private static func barRatios(for item: DisplayItem, snapshot: MetricsSnapshot?) -> [CGFloat] {
        guard let snapshot else {
            return [0.18]
        }

        switch item {
        case .cpuUsage:
            return [CGFloat(snapshot.cpu.totalUsage.clamped(to: 0...1))]
        case .memoryUsage:
            return [CGFloat(snapshot.memory.usageRatio.clamped(to: 0...1))]
        case .networkSpeed:
            return [
                throughputRatio(snapshot.network.totalDownloadBytesPerSecond, scale: 5_000_000),
                throughputRatio(snapshot.network.totalUploadBytesPerSecond, scale: 5_000_000),
            ]
        case .diskUsage:
            return [CGFloat((primaryVolume(from: snapshot.disk.volumes)?.usageRatio ?? 0).clamped(to: 0...1))]
        case .diskIO:
            return [
                throughputRatio(snapshot.disk.readBytesPerSecond, scale: 20_000_000),
                throughputRatio(snapshot.disk.writeBytesPerSecond, scale: 20_000_000),
            ]
        case .cpuTemperature, .gpuUsage:
            return [0.18]
        }
    }

    private static func graphValues(
        for item: DisplayItem,
        history: [MetricsSnapshot],
        snapshot: MetricsSnapshot?
    ) -> [Double] {
        let snapshots = Array(history.suffix(18))
        let baseSnapshots = snapshots.isEmpty ? snapshot.map { [$0] } ?? [] : snapshots
        let rawValues = baseSnapshots.map { metricValue(for: item, snapshot: $0) }

        guard item == .networkSpeed || item == .diskIO else {
            return rawValues.map { $0.clamped(to: 0...1) }
        }

        let maximumValue = rawValues.max() ?? 0
        guard maximumValue > 0 else {
            return rawValues.map { _ in 0 }
        }

        return rawValues.map { ($0 / maximumValue).clamped(to: 0...1) }
    }

    private static func metricValue(for item: DisplayItem, snapshot: MetricsSnapshot) -> Double {
        switch item {
        case .cpuUsage:
            snapshot.cpu.totalUsage
        case .memoryUsage:
            snapshot.memory.usageRatio
        case .networkSpeed:
            Double(
                snapshot.network.totalDownloadBytesPerSecond + snapshot.network.totalUploadBytesPerSecond
            )
        case .diskUsage:
            primaryVolume(from: snapshot.disk.volumes)?.usageRatio ?? 0
        case .diskIO:
            Double(snapshot.disk.readBytesPerSecond + snapshot.disk.writeBytesPerSecond)
        case .cpuTemperature, .gpuUsage:
            0
        }
    }

    private static func throughputRatio(_ value: UInt64, scale: Double) -> CGFloat {
        CGFloat((Double(value) / scale).clamped(to: 0.05...1))
    }

    private static func primaryVolume(from volumes: [VolumeInfo]) -> VolumeInfo? {
        volumes.first { volume in
            volume.isInternal
        } ?? volumes.first
    }

    private static func shortLabel(for item: DisplayItem) -> String {
        switch item {
        case .cpuUsage:
            "CPU"
        case .memoryUsage:
            "MEM"
        case .networkSpeed:
            "NET"
        case .diskUsage:
            "DSK"
        case .diskIO:
            "I/O"
        case .cpuTemperature:
            "TMP"
        case .gpuUsage:
            "GPU"
        }
    }

    private static func color(for item: DisplayItem) -> NSColor {
        accentColors(for: item).first ?? NSColor.controlAccentColor
    }

    private static func accentColors(for item: DisplayItem) -> [NSColor] {
        switch item {
        case .cpuUsage:
            [NSColor.systemBlue]
        case .memoryUsage:
            [NSColor.systemTeal]
        case .networkSpeed:
            [NSColor.systemMint, NSColor.systemIndigo]
        case .diskUsage:
            [NSColor.systemPurple]
        case .diskIO:
            [NSColor.systemCyan, NSColor.systemOrange]
        case .cpuTemperature:
            [NSColor.systemRed]
        case .gpuUsage:
            [NSColor.systemGreen]
        }
    }
}

extension Double {
    fileprivate func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
