//
//  MenuBarRendererTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

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
