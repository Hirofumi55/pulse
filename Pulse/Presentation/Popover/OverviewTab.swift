//
//  OverviewTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 全メトリクスの現在値をまとめて表示するタブ。
struct OverviewTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private var latestSnapshot: MetricsSnapshot? {
        coordinator.latestSnapshot
    }

    private var history: [MetricsSnapshot] {
        Array(coordinator.history.suffix(36))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                cpuCard
                memoryCard
                thermalCard
                storageCard
                networkCard
                diskIOCard
            }
        }
        .padding(12)
    }

    private var cpuCard: some View {
        let cpu = latestSnapshot?.cpu
        return MetricWidgetCard(
            title: "CPU負荷",
            systemImage: "cpu",
            value: percentageText(cpu?.totalUsage),
            subtitle: cpu.map { "\($0.logicalCoreCount)スレッド" } ?? "取得待ち",
            tint: .blue
        ) {
            CoreLoadBars(values: cpu?.perCoreUsage ?? [])
        } footer: {
            WidgetPill(text: "User \(percentageText(cpu?.userUsage))", systemImage: "person")
            WidgetPill(text: "Sys \(percentageText(cpu?.systemUsage))", systemImage: "gearshape")
        }
    }

    private var thermalCard: some View {
        let thermal = latestSnapshot?.thermal
        let cpuTemperature = thermal?.cpuTemperatureCelsius
        return MetricWidgetCard(
            title: "CPU温度",
            systemImage: "thermometer.medium",
            value: temperatureText(cpuTemperature),
            subtitle: cpuTemperatureSubtitle(thermal),
            tint: .orange
        ) {
            TemperatureGaugeView(temperature: cpuTemperature)
        } footer: {
            WidgetPill(
                text: "電池 \(temperatureText(thermal?.batteryTemperatureCelsius))",
                systemImage: "battery.100percent"
            )
            WidgetPill(text: thermalStatusText(thermal), systemImage: "waveform.path.ecg")
        }
    }

    private var memoryCard: some View {
        let memory = latestSnapshot?.memory
        return MetricWidgetCard(
            title: "メモリ",
            systemImage: "memorychip",
            value: percentageText(memory?.usageRatio),
            subtitle: memorySubtitle,
            tint: .teal
        ) {
            DonutMetricView(
                segments: [
                    DonutSegment(value: Double(memory?.appBytes ?? 0), color: .teal),
                    DonutSegment(value: Double(memory?.wiredBytes ?? 0), color: .blue),
                    DonutSegment(value: Double(memory?.compressedBytes ?? 0), color: .purple),
                    DonutSegment(value: Double(memory?.cachedBytes ?? 0), color: .secondary.opacity(0.35)),
                ],
                centerText: percentageText(memory?.pressure),
                centerCaption: "圧力"
            )
        } footer: {
            WidgetPill(text: "空き \(bytes(memory?.freeBytes ?? 0))", systemImage: "arrow.down.to.line")
            WidgetPill(text: "Swap \(bytes(memory?.swapUsedBytes ?? 0))", systemImage: "arrow.left.arrow.right")
        }
    }

    private var storageCard: some View {
        let volume = primaryVolume
        return MetricWidgetCard(
            title: "ストレージ",
            systemImage: "internaldrive",
            value: percentageText(volume?.usageRatio),
            subtitle: storageSubtitle,
            tint: .indigo
        ) {
            DonutMetricView(
                segments: [
                    DonutSegment(value: volume == nil ? 0 : Double(volume?.usedBytes ?? 0), color: .indigo),
                    DonutSegment(value: Double(volume?.freeBytes ?? 0), color: .secondary.opacity(0.28)),
                ],
                centerText: bytes(volume?.freeBytes ?? 0),
                centerCaption: "空き"
            )
        } footer: {
            WidgetPill(text: volume?.name ?? "ボリューム待機中", systemImage: "externaldrive")
        }
    }

    private var diskIOCard: some View {
        let disk = latestSnapshot?.disk
        return MetricWidgetCard(
            title: "ディスクI/O",
            systemImage: "arrow.up.arrow.down.square",
            value: diskIOValue(disk),
            subtitle: "読み書き合計",
            tint: .purple
        ) {
            IOMeterView(read: disk?.readBytesPerSecond ?? 0, write: disk?.writeBytesPerSecond ?? 0)
        } footer: {
            WidgetPill(text: "読 \(rateText(disk?.readBytesPerSecond))", systemImage: "arrow.down")
            WidgetPill(text: "書 \(rateText(disk?.writeBytesPerSecond))", systemImage: "arrow.up")
        }
    }

    private var networkCard: some View {
        let network = latestSnapshot?.network
        return MetricWidgetCard(
            title: "ネットワーク",
            systemImage: "network",
            value: rateText(network?.totalDownloadBytesPerSecond),
            subtitle: "受信",
            tint: .cyan
        ) {
            NetworkActivityView(history: history, dataUnit: preferences.dataUnit)
        } footer: {
            WidgetPill(
                text: networkUploadText(network),
                systemImage: "arrow.up"
            )
            WidgetPill(text: activeInterfaceSummary, systemImage: "antenna.radiowaves.left.and.right")
        }
    }

    private var memorySubtitle: String {
        guard let memory = latestSnapshot?.memory else {
            return "待機中"
        }

        let used = memory.appBytes + memory.wiredBytes + memory.compressedBytes
        return "\(bytes(used)) / \(bytes(memory.totalBytes))"
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
            return "IF待機中"
        }

        return "\(activeInterfaceCount)IF"
    }

    private func networkUploadText(_ network: NetworkMetrics?) -> String {
        "送信 \(rateText(network?.totalUploadBytesPerSecond))"
    }

    private func diskIOValue(_ disk: DiskMetrics?) -> String {
        guard let disk else {
            return "--/s"
        }

        return ByteFormatter.rateString(
            from: disk.readBytesPerSecond + disk.writeBytesPerSecond,
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

    private func bytes(_ value: UInt64) -> String {
        ByteFormatter.string(from: value, dataUnit: preferences.dataUnit, unitStyle: .compact)
    }

    private func temperatureText(_ celsius: Double?) -> String {
        guard let celsius else {
            return "--"
        }

        switch preferences.temperatureUnit {
        case .celsius:
            return "\(Int(celsius.rounded()))℃"
        case .fahrenheit:
            return "\(Int((celsius * 9 / 5 + 32).rounded()))℉"
        }
    }

    private func cpuTemperatureSubtitle(_ thermal: ThermalMetrics?) -> String {
        thermal?.cpuTemperatureStatusMessage ?? "CPU温度待機中"
    }

    private func thermalStatusText(_ thermal: ThermalMetrics?) -> String {
        guard let thermal else {
            return "CPU待機中"
        }

        guard let temperature = thermal.cpuTemperatureCelsius else {
            return "取得不可"
        }

        if temperature >= 80 {
            return "高温"
        }
        if temperature >= 60 {
            return "注意"
        }
        return "安定"
    }
}

private struct MetricWidgetCard<Visual: View, Footer: View>: View {
    @Environment(PreferencesStore.self) private var preferences

    let title: String
    let systemImage: String
    let value: String
    let subtitle: String
    let tint: Color
    let visual: Visual
    let footer: Footer

    init(
        title: String,
        systemImage: String,
        value: String,
        subtitle: String,
        tint: Color,
        @ViewBuilder visual: () -> Visual,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.systemImage = systemImage
        self.value = value
        self.subtitle = subtitle
        self.tint = tint
        self.visual = visual()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            visual
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            FlowPills {
                footer
            }
        }
        .padding(9)
        .frame(height: 190, alignment: .topLeading)
        .pulseGlassPanel(
            tint: tint,
            materialOpacity: PulseGlassStyle.panelMaterialOpacity(
                for: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius
            ),
            tone: .clearBlack
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)、\(subtitle)")
    }
}

