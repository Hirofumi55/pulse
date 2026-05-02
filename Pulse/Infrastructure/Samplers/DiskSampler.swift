//
//  DiskSampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import IOKit

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
        let speed = calculateSpeed(current: ioSample)

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

        let volumes = try urls.compactMap { url in
            try makeVolumeInfo(from: url)
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

    private func sampleDiskIO() throws -> DiskIOSample {
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

        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else {
                break
            }

            defer {
                IOObjectRelease(service)
            }

            guard let statistics = statisticsDictionary(for: service) else {
                continue
            }

            totalRead += unsignedInteger(from: statistics["Bytes (Read)"]) ?? 0
            totalWrite += unsignedInteger(from: statistics["Bytes (Write)"]) ?? 0
        }

        return DiskIOSample(readBytes: totalRead, writeBytes: totalWrite, timestamp: .now)
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

    private func calculateSpeed(current: DiskIOSample) -> (read: UInt64, write: UInt64) {
        defer {
            previousIOSample = current
        }

        guard let previousIOSample else {
            return (0, 0)
        }

        let elapsedSeconds = current.timestamp.timeIntervalSince(previousIOSample.timestamp)
        guard elapsedSeconds > 0 else {
            return (0, 0)
        }

        let readDelta = difference(current: current.readBytes, previous: previousIOSample.readBytes)
        let writeDelta = difference(current: current.writeBytes, previous: previousIOSample.writeBytes)

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

    private func bytesPerSecond(_ bytes: UInt64, elapsedSeconds: TimeInterval) -> UInt64 {
        let value = Double(bytes) / elapsedSeconds

        guard value.isFinite, value > 0 else {
            return 0
        }

        if value >= Double(UInt64.max) {
            return UInt64.max
        }

        return UInt64(value)
    }

    private func difference(current: UInt64, previous: UInt64) -> UInt64 {
        if current >= previous {
            current - previous
        } else {
            0
        }
    }
}

private struct DiskIOSample: Sendable, Equatable {
    let readBytes: UInt64
    let writeBytes: UInt64
    let timestamp: Date
}
