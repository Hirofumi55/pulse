//
//  AppDelegate.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Observation
import os

private let logger = Logger(category: .app)

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = MetricsCoordinator()
    private let preferences = PreferencesStore.shared
    private let updateManager = UpdateManager(preferences: PreferencesStore.shared)
    private var menuBarController: MenuBarController?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        updateManager.start()
        observeUpdatePreferences()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkForUpdates),
            name: .pulseCheckForUpdates,
            object: nil
        )
        coordinator.start(interval: preferences.samplingDuration)

        let menuBarController = MenuBarController(coordinator: coordinator, preferences: preferences)
        menuBarController.setup()
        self.menuBarController = menuBarController
        logger.debug("Pulse launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.debug("Pulse will terminate")
        menuBarController?.cleanup()
    }

    private func observeUpdatePreferences() {
        withObservationTracking {
            _ = preferences.automaticallyChecksForUpdates
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateManager.applyPreferences()
                self?.observeUpdatePreferences()
            }
        }
    }

    @objc private func checkForUpdates() {
        logger.debug("Manual update check requested")
        updateManager.checkForUpdates()
    }
}
