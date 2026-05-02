//
//  MenuBarRendererTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Foundation
import Testing

@testable import Pulse

@Suite("Menu Bar Renderer Tests")
struct MenuBarRendererTests {
    @Test("Renderer creates placeholder titles")
    func createsPlaceholderTitles() {
        #expect(MenuBarRenderer.title(for: .cpuUsage, snapshot: nil, showIcon: true, dataUnit: .iec) == "CPU --%")
        #expect(MenuBarRenderer.title(for: .memoryUsage, snapshot: nil, showIcon: false, dataUnit: .iec) == "--%")
        #expect(MenuBarRenderer.title(for: .networkSpeed, snapshot: nil, showIcon: true, dataUnit: .iec) == "↓ -- ↑ --")
    }

    @Test("Renderer creates metric titles")
    func createsMetricTitles() {
        let snapshot = makeSnapshot()

        #expect(title(for: .cpuUsage, snapshot: snapshot, dataUnit: .iec) == "CPU 42%")
        #expect(title(for: .memoryUsage, snapshot: snapshot, dataUnit: .iec) == "MEM 50%")
        #expect(title(for: .diskUsage, snapshot: snapshot, dataUnit: .iec) == "DSK 75%")
        #expect(title(for: .networkSpeed, snapshot: snapshot, dataUnit: .si) == "↓ 2.5M ↑ 154K")
        #expect(title(for: .diskIO, snapshot: snapshot, dataUnit: .iec) == "↓ 1.0M ↑ 512K")
        #expect(title(for: .cpuTemperature, snapshot: snapshot, dataUnit: .iec) == "温度 31℃")
    }

    @Test("Renderer creates combined title")
    func createsCombinedTitle() {
        let snapshot = makeSnapshot()
        let title = MenuBarRenderer.title(
            for: [.cpuUsage, .memoryUsage, .networkSpeed],
            snapshot: snapshot,
            showIcon: true,
            dataUnit: .si
        )

        #expect(title == "CPU 42%  MEM 50%  ↓ 2.5M ↑ 154K")
    }

    @Test("Renderer creates graphic menu bar images")
    @MainActor
    func createsGraphicMenuBarImages() {
        let snapshot = makeSnapshot()
        let image = MenuBarRenderer.image(
            for: [.cpuUsage, .memoryUsage, .networkSpeed],
            snapshot: snapshot,
            history: [snapshot],
            style: .bar,
            options: barOptions
        )

        #expect(image.size.width > 0)
        #expect(image.size.height == 20)
    }

    @Test("Renderer uses compact length for graphic styles")
    @MainActor
    func usesCompactLengthForGraphicStyles() {
        let items: [DisplayItem] = [.cpuUsage, .memoryUsage, .networkSpeed]
        let textLength = MenuBarRenderer.preferredLength(for: items, style: .text, options: barOptions)
        let barLength = MenuBarRenderer.preferredLength(for: items, style: .bar, options: barOptions)

        #expect(barLength < textLength)
    }

    @Test("Renderer keeps vertical bars compact")
    @MainActor
    func keepsVerticalBarsCompact() {
        let items: [DisplayItem] = [.cpuUsage]
        let verticalOptions = MenuBarRenderOptions(
            showIcon: true,
            barLayout: .vertical,
            showBarPercentage: true
        )
        let horizontalOptions = MenuBarRenderOptions(
            showIcon: true,
            barLayout: .horizontal,
            showBarPercentage: true
        )
        let verticalLength = MenuBarRenderer.preferredLength(
            for: items,
            style: .bar,
            options: verticalOptions
        )
        let horizontalLength = MenuBarRenderer.preferredLength(
            for: items,
            style: .bar,
            options: horizontalOptions
        )

        #expect(verticalLength < horizontalLength)
    }

    @Test("Renderer fills vertical bars along the vertical axis")
    @MainActor
    func fillsVerticalBarsAlongVerticalAxis() {
        let snapshot = makeSnapshot()
        let image = MenuBarRenderer.image(
            for: [.cpuUsage],
            snapshot: snapshot,
            history: [snapshot],
            style: .bar,
            options: MenuBarRenderOptions(
                showIcon: false,
                barLayout: .vertical,
                showBarPercentage: false
            )
        )
        var rect = NSRect(origin: .zero, size: image.size)
        let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)

