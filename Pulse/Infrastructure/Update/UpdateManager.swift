//
//  UpdateManager.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Sparkle
import os

private let logger = Logger(category: .update)

/// Sparkle によるアップデート確認を管理する。
@MainActor
final class UpdateManager {
    private let preferences: PreferencesStore
    private var updaterController: SPUStandardUpdaterController?

    /// UpdateManager を作成する。
    init(preferences: PreferencesStore) {
        self.preferences = preferences
    }

    /// Sparkle updater を開始する。
    func start() {
        guard Bundle.main.isSparkleUpdateConfigured else {
            logger.warning(
                "Sparkle updater disabled: \(Bundle.main.sparkleUpdateConfigurationStatus, privacy: .public)"
            )
            return
        }

        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = updaterController
        applyPreferences()
        logger.debug("Sparkle updater started")
    }

    /// UserDefaults 側の更新設定を Sparkle に反映する。
    func applyPreferences() {
        guard Bundle.main.isSparkleUpdateConfigured else {
            return
        }

        updaterController?.updater.automaticallyChecksForUpdates =
            preferences.automaticallyChecksForUpdates
        logger.debug(
            """
            Automatic update checks changed: \
            \(self.preferences.automaticallyChecksForUpdates, privacy: .public)
            """
        )
    }

    /// アップデートを手動確認する。
    func checkForUpdates() {
        guard Bundle.main.isSparkleUpdateConfigured else {
            logger.warning(
                "Sparkle manual update check skipped: \(Bundle.main.sparkleUpdateConfigurationStatus, privacy: .public)"
            )
            return
        }

        logger.debug("Sparkle manual update check started")
        updaterController?.checkForUpdates(nil)
    }
}

extension Bundle {
    /// Sparkle の更新設定が実際に使える状態かどうか。
    var isSparkleUpdateConfigured: Bool {
        sparkleUpdateConfigurationIssue == nil
    }

    /// Sparkle の更新設定状態を説明する文言。
    var sparkleUpdateConfigurationStatus: String {
        sparkleUpdateConfigurationIssue ?? "アップデート確認を利用できます"
    }

    private var sparkleUpdateConfigurationIssue: String? {
        guard
            let publicKey = object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
            !publicKey.isEmpty,
            publicKey != "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        else {
            return "Sparkle公開鍵が未設定のため、アップデート確認は無効です。"
        }

        guard
            let feedURLString = object(forInfoDictionaryKey: "SUFeedURL") as? String,
            let feedURL = URL(string: feedURLString),
            feedURL.scheme == "https"
        else {
            return "アップデート確認URLがHTTPSで設定されていません。"
        }

        return nil
    }
}
