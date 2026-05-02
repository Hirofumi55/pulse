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
        logger.debug("Sparkle manual update check started")
        updaterController?.checkForUpdates(nil)
    }
}
