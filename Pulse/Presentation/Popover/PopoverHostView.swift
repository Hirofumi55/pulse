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

    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        OverviewTab(coordinator: coordinator, preferences: preferences)
            .frame(width: 420, height: 650)
            .background {
                PulseGlassBackdrop(
                    opacity: preferences.popoverBackgroundOpacity,
                    blurRadius: preferences.popoverBackgroundBlurRadius,
                    tone: .clearBlack
                )
            }
            .overlay(alignment: .topLeading) {
                if !coordinator.isSampling {
                    Text("一時停止中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 4)
                }
            }
            .preferredColorScheme(preferences.appearance.colorScheme)
    }
}
