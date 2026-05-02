//
//  GeneralSettingsView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 一般設定を表示するビュー。
struct GeneralSettingsView: View {
    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pulse")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Apple Silicon のための、モダンなメニューバー型システムモニター")
                        .foregroundStyle(.secondary)
                }
            }

            Section("ログイン時に開く") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("システム設定 → 一般 → ログイン項目 から Pulse を追加してください。")
                    Text("/Applications/Pulse.app")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Section("設定") {
                Button("設定をリセット") {
                    preferences.resetToDefaults()
                }
            }
        }
        .pulseGlassForm()
    }
}

#Preview {
    GeneralSettingsView()
        .environment(PreferencesStore())
}
