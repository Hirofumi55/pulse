//
//  AppDelegate.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Observation
import SwiftUI
import os

private let logger = Logger(category: .app)

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = MetricsCoordinator()
    private let preferences = PreferencesStore.shared
    private let updateManager = UpdateManager(preferences: PreferencesStore.shared)
    private var menuBarController: MenuBarController?
    private var settingsWindowController: NSWindowController?

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

        let menuBarController = MenuBarController(
            coordinator: coordinator,
            preferences: preferences,
            openSettingsHandler: { [weak self] in
                self?.showSettingsWindow()
            }
        )
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

    private func showSettingsWindow() {
        let windowController: NSWindowController
        if let settingsWindowController {
            windowController = settingsWindowController
        } else {
            let newWindowController = makeSettingsWindowController()
            settingsWindowController = newWindowController
            windowController = newWindowController
        }

        NSApp.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        logger.debug("Settings window opened")
    }

    private func makeSettingsWindowController() -> NSWindowController {
        let hostingController = NSHostingController(
            rootView: SettingsView()
                .environment(preferences)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pulse 設定"
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 560, height: 460)
        window.center()
        window.isReleasedWhenClosed = false

        return NSWindowController(window: window)
    }
}
