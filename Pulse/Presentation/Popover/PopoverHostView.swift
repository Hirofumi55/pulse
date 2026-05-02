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

    var body: some View {
        OverviewTab(coordinator: coordinator, preferences: preferences)
            .frame(width: 380, height: 480)
            .background {
                PulseGlassBackdrop(opacity: preferences.popoverBackgroundOpacity)
            }
            .preferredColorScheme(preferences.appearance.colorScheme)
    }
}
