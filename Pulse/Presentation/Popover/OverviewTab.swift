//
//  OverviewTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 全メトリクスの現在値を Apple 純正風の Bento レイアウトで表示する概要タブ。
struct OverviewTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore
    let onSelectTab: (PopoverTab) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private let twoColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    init(
        coordinator: MetricsCoordinator,
        preferences: PreferencesStore,
        onSelectTab: @escaping (PopoverTab) -> Void = { _ in }
    ) {
        self.coordinator = coordinator
        self.preferences = preferences
        self.onSelectTab = onSelectTab
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            cpuHeroCard
                .pulseStaggeredEntrance(appeared: hasAppeared, delay: 0.0, reduceMotion: reduceMotion)

            LazyVGrid(columns: twoColumns, spacing: 10) {
                memoryCard
                storageCard
            }
            .pulseStaggeredEntrance(appeared: hasAppeared, delay: 0.04, reduceMotion: reduceMotion)

            LazyVGrid(columns: twoColumns, spacing: 10) {
                networkCard
                diskIOCard
            }
            .pulseStaggeredEntrance(appeared: hasAppeared, delay: 0.08, reduceMotion: reduceMotion)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .onAppear {
            guard !hasAppeared else {
                return
            }
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(PulseMotion.smooth) {
                    hasAppeared = true
                }
            }
        }
    }

    private var cpuHeroCard: some View {
        let cpu = latestSnapshot?.cpu
        return BentoTileCard(
            title: "CPU負荷",
            systemImage: "cpu",
            tint: .blue,
            height: 132,
            action: { onSelectTab(.cpu) },
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(percentageText(cpu?.totalUsage))
                            .font(.system(size: 29, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(
                                PulseMotion.resolve(PulseMotion.numeric, reduceMotion: reduceMotion),
                                value: percentageText(cpu?.totalUsage)
                            )

                        Spacer(minLength: 8)

                        HStack(spacing: 10) {
                            MetricInlineStat(
                                label: "ユーザー",
                                value: percentageText(cpu?.userUsage),
                                dotColor: .blue
                            )
                            MetricInlineStat(
                                label: "システム",
                                value: percentageText(cpu?.systemUsage),
                                dotColor: .indigo
                            )
                        }
                    }

                    CoreLoadBars(values: cpu?.perCoreUsage ?? [])
                }
            }
        )
        .accessibilityLabel("CPU負荷")
        .accessibilityValue("\(percentageText(cpu?.totalUsage))、ユーザー \(percentageText(cpu?.userUsage))")
    }

    private var memoryCard: some View {
        let memory = latestSnapshot?.memory
        return BentoTileCard(
            title: "メモリ",
            systemImage: "memorychip",
            tint: .teal,
            height: 164,
            action: { onSelectTab(.memory) },
            content: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(percentageText(memory?.usageRatio))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Spacer(minLength: 4)
                        Text(memorySubtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    DonutMetricView(
                        segments: [
                            DonutSegment(value: Double(memory?.appBytes ?? 0), color: .teal),
                            DonutSegment(value: Double(memory?.wiredBytes ?? 0), color: .blue),
                            DonutSegment(value: Double(memory?.compressedBytes ?? 0), color: .purple),
                            DonutSegment(value: Double(memory?.cachedBytes ?? 0), color: .white.opacity(0.22)),
                        ],
                        centerText: percentageText(memory?.pressure),
                        centerCaption: "圧力"
                    )

                    HStack(spacing: 8) {
                        MetricInlineStat(label: "空き", value: optionalBytes(memory?.freeBytes))
                        Spacer(minLength: 0)
                        MetricInlineStat(label: "Swap", value: optionalBytes(memory?.swapUsedBytes))
                    }
                }
            }
        )
        .accessibilityLabel("メモリ")
        .accessibilityValue("\(percentageText(memory?.usageRatio))、\(memorySubtitle)")
    }

    private var storageCard: some View {
        let volume = primaryVolume
        return BentoTileCard(
            title: "ストレージ",
            systemImage: "internaldrive",
            tint: .indigo,
            height: 164,
            action: { onSelectTab(.storage) },
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(percentageText(volume?.usageRatio))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(storageSubtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 2)

                    StorageSegmentBar(
                        usageRatio: volume?.usageRatio,
                        freeText: optionalBytes(volume?.freeBytes)
                    )

                    HStack(spacing: 4) {
                        Image(systemName: "externaldrive")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(volume?.name ?? "ボリューム待機中")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        )
        .accessibilityLabel("ストレージ")
        .accessibilityValue("\(percentageText(volume?.usageRatio))、\(storageSubtitle)")
    }

    private var networkCard: some View {
        let network = latestSnapshot?.network
        return BentoTileCard(
            title: "ネットワーク",
            systemImage: "network",
            tint: .cyan,
            height: 150,
            action: { onSelectTab(.network) },
            content: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(rateText(network?.totalDownloadBytesPerSecond))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer(minLength: 4)
                        Text(activeInterfaceSummary)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    NetworkActivityView(history: history, dataUnit: preferences.dataUnit)

                    HStack {
                        MetricInlineStat(
                            label: "送信",
                            value: rateText(network?.totalUploadBytesPerSecond),
                            dotColor: .indigo
                        )
                        Spacer(minLength: 0)
                    }
                }
            }
        )
        .accessibilityLabel("ネットワーク")
        .accessibilityValue("受信 \(rateText(network?.totalDownloadBytesPerSecond))")
    }

    private var diskIOCard: some View {
        let disk = latestSnapshot?.disk
        return BentoTileCard(
            title: "ディスクI/O",
            systemImage: "arrow.up.arrow.down.square",
            tint: .purple,
            height: 150,
            action: { onSelectTab(.storage) },
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(diskIOValue(disk))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer(minLength: 4)
                        Text("合計")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 2)

                    IOMeterView(read: disk?.readBytesPerSecond ?? 0, write: disk?.writeBytesPerSecond ?? 0)

                    HStack(spacing: 8) {
                        MetricInlineStat(label: "読", value: compactRateText(disk?.readBytesPerSecond))
                        Spacer(minLength: 0)
                        MetricInlineStat(label: "書", value: compactRateText(disk?.writeBytesPerSecond))
                    }
                }
            }
        )
        .accessibilityLabel("ディスクI/O")
        .accessibilityValue(diskIOValue(disk))
    }
}