private struct CoreLoadBars: View {
    let values: [Double]

    private var displayValues: [Double] {
        values.isEmpty ? Array(repeating: 0, count: 8) : values
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(displayValues.enumerated()), id: \.offset) { item in
                    VStack(spacing: 1) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(.blue.opacity(0.28))
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(barGradient)
                            .frame(height: barHeight(value: item.element, totalHeight: proxy.size.height))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 43)
    }

    private var barGradient: LinearGradient {
        LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .top, endPoint: .bottom)
    }

    private func barHeight(value: Double, totalHeight: CGFloat) -> CGFloat {
        max(totalHeight * CGFloat(Swift.min(Swift.max(value, 0), 1)), 2)
    }
}

private struct DonutMetricView: View {
    let segments: [DonutSegment]
    let centerText: String
    let centerCaption: String

    private var total: Double {
        max(segments.reduce(0) { result, segment in result + max(segment.value, 0) }, 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.16), lineWidth: 13)

            ForEach(Array(segments.enumerated()), id: \.offset) { item in
                Circle()
                    .trim(from: startTrim(at: item.offset), to: endTrim(at: item.offset))
                    .stroke(
                        item.element.color,
                        style: StrokeStyle(lineWidth: 13, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 0) {
                Text(centerText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(centerCaption)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 70, height: 70)
        .frame(maxWidth: .infinity)
    }

    private func startTrim(at index: Int) -> Double {
        segments.prefix(index).reduce(0) { result, segment in
            result + max(segment.value, 0) / total
        }
    }

    private func endTrim(at index: Int) -> Double {
        startTrim(at: index) + max(segments[index].value, 0) / total
    }
}

private struct DonutSegment {
    let value: Double
    let color: Color
}

private struct NetworkActivityView: View {
    let history: [MetricsSnapshot]
    let dataUnit: DataUnit

    private var maxValue: Double {
        max(
            history.map { snapshot in
                Double(
                    max(
                        snapshot.network.totalDownloadBytesPerSecond,
                        snapshot.network.totalUploadBytesPerSecond
                    )
                )
            }.max() ?? 1,
            1
        )
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(history.suffix(22).enumerated()), id: \.offset) { item in
                    Capsule()
                        .fill(.cyan.opacity(0.35))
                        .overlay(alignment: .bottom) {
                            Capsule()
                                .fill(.cyan)
                                .frame(height: height(for: item.element.network.totalDownloadBytesPerSecond))
                        }
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 44)

            HStack {
                Text("ピーク")
                Spacer()
                Text(ByteFormatter.rateString(from: UInt64(maxValue), dataUnit: dataUnit, unitStyle: .compact))
                    .monospacedDigit()
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }

    private func height(for bytes: UInt64) -> CGFloat {
        max(44 * CGFloat(Double(bytes) / maxValue), 2)
    }
}

private struct FlowPills<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 5) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
