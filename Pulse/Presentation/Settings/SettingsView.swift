//
//  SettingsView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// アプリ設定画面のルートビュー。
struct SettingsView: View {
    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("一般", systemImage: "gearshape")
                }
            DisplaySettingsView()
                .tabItem {
                    Label("表示", systemImage: "menubar.rectangle")
                }
            UpdateSettingsView()
                .tabItem {
                    Label("更新", systemImage: "arrow.triangle.2.circlepath")
                }
            UnitSettingsView()
                .tabItem {
                    Label("単位", systemImage: "ruler")
                }
            AboutView()
                .tabItem {
                    Label("情報", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 420)
        .preferredColorScheme(preferences.appearance.colorScheme)
    }
}

#Preview {
    SettingsView()
        .environment(PreferencesStore())
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
