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
        20
    }

    /// メニューバー用のグラフィカルな画像を生成する。
    @MainActor
    static func image(
        for items: [DisplayItem],
        snapshot: MetricsSnapshot?,
        history: [MetricsSnapshot],
        style: MenuBarDisplayStyle,
        options: MenuBarRenderOptions
    ) -> NSImage {
        let width = preferredLength(for: items, style: style, options: options)
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
                drawBarItem(item, snapshot: snapshot, in: itemRect, options: options)
            case .graph:
                drawGraphItem(item, history: history, snapshot: snapshot, in: itemRect, showIcon: options.showIcon)
            case .text:
                drawFallbackText(
                    for: item,
                    snapshot: snapshot,
                    showIcon: options.showIcon,
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
        options: MenuBarRenderOptions
    ) {
        switch options.barLayout {
        case .vertical:
            drawVerticalBarItem(item, snapshot: snapshot, in: rect, options: options)
        case .horizontal:
            drawHorizontalBarItem(item, snapshot: snapshot, in: rect, options: options)
        }
    }

    private static func drawVerticalBarItem(
        _ item: DisplayItem,
        snapshot: MetricsSnapshot?,
        in rect: NSRect,
        options: MenuBarRenderOptions
    ) {
        let ratios = barRatios(for: item, snapshot: snapshot)
        let colors = accentColors(for: item)
        let showsTextInsideBar = options.showBarPercentage
        let labelHeight: CGFloat = options.showIcon && !showsTextInsideBar ? 6 : 0
        if options.showIcon && !showsTextInsideBar {
            let labelRect = NSRect(x: rect.minX, y: rect.maxY - 6, width: rect.width, height: 6)
            drawLabel(shortLabel(for: item), in: labelRect, size: 6)
        }

        let barRect = NSRect(
            x: rect.minX + 1,
            y: rect.minY + 1,
            width: rect.width - 2,
            height: max(12, rect.height - labelHeight - 2)
        )
        drawVerticalLanes(ratios: ratios, colors: colors, in: barRect)

        if options.showBarPercentage {
            drawPercentLabel(for: item, snapshot: snapshot, in: barRect)
        }
    }

    private static func drawHorizontalBarItem(
        _ item: DisplayItem,
        snapshot: MetricsSnapshot?,
        in rect: NSRect,
        options: MenuBarRenderOptions
    ) {
        let barRect = NSRect(
            x: rect.minX,
            y: rect.minY + 2,
            width: rect.width,
            height: max(8, rect.height - 4)
        )
        drawRoundedRect(barRect, color: accessibleTrackColor, radius: 3.5)
        strokeRoundedRect(barRect, color: accessibleBorderColor, radius: 3.5, lineWidth: 0.6)

        let ratio = CGFloat(primaryRatio(for: item, snapshot: snapshot))
        let fillRect = NSRect(
            x: barRect.minX + 1,
            y: barRect.minY + 1,
            width: max(5, (barRect.width - 2) * ratio),
            height: 4
        )
        drawRoundedRect(fillRect, color: color(for: item), radius: 2)

        if options.showIcon {
            drawInlineLabel(wideLabel(for: item), in: barRect)
        }
    }

    private static func drawVerticalLanes(
        ratios: [CGFloat],
        colors: [NSColor],
        in rect: NSRect
    ) {
        let spacing: CGFloat = ratios.count > 1 ? 1 : 0
        let laneWidth = max(3, (rect.width - spacing * CGFloat(ratios.count - 1)) / CGFloat(max(ratios.count, 1)))

        for (index, ratio) in ratios.enumerated() {
            let xPosition = rect.minX + CGFloat(index) * (laneWidth + spacing)
            let laneRect = NSRect(x: xPosition, y: rect.minY, width: laneWidth, height: rect.height)
            drawRoundedRect(laneRect, color: NSColor.labelColor.withAlphaComponent(0.10), radius: 3)

            let fillHeight = max(2, laneRect.height * ratio)
            let fillRect = NSRect(
                x: laneRect.minX,
                y: laneRect.minY,
                width: laneRect.width,
                height: fillHeight
            )
            drawRoundedRect(fillRect, color: colors[index % colors.count], radius: 3)
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

    private static func drawLabel(_ label: String, in rect: NSRect, size: CGFloat = 7) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: size, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        NSAttributedString(string: label, attributes: attributes).draw(in: rect)
    }

    private static func drawInlineLabel(_ label: String, in rect: NSRect) {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
        shadow.shadowBlurRadius = 1.6
        shadow.shadowOffset = .zero

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
            .foregroundColor: NSColor.white,
            .shadow: shadow,
        ]
        let text = NSAttributedString(string: label, attributes: attributes)
        let textSize = text.size()
        let labelRect = NSRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: labelRect)
    }

    private static func drawRoundedRect(_ rect: NSRect, color: NSColor, radius: CGFloat) {
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }

    private static func strokeRoundedRect(
        _ rect: NSRect,
        color: NSColor,
        radius: CGFloat,
        lineWidth: CGFloat
    ) {
        color.setStroke()
        let strokeRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = NSBezierPath(roundedRect: strokeRect, xRadius: radius, yRadius: radius)
        path.lineWidth = lineWidth
        path.stroke()
    }

    private static func drawPercentLabel(for item: DisplayItem, snapshot: MetricsSnapshot?, in rect: NSRect) {
        let rawPercent = Int((primaryRatio(for: item, snapshot: snapshot) * 100).rounded())
        let percent = Swift.min(Swift.max(rawPercent, 0), 100)
        let label = "\(percent)%"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 7, weight: .bold),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.windowBackgroundColor.withAlphaComponent(0.50),
        ]
        let text = NSAttributedString(string: label, attributes: attributes)
        let textSize = text.size()
        let labelRect = NSRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: labelRect)
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
        case .cpuTemperature:
            return [CGFloat(temperatureRatio(snapshot.thermal.primaryTemperatureCelsius))]
        case .gpuUsage:
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
        case .cpuTemperature:
            temperatureRatio(snapshot.thermal.primaryTemperatureCelsius)
        case .gpuUsage:
            0
        }
    }

    private static func primaryRatio(for item: DisplayItem, snapshot: MetricsSnapshot?) -> Double {
        guard let snapshot else {
            return 0
        }

        return switch item {
        case .cpuUsage:
            snapshot.cpu.totalUsage.clamped(to: 0...1)
        case .memoryUsage:
            snapshot.memory.usageRatio.clamped(to: 0...1)
        case .networkSpeed:
            (Double(
                snapshot.network.totalDownloadBytesPerSecond + snapshot.network.totalUploadBytesPerSecond
            ) / 10_000_000).clamped(to: 0...1)
        case .diskUsage:
            (primaryVolume(from: snapshot.disk.volumes)?.usageRatio ?? 0).clamped(to: 0...1)
        case .diskIO:
            (Double(snapshot.disk.readBytesPerSecond + snapshot.disk.writeBytesPerSecond) / 40_000_000)
                .clamped(to: 0...1)
        case .cpuTemperature:
            temperatureRatio(snapshot.thermal.primaryTemperatureCelsius)
        case .gpuUsage:
            0
        }
    }

    private static func throughputRatio(_ value: UInt64, scale: Double) -> CGFloat {
        CGFloat((Double(value) / scale).clamped(to: 0.05...1))
    }

    private static func temperatureRatio(_ value: Double?) -> Double {
        guard let value else {
            return 0.05
        }

        return ((value - 20) / 70).clamped(to: 0.05...1)
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

    private static func wideLabel(for item: DisplayItem) -> String {
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

    private static var accessibleTrackColor: NSColor {
        NSColor(calibratedWhite: 0.02, alpha: 0.82)
    }

    private static var accessibleBorderColor: NSColor {
        NSColor.white.withAlphaComponent(0.18)
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
            [NSColor.systemOrange]
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
