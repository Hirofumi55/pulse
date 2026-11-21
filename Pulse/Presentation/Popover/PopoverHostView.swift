//
//  PopoverHostView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// ポップオーバー内の表示タブ。
enum PopoverTab: String, CaseIterable, Identifiable, Sendable {
    case overview
    case cpu
    case memory
    case storage
    case network

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .overview:
            "概要"
        case .cpu:
            "CPU"
        case .memory:
            "メモリ"
        case .storage:
            "ストレージ"
        case .network:
            "ネットワーク"
        }
    }
}

/// メニューバーポップオーバー全体をホストするビュー。
struct PopoverHostView: View {
    let coordinator: MetricsCoordinator

    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabNamespace

    @State private var entryOffset: CGFloat = 10
    @State private var selectedTab: PopoverTab = .overview

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            tabPickerBar
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

            ZStack(alignment: .top) { tabContent }
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            PulseGlassBackdrop(
                opacity: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius,
                tone: .clearBlack
            )
        }
        .preferredColorScheme(.dark)
    }

    static let size = CGSize(width: 420, height: 496)

    private var headerBar: some View {
        HStack(spacing: 7) {
            PulseLiveIndicator(
                isActive: coordinator.isSampling && coordinator.latestSnapshot != nil,
                pulseDate: coordinator.latestSnapshot?.timestamp
            )
            .accessibilityHidden(true)

            Text("Pulse")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Rectangle().fill(.secondary.opacity(0.40)).frame(width: 1, height: 11)
            Text(hardwareSummary)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if !coordinator.isSampling {
                Text("一時停止中")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
    }

    private var tabPickerBar: some View {
        PulseGlassContainer(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(PopoverTab.allCases) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(3)
            .pulseGlassCapsule()
        }
    }

    private func tabButton(for tab: PopoverTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectTab(tab)
        } label: {
            Text(tab.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    if isSelected {
                        selectedTabPill
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectedTabPill: some View {
        let shape = Capsule(style: .continuous)
        return
            shape
            .fill(
                .linearGradient(
                    colors: [.white.opacity(0.25), .white.opacity(0.12)],
                    startPoint: .top, endPoint: .bottom)
            )
            .overlay {
                shape.strokeBorder(.white.opacity(0.24), lineWidth: 0.5)
            }
            .matchedGeometryEffect(id: "selectedPopoverTab", in: tabNamespace)
    }

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .overview:
                OverviewTab(
                    coordinator: coordinator,
                    preferences: preferences,
                    onSelectTab: selectTab
                )
            case .cpu:
                CPUTab(coordinator: coordinator)
            case .memory:
                MemoryTab(coordinator: coordinator, preferences: preferences)
            case .storage:
                StorageTab(coordinator: coordinator, preferences: preferences)
            case .network:
                NetworkTab(coordinator: coordinator, preferences: preferences)
            }
        }
        .id(selectedTab)
        .transition(
            reduceMotion
                ? .identity
                : .asymmetric(insertion: .opacity.combined(with: .offset(x: entryOffset)), removal: .opacity)
        )
    }

    private var hardwareSummary: String {
        let coreCount = coordinator.latestSnapshot?.cpu.logicalCoreCount ?? ProcessInfo.processInfo.activeProcessorCount
        return "\(coreCount)コア"
    }

    private func selectTab(_ tab: PopoverTab) {
        guard selectedTab != tab else {
            return
        }

        withAnimation(PulseMotion.resolve(PulseMotion.snappy, reduceMotion: reduceMotion)) {
            let order = PopoverTab.allCases
            entryOffset = order.prefix(while: { $0 != tab }).contains(selectedTab) ? 10 : -10
            selectedTab = tab
        }
    }
}
