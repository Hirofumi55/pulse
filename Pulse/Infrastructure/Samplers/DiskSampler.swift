//
//  DiskSampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import IOKit
import os

private let logger = Logger(category: .sampler)

/// Foundation と IOKit からディスク容量と I/O 速度を取得する Sampler。
actor DiskSampler: Sampler {
    private let volumeResourceKeys: Set<URLResourceKey> = [
        .volumeAvailableCapacityKey,
        .volumeIsInternalKey,
        .volumeNameKey,
        .volumeTotalCapacityKey,
    ]

    private var previousIOSample: DiskIOSample?

    func sample() async throws -> DiskMetrics {
        let volumes = try sampleVolumes()
        let ioSample = try sampleDiskIO()
        let speed = calculateSpeed(counters: ioSample, uptime: ProcessInfo.processInfo.systemUptime)

        return DiskMetrics(
            volumes: volumes,
            readBytesPerSecond: speed.read,
            writeBytesPerSecond: speed.write
        )
    }

    private func sampleVolumes() throws -> [VolumeInfo] {
        guard
            let urls = FileManager.default.mountedVolumeURLs(
                includingResourceValuesForKeys: Array(volumeResourceKeys),
                options: [.skipHiddenVolumes]
            )
        else {
            throw SamplerError.unexpectedFormat
        }

        return try sampleVolumes(from: urls)
    }

    func sampleVolumes(from urls: [URL]) throws -> [VolumeInfo] {
        var volumes: [VolumeInfo] = []
        var firstError: (any Error)?
        var skippedVolumeCount = 0

        for url in urls {
            do {
                if let volume = try makeVolumeInfo(from: url) {
                    volumes.append(volume)
                }
            } catch {
                firstError = firstError ?? error
                skippedVolumeCount += 1
            }
        }

        if skippedVolumeCount > 0 {
            logger.debug("Unreadable mounted volumes skipped: \(skippedVolumeCount, privacy: .public)")
        }

        if volumes.isEmpty, let firstError {
            throw firstError
        }

        return volumes.sorted { left, right in
            if left.isInternal != right.isInternal {
                return left.isInternal
            }
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        }
    }

    private func makeVolumeInfo(from url: URL) throws -> VolumeInfo? {
        let values = try url.resourceValues(forKeys: volumeResourceKeys)

        guard
            let totalCapacity = values.volumeTotalCapacity,
            let availableCapacity = values.volumeAvailableCapacity,
            totalCapacity > 0,
            availableCapacity >= 0
        else {
            return nil
        }

        let id = url.path(percentEncoded: false)
        let name = displayName(for: url, volumeName: values.volumeName, fallbackID: id)
        let freeBytes = min(UInt64(availableCapacity), UInt64(totalCapacity))

        return VolumeInfo(
            id: id,
            name: name,
            totalBytes: UInt64(totalCapacity),
            freeBytes: freeBytes,
            isInternal: values.volumeIsInternal ?? false
        )
    }

    private func displayName(for url: URL, volumeName: String?, fallbackID: String) -> String {
        if let volumeName, !volumeName.isEmpty {
            return volumeName
        }

        let lastPathComponent = url.lastPathComponent
        if !lastPathComponent.isEmpty {
            return lastPathComponent
        }

        return fallbackID
    }

    private func sampleDiskIO() throws -> [UInt64: DiskIOCounters] {
        guard let matching = IOServiceMatching("IOBlockStorageDriver") else {
            throw SamplerError.ioKitFailed
        }

        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

        guard result == KERN_SUCCESS else {
            throw SamplerError.ioKitFailed
        }

        defer {
            IOObjectRelease(iterator)
        }

        var counters: [UInt64: DiskIOCounters] = [:]

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else {
                break
            }

            defer {
                IOObjectRelease(service)
            }

            var entryID: UInt64 = 0
            guard
                IORegistryEntryGetRegistryEntryID(service, &entryID) == KERN_SUCCESS,
                let statistics = statisticsDictionary(for: service)
            else {
                continue
            }

            counters[entryID] = DiskIOCounters(
                read: unsignedInteger(from: statistics["Bytes (Read)"]),
                write: unsignedInteger(from: statistics["Bytes (Write)"])
            )
        }

        return counters
    }

    private func statisticsDictionary(for service: io_registry_entry_t) -> [String: Any]? {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)

        guard
            result == KERN_SUCCESS,
            let dictionary = properties?.takeRetainedValue() as? [String: Any],
            let statistics = dictionary["Statistics"] as? [String: Any]
        else {
            return nil
        }

        return statistics
    }

    func calculateSpeed(counters: [UInt64: DiskIOCounters], uptime: TimeInterval) -> (read: UInt64, write: UInt64) {
        defer {
            previousIOSample = DiskIOSample(counters: counters, uptime: uptime)
        }

        guard let previousIOSample, uptime > previousIOSample.uptime else {
            return (0, 0)
        }

        var readDelta = 0.0
        var writeDelta = 0.0
        for (entryID, current) in counters {
            guard let previous = previousIOSample.counters[entryID] else { continue }
            readDelta += Double(difference(current: current.read, previous: previous.read))
            writeDelta += Double(difference(current: current.write, previous: previous.write))
        }

        let elapsedSeconds = uptime - previousIOSample.uptime
        return (
            bytesPerSecond(readDelta, elapsedSeconds: elapsedSeconds),
            bytesPerSecond(writeDelta, elapsedSeconds: elapsedSeconds)
        )
    }

    private func unsignedInteger(from value: Any?) -> UInt64? {
        switch value {
        case let value as UInt64:
            value
        case let value as UInt:
            UInt64(value)
        case let value as Int where value >= 0:
            UInt64(value)
        case let value as Int64 where value >= 0:
            UInt64(value)
        case let value as NSNumber where value.int64Value >= 0:
            UInt64(value.uint64Value)
        default:
            nil
        }
    }

    private func bytesPerSecond(_ bytes: Double, elapsedSeconds: TimeInterval) -> UInt64 {
        let value = bytes / elapsedSeconds

        guard value.isFinite, value > 0 else {
            return 0
        }

        if value >= Double(UInt64.max) {
            return UInt64.max
        }

        return UInt64(value)
    }

    private func difference(current: UInt64?, previous: UInt64?) -> UInt64 {
        if let current, let previous, current >= previous {
            current - previous
        } else {
            0
        }
    }
}

struct DiskIOCounters: Sendable {
    let read: UInt64?
    let write: UInt64?
}

private struct DiskIOSample: Sendable {
    let counters: [UInt64: DiskIOCounters]
    let uptime: TimeInterval
}