        #expect(cgImage != nil)
        guard let cgImage else {
            return
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let bandHeight = max(1, bitmap.pixelsHigh / 4)
        let topBand = 0..<bandHeight
        let bottomBand = (bitmap.pixelsHigh - bandHeight)..<bitmap.pixelsHigh
        let topColored = bluePixelCount(in: bitmap, rows: topBand)
        let bottomColored = bluePixelCount(in: bitmap, rows: bottomBand)

        #expect(Swift.abs(topColored - bottomColored) > 20)
    }

    @Test("Horizontal bars keep a dark readable label area")
    @MainActor
    func horizontalBarsKeepDarkReadableLabelArea() {
        let snapshot = makeSnapshot()
        let image = MenuBarRenderer.image(
            for: [.memoryUsage],
            snapshot: snapshot,
            history: [snapshot],
            style: .bar,
            options: MenuBarRenderOptions(
                showIcon: true,
                barLayout: .horizontal,
                showBarPercentage: false
            )
        )
        var rect = NSRect(origin: .zero, size: image.size)
        let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)

        #expect(cgImage != nil)
        guard let cgImage else {
            return
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let centerRows = (bitmap.pixelsHigh / 3)..<(bitmap.pixelsHigh * 2 / 3)
        let darkPixels = darkPixelCount(in: bitmap, rows: centerRows)
        let minimumReadableArea = bitmap.pixelsWide * centerRows.count / 3

        #expect(darkPixels > minimumReadableArea)
    }

    private var barOptions: MenuBarRenderOptions {
        MenuBarRenderOptions(showIcon: true, barLayout: .vertical, showBarPercentage: true)
    }

    private func bluePixelCount(in bitmap: NSBitmapImageRep, rows: Range<Int>) -> Int {
        var count = 0
        for yPosition in rows {
            for xPosition in 0..<bitmap.pixelsWide {
                guard
                    let color = bitmap.colorAt(x: xPosition, y: yPosition)?.usingColorSpace(.sRGB),
                    color.alphaComponent > 0.2,
                    color.blueComponent > 0.35,
                    color.redComponent < 0.4
                else {
                    continue
                }
                count += 1
            }
        }
        return count
    }

    private func darkPixelCount(in bitmap: NSBitmapImageRep, rows: Range<Int>) -> Int {
        var count = 0
        for yPosition in rows {
            for xPosition in 0..<bitmap.pixelsWide {
                guard
                    let color = bitmap.colorAt(x: xPosition, y: yPosition)?.usingColorSpace(.sRGB),
                    color.alphaComponent > 0.45,
                    color.redComponent < 0.18,
                    color.greenComponent < 0.18,
                    color.blueComponent < 0.18
                else {
                    continue
                }
                count += 1
            }
        }
        return count
    }

    private func makeSnapshot() -> MetricsSnapshot {
        MetricsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            cpu: CPUMetrics(
                totalUsage: 0.42,
                userUsage: 0.30,
                systemUsage: 0.12,
                idleUsage: 0.58,
                perCoreUsage: [0.42],
                physicalCoreCount: 1,
                logicalCoreCount: 1
            ),
            memory: MemoryMetrics(
                totalBytes: 100,
                appBytes: 20,
                wiredBytes: 20,
                compressedBytes: 10,
                cachedBytes: 30,
                freeBytes: 20,
                swapUsedBytes: 0,
                pressure: 0.1
            ),
            disk: DiskMetrics(
                volumes: [
                    VolumeInfo(
                        id: "/",
                        name: "Macintosh HD",
                        totalBytes: 100,
                        freeBytes: 25,
                        isInternal: true
                    )
                ],
                readBytesPerSecond: 1_048_576,
                writeBytesPerSecond: 524_288
            ),
            network: NetworkMetrics(
                interfaces: [
                    InterfaceInfo(
                        id: "en0",
                        displayName: "en0",
                        downloadBytesPerSecond: 2_500_000,
                        uploadBytesPerSecond: 154_000,
                        isActive: true
                    )
                ]
            ),
            thermal: ThermalMetrics(
                cpuTemperatureCelsius: nil,
                batteryTemperatureCelsius: 30.6
            )
        )
    }

    private func title(
        for item: DisplayItem,
        snapshot: MetricsSnapshot,
        dataUnit: DataUnit
    ) -> String {
        MenuBarRenderer.title(for: item, snapshot: snapshot, showIcon: true, dataUnit: dataUnit)
    }
}
