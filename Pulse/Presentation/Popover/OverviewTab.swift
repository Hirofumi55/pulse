//
//  OverviewTab.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 現在の計測値と直近1分の履歴を一覧にする。
struct OverviewTab: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore
    let onSelectTab: (PopoverTab) -> Void

    private struct Metric {
        let title: String
        let icon: String
        let tab: PopoverTab
    }
    private struct Flow {
        let key: KeyPath<MetricsSnapshot, UInt64>
        let label: String
        let spoken: String
    }

    private var latest: MetricsSnapshot? { coordinator.latestSnapshot }
    private var history: [MetricsSnapshot] {
        guard let end = latest?.timestamp else { return [] }
        // 左端を通過する点も残し、グラフ更新時の途切れを防ぐ。
        return coordinator.history.suffix(65).filter { end.timeIntervalSince($0.timestamp) <= 75 }
    }

    var body: some View {
        let samples = history
        VStack(spacing: 0) {
            cpuRow
            capacityRows
            separator
            activityRow(
                Metric(title: "ネットワーク", icon: "globe", tab: .network), samples: samples,
                first: Flow(key: \.network.totalDownloadBytesPerSecond, label: "↓", spoken: "受信"),
                second: Flow(key: \.network.totalUploadBytesPerSecond, label: "↑", spoken: "送信")
            )
            separator
            activityRow(
                Metric(title: "ディスク I/O", icon: "arrow.up.arrow.down.square", tab: .storage), samples: samples,
                first: Flow(key: \.disk.readBytesPerSecond, label: "読込", spoken: "読込"),
                second: Flow(key: \.disk.writeBytesPerSecond, label: "書込", spoken: "書込")
            )
            separator
            cpuHistory(samples)
        }
        .padding(.horizontal, 9)
        .padding(.bottom, 12)
    }

    private var separator: some View {
        Rectangle().fill(.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 8)
    }

    private var cpuRow: some View {
        let cpu = latest?.cpu
        let detail = "ユーザー \(percent(cpu?.userUsage))　システム \(percent(cpu?.systemUsage))"
        return metricRow(
            Metric(title: "CPU", icon: "cpu", tab: .cpu), value: "\(percent(cpu?.totalUsage))、\(detail)", hero: true
        ) {
            CoreLoadBars(values: cpu?.perCoreUsage ?? [])
        } readout: {
            VStack(alignment: .trailing, spacing: 3) {
                number(percent(cpu?.totalUsage))
                Text(detail).font(.system(size: 9)).foregroundStyle(.secondary)
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.78)
            }
        }
    }

    private var capacityRows: some View {
        let memory = latest?.memory
        let volumes = latest?.disk.volumes ?? []
        let volume = volumes.first(where: \.isInternal) ?? volumes.first
        let storageMetric = Metric(title: "ストレージ", icon: "internaldrive", tab: .storage)
        return Group {
            metricRow(Metric(title: "メモリ", icon: "memorychip", tab: .memory), value: percent(memory?.usageRatio)) {
                CapacityMeter(ratio: memory?.usageRatio, tint: InspectorTint.aqua)
            } readout: {
                number(percent(memory?.usageRatio))
            }
            separator
            metricRow(storageMetric, value: percent(volume?.usageRatio)) {
                CapacityMeter(ratio: volume?.usageRatio, tint: InspectorTint.lavender)
            } readout: {
                number(percent(volume?.usageRatio))
            }
        }
    }

    private func activityRow(
        _ metric: Metric, samples: [MetricsSnapshot], first: Flow, second: Flow
    ) -> some View {
        let ceiling = Double(samples.map { max($0[keyPath: first.key], $0[keyPath: second.key]) }.max() ?? 0)
        let firstRate = rate(latest?[keyPath: first.key])
        let secondRate = rate(latest?[keyPath: second.key])
        return metricRow(
            metric,
            value: "\(first.spoken) \(firstRate)、\(second.spoken) \(secondRate)"
        ) {
            VStack(spacing: 3) {
                HistoryTrace(
                    samples: samples, value: { Double($0[keyPath: first.key]) }, ceiling: ceiling,
                    color: InspectorTint.aqua)
                HistoryTrace(
                    samples: samples, value: { Double($0[keyPath: second.key]) }, ceiling: ceiling,
                    color: InspectorTint.lavender)
            }
            .frame(height: 28)
        } readout: {
            VStack(alignment: .trailing, spacing: 3) {
                rateLine(first.label, firstRate)
                rateLine(second.label, secondRate)
            }
        }
    }

    private func rateLine(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 12, weight: .medium)).monospacedDigit()
        }
    }

    private func metricRow<Meter: View, Readout: View>(
        _ metric: Metric, value: String, hero: Bool = false,
        @ViewBuilder meter: () -> Meter, @ViewBuilder readout: () -> Readout
    ) -> some View {
        Button {
            onSelectTab(metric.tab)
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 9) {
                    Image(systemName: metric.icon).font(.system(size: 16)).foregroundStyle(.secondary).frame(width: 20)
                    Text(metric.title).font(.system(size: 12.5, weight: .medium))
                }
                .frame(width: 99, alignment: .leading)
                meter().frame(maxWidth: .infinity)
                readout().frame(width: 106, alignment: .trailing)
            }
            .lineLimit(1)
            .padding(.horizontal, 9)
            .frame(height: hero ? 60 : 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(InspectorRowStyle(hero: hero))
        .accessibilityLabel("\(metric.title)の詳細")
        .accessibilityValue(value)
    }

    private func cpuHistory(_ samples: [MetricsSnapshot]) -> some View {
        let peak = samples.map { max($0.cpu.userUsage, $0.cpu.systemUsage) }.max() ?? 0
        let ceiling = min(1, max(0.25, ceil(peak * 4) / 4))
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CPUの履歴").font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("直近1分 · 上限\(percent(ceiling))").font(.caption2).foregroundStyle(.secondary)
            }

            ZStack {
                HistoryTrace(
                    samples: samples, value: { $0.cpu.userUsage }, ceiling: ceiling,
                    color: InspectorTint.amber, filled: true)
                HistoryTrace(
                    samples: samples, value: { $0.cpu.systemUsage }, ceiling: ceiling,
                    color: InspectorTint.lavender, filled: true)
            }
            .frame(maxHeight: .infinity)
            .overlay {
                if samples.count < 2 {
                    Text("履歴を収集中").font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 18) {
                legend("ユーザー", value: latest?.cpu.userUsage, color: InspectorTint.amber)
                legend("システム", value: latest?.cpu.systemUsage, color: InspectorTint.lavender)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
    }

    private func legend(_ title: String, value: Double?, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).foregroundStyle(.secondary)
            Text(percent(value)).monospacedDigit()
        }
        .font(.system(size: 10, weight: .medium))
        .accessibilityElement(children: .combine)
    }

    private func number(_ value: String) -> some View {
        Text(value).font(.system(size: 19, weight: .semibold)).monospacedDigit()
    }

    private func percent(_ ratio: Double?) -> String {
        ratio.map(MetricFormatter.percentage) ?? "—"
    }

    private func rate(_ bytes: UInt64?) -> String {
        bytes.map { MetricFormatter.bytesPerSecond($0, dataUnit: preferences.dataUnit) } ?? "—"
    }
}

private struct InspectorRowStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let hero: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        configuration.label
            .background(shape.fill(.white.opacity(configuration.isPressed ? 0.16 : hovered ? 0.12 : hero ? 0.085 : 0)))
            .overlay {
                if hero {
                    shape.strokeBorder(
                        .linearGradient(
                            colors: [.white.opacity(0.16), .white.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.75)
                }
            }
            .onHover { hovered = $0 }
            .animation(PulseMotion.resolve(.easeOut(duration: 0.15), reduceMotion: reduceMotion), value: hovered)
    }
}