extension OverviewTab {
    private var latestSnapshot: MetricsSnapshot? {
        coordinator.latestSnapshot
    }

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(36))
    }

    private var memorySubtitle: String {
        guard let memory = latestSnapshot?.memory else {
            return "待機中"
        }

        return "\(bytes(memory.usedBytes))/\(bytes(memory.totalBytes))"
    }

    private var storageSubtitle: String {
        guard let primaryVolume else {
            return "待機中"
        }

        return "\(bytes(primaryVolume.usedBytes)) / \(bytes(primaryVolume.totalBytes))"
    }

    private var primaryVolume: VolumeInfo? {
        latestSnapshot?.disk.volumes.first { volume in
            volume.isInternal
        } ?? latestSnapshot?.disk.volumes.first
    }

    private var activeInterfaceCount: Int {
        latestSnapshot?.network.interfaces.filter(\.isActive).count ?? 0
    }

    private var activeInterfaceSummary: String {
        guard latestSnapshot?.network != nil else {
            return "接続待ち"
        }

        return "\(activeInterfaceCount)接続"
    }

    private func diskIOValue(_ disk: DiskMetrics?) -> String {
        guard let disk else {
            return "--/s"
        }

        let (total, overflow) = disk.readBytesPerSecond.addingReportingOverflow(disk.writeBytesPerSecond)
        return ByteFormatter.rateString(
            from: overflow ? .max : total,
            dataUnit: preferences.dataUnit,
            unitStyle: .compact
        )
    }

    private func percentageText(_ ratio: Double?) -> String {
        guard let ratio else {
            return "--"
        }

        return MetricFormatter.percentage(ratio)
    }

    private func rateText(_ bytes: UInt64?) -> String {
        guard let bytes else {
            return "--/s"
        }

        return MetricFormatter.bytesPerSecond(bytes, dataUnit: preferences.dataUnit)
    }

    private func compactRateText(_ bytes: UInt64?) -> String {
        guard let bytes else {
            return "--/s"
        }

        return ByteFormatter.rateString(from: bytes, dataUnit: preferences.dataUnit, unitStyle: .compact)
    }

    private func bytes(_ value: UInt64) -> String {
        ByteFormatter.string(from: value, dataUnit: preferences.dataUnit, unitStyle: .compact)
    }

    private func optionalBytes(_ value: UInt64?) -> String {
        guard let value else {
            return "--"
        }

        return bytes(value)
    }
}
