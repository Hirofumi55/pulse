//
//  UpdateSettingsView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import SwiftUI

/// サンプリングとアップデート確認を設定するビュー。
struct UpdateSettingsView: View {
    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        let isUpdateConfigured = Bundle.main.isSparkleUpdateConfigured
        let updateConfigurationStatus = Bundle.main.sparkleUpdateConfigurationStatus

        Form {
            Section("サンプリング") {
                Picker("更新頻度", selection: samplingIntervalBinding) {
                    ForEach(PreferencesStore.allowedSamplingIntervals, id: \.self) { interval in
                        Text(intervalTitle(interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("アップデート") {
                Toggle("自動的に確認", isOn: automaticUpdateBinding)
                    .disabled(!isUpdateConfigured)
                    .help(isUpdateConfigured ? "Sparkle による自動確認を切り替えます。" : updateConfigurationStatus)
                    .accessibilityHint(
                        isUpdateConfigured ? "Sparkle による自動確認を切り替えます。" : updateConfigurationStatus
                    )
                Button("今すぐ確認") {
                    NotificationCenter.default.post(name: .pulseCheckForUpdates, object: nil)
                }
                .disabled(!isUpdateConfigured)
                .help(isUpdateConfigured ? "新しいバージョンの有無を確認します。" : updateConfigurationStatus)
                .accessibilityHint(
                    isUpdateConfigured ? "新しいバージョンの有無を確認します。" : updateConfigurationStatus
                )

                if !isUpdateConfigured {
                    Text(updateConfigurationStatus)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LabeledContent("現在のバージョン", value: Bundle.main.pulseVersion)
            }
        }
        .pulseGlassForm()
    }

    private var samplingIntervalBinding: Binding<Double> {
        Binding {
            preferences.samplingIntervalSeconds
        } set: { newValue in
            preferences.samplingIntervalSeconds = newValue
        }
    }

    private var automaticUpdateBinding: Binding<Bool> {
        Binding {
            preferences.automaticallyChecksForUpdates
        } set: { newValue in
            preferences.automaticallyChecksForUpdates = newValue
        }
    }

    private func intervalTitle(_ interval: Double) -> String {
        if interval == floor(interval) {
            return "\(Int(interval))秒"
        }

        return String(format: "%.1f秒", interval)
    }
}

extension Notification.Name {
    static let pulseCheckForUpdates = Notification.Name("com.hirofumi.pulse.checkForUpdates")
}

extension Bundle {
    var pulseVersion: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String

        return switch (version, build) {
        case (.some(let version), .some(let build)):
            "\(version) (\(build))"
        case (.some(let version), .none):
            version
        case (.none, .some(let build)):
            build
        case (.none, .none):
            "不明"
        }
    }
}

#Preview {
    UpdateSettingsView()
        .environment(PreferencesStore())
}
