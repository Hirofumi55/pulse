//
//  NetworkSampler.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Darwin
import Foundation

/// sysctl からネットワーク通信速度を取得する Sampler。
actor NetworkSampler: Sampler {
    private let excludedInterfacePrefixes = [
        "lo",
        "awdl",
        "llw",
        "utun",
        "bridge",
        "gif",
        "stf",
        "p2p",
    ]

    private var previousSamples: [String: NetworkCounterSample] = [:]

    func sample() async throws -> NetworkMetrics {
        let rawStats = try sampleRawStats()
        let currentSamples = Dictionary(
            uniqueKeysWithValues: rawStats.map { rawStat in
                (
                    rawStat.name,
                    NetworkCounterSample(
                        downloadBytes: rawStat.downloadBytes,
                        uploadBytes: rawStat.uploadBytes,
                        timestamp: rawStat.timestamp
                    )
                )
            }
        )
        let interfaces = rawStats.compactMap { rawStat in
            makeInterfaceInfo(from: rawStat)
        }

        previousSamples = currentSamples
        return NetworkMetrics(interfaces: interfaces)
    }

    private func sampleRawStats() throws -> [NetworkRawStats] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        let sizeResult = mib.withUnsafeMutableBufferPointer { pointer in
            sysctl(pointer.baseAddress, u_int(pointer.count), nil, &length, nil, 0)
        }

        guard sizeResult == 0 else {
            throw SamplerError.sysctlFailed
        }

        guard length > 0 else {
            throw SamplerError.insufficientData
        }

        var buffer = [UInt8](repeating: 0, count: length)
        let dataResult = buffer.withUnsafeMutableBytes { rawBuffer in
            mib.withUnsafeMutableBufferPointer { pointer in
                sysctl(pointer.baseAddress, u_int(pointer.count), rawBuffer.baseAddress, &length, nil, 0)
            }
        }

        guard dataResult == 0 else {
            throw SamplerError.sysctlFailed
        }

        return try parseRawStats(from: buffer, validLength: length, timestamp: .now)
    }

    private func parseRawStats(
        from buffer: [UInt8],
        validLength: Int,
        timestamp: Date
    ) throws -> [NetworkRawStats] {
        var stats: [NetworkRawStats] = []
        var offset = 0
        let messageSize = MemoryLayout<if_msghdr2>.stride
        let limit = min(validLength, buffer.count)

        while offset + messageSize <= limit {
            let message = buffer.withUnsafeBytes { rawBuffer in
                rawBuffer.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
            }
            let messageLength = Int(message.ifm_msglen)

            guard messageLength > 0, offset + messageLength <= limit else {
                throw SamplerError.unexpectedFormat
            }

            defer {
                offset += messageLength
            }

            guard
                message.ifm_type == UInt8(RTM_IFINFO2),
                let name = interfaceName(
                    from: buffer,
                    messageOffset: offset,
                    messageLength: messageLength
                ),
                shouldIncludeInterface(named: name)
            else {
                continue
            }

            stats.append(
                NetworkRawStats(
                    name: name,
                    downloadBytes: message.ifm_data.ifi_ibytes,
                    uploadBytes: message.ifm_data.ifi_obytes,
                    flags: UInt32(bitPattern: message.ifm_flags),
                    timestamp: timestamp
                )
            )
        }

        return stats.sorted { left, right in
            left.name.localizedStandardCompare(right.name) == .orderedAscending
        }
    }

    private func makeInterfaceInfo(from rawStat: NetworkRawStats) -> InterfaceInfo? {
        guard shouldIncludeInterface(named: rawStat.name) else {
            return nil
        }

        let speed = calculateSpeed(for: rawStat)

        return InterfaceInfo(
            id: rawStat.name,
            displayName: rawStat.name,
            downloadBytesPerSecond: speed.download,
            uploadBytesPerSecond: speed.upload,
            isActive: isInterfaceActive(flags: rawStat.flags)
        )
    }

    private func calculateSpeed(for rawStat: NetworkRawStats) -> (download: UInt64, upload: UInt64) {
        guard let previousSample = previousSamples[rawStat.name] else {
            return (0, 0)
        }

        let elapsedSeconds = rawStat.timestamp.timeIntervalSince(previousSample.timestamp)
        guard elapsedSeconds > 0 else {
            return (0, 0)
        }

        let downloadDelta = difference(current: rawStat.downloadBytes, previous: previousSample.downloadBytes)
        let uploadDelta = difference(current: rawStat.uploadBytes, previous: previousSample.uploadBytes)

        return (
            bytesPerSecond(downloadDelta, elapsedSeconds: elapsedSeconds),
            bytesPerSecond(uploadDelta, elapsedSeconds: elapsedSeconds)
        )
    }

    private func interfaceName(
        from buffer: [UInt8],
        messageOffset: Int,
        messageLength: Int
    ) -> String? {
        let addressOffset = messageOffset + MemoryLayout<if_msghdr2>.stride
        let addressLimit = min(messageOffset + messageLength, buffer.count)
        guard addressOffset + MemoryLayout<sockaddr_dl>.stride <= addressLimit else {
            return nil
        }

        let address = buffer.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(fromByteOffset: addressOffset, as: sockaddr_dl.self)
        }
        let nameLength = min(Int(address.sdl_nlen), MemoryLayout.size(ofValue: address.sdl_data))
        guard nameLength > 0 else {
            return nil
        }

        let nameBytes = withUnsafeBytes(of: address.sdl_data) { rawBuffer in
            Array(rawBuffer.prefix(nameLength)).filter { byte in
                byte != 0
            }
        }

        guard !nameBytes.isEmpty else {
            return nil
        }

        return String(bytes: nameBytes, encoding: .utf8)
    }

    private func shouldIncludeInterface(named name: String) -> Bool {
        !excludedInterfacePrefixes.contains { prefix in
            name.hasPrefix(prefix)
        }
    }

    private func isInterfaceActive(flags: UInt32) -> Bool {
        let up = (flags & UInt32(IFF_UP)) != 0
        let running = (flags & UInt32(IFF_RUNNING)) != 0
        let loopback = (flags & UInt32(IFF_LOOPBACK)) != 0
        return up && running && !loopback
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

private struct NetworkRawStats: Sendable, Equatable {
    let name: String
    let downloadBytes: UInt64
    let uploadBytes: UInt64
    let flags: UInt32
    let timestamp: Date
}

private struct NetworkCounterSample: Sendable, Equatable {
    let downloadBytes: UInt64
    let uploadBytes: UInt64
    let timestamp: Date
}
