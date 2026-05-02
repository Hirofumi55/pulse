//
//  PopoverHostView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// メニューバーポップオーバー全体をホストするビュー。
struct PopoverHostView: View {
    let coordinator: MetricsCoordinator
    let preferences: PreferencesStore

    @State private var selectedTab = PopoverTab.overview

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewTab(coordinator: coordinator, preferences: preferences)
                .tabItem {
                    Label("概要", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(PopoverTab.overview)
            CPUTab(coordinator: coordinator)
                .tabItem {
                    Label("CPU", systemImage: "cpu")
                }
                .tag(PopoverTab.cpu)
            MemoryTab(coordinator: coordinator, preferences: preferences)
                .tabItem {
                    Label("メモリ", systemImage: "memorychip")
                }
                .tag(PopoverTab.memory)
            StorageTab(coordinator: coordinator, preferences: preferences)
                .tabItem {
                    Label("ストレージ", systemImage: "internaldrive")
                }
                .tag(PopoverTab.storage)
            NetworkTab(coordinator: coordinator, preferences: preferences)
                .tabItem {
                    Label("ネットワーク", systemImage: "network")
                }
                .tag(PopoverTab.network)
        }
        .frame(width: 380, height: 480)
        .background {
            PulseGlassBackdrop(opacity: preferences.popoverBackgroundOpacity)
        }
        .preferredColorScheme(preferences.appearance.colorScheme)
    }
}

private enum PopoverTab: Hashable {
    case overview
    case cpu
    case memory
    case storage
    case network
}
