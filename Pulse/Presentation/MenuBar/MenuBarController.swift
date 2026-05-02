//
//  MenuBarController.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import Observation
import SwiftUI
import os

private let logger = Logger(category: .menuBar)

/// NSStatusItem を設定とメトリクスに応じて管理する。
@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var statusItemTitle: String?
    private var displayedItems: [DisplayItem] = []
    private var popover: NSPopover?
    private var isPaused = false

    private let coordinator: MetricsCoordinator
    private let preferences: PreferencesStore

    init(coordinator: MetricsCoordinator, preferences: PreferencesStore) {
        self.coordinator = coordinator
        self.preferences = preferences
    }

    /// メニューバー項目を構築し、設定とメトリクスの監視を開始する。
    func setup() {
        displayedItems = filteredDisplayedItems()
        rebuildStatusItems()
        observePreferences()
        observeMetrics()
        logger.debug("Menu bar controller setup completed")
    }

    /// アプリ終了時に NSStatusItem を破棄する。
    func cleanup() {
        logger.debug("Menu bar controller cleanup started")
        popover?.close()
        removeStatusItems()
        coordinator.stop()
    }

    private func observePreferences() {
        withObservationTracking {
            _ = preferences.displayedItems
            _ = preferences.showMenuBarIcons
            _ = preferences.dataUnit
            _ = preferences.samplingIntervalSeconds
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.handlePreferencesChanged()
                self?.observePreferences()
            }
        }
    }

    private func observeMetrics() {
        withObservationTracking {
            _ = coordinator.latestSnapshot
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateStatusItemTitle()
                self?.observeMetrics()
            }
        }
    }

    private func handlePreferencesChanged() {
        let nextDisplayedItems = filteredDisplayedItems()
        if displayedItems != nextDisplayedItems {
            displayedItems = nextDisplayedItems
            updateStatusItemLength()
            statusItemTitle = nil
            updateStatusItemTitle()
            logger.debug(
                "Menu bar status item updated: \(self.displayedItems.count, privacy: .public)"
            )
        } else {
            updateStatusItemLength()
            updateStatusItemTitle()
        }

        if !isPaused {
            coordinator.updateInterval(preferences.samplingDuration)
        }
    }

    private func filteredDisplayedItems() -> [DisplayItem] {
        preferences.displayedItems.filter { item in
            item.isAvailableInPhase1
        }
    }

    private func rebuildStatusItems() {
        removeStatusItems()

        let statusItem = NSStatusBar.system.statusItem(
            withLength: MenuBarRenderer.preferredLength(
                for: displayedItems,
                showIcon: preferences.showMenuBarIcons
            )
        )
        statusItem.button?.action = #selector(handleClick(_:))
        statusItem.button?.target = self
        statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.toolTip = "Pulse"
        statusItem.button?.setAccessibilityLabel("Pulse システムモニター")
        self.statusItem = statusItem

        updateStatusItemTitle()
    }

    private func removeStatusItems() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        statusItemTitle = nil
    }

    private func updateStatusItemTitle() {
        guard let statusItem else {
            return
        }

        let title = MenuBarRenderer.title(
            for: displayedItems,
            snapshot: coordinator.latestSnapshot,
            showIcon: preferences.showMenuBarIcons,
            dataUnit: preferences.dataUnit
        )
        guard statusItemTitle != title else {
            return
        }

        statusItemTitle = title
        statusItem.button?.title = title
    }

    private func updateStatusItemLength() {
        statusItem?.length = MenuBarRenderer.preferredLength(
            for: displayedItems,
            showIcon: preferences.showMenuBarIcons
        )
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(for: sender)
        } else {
            togglePopover(for: sender)
        }
    }

    private func togglePopover(for sender: NSStatusBarButton) {
        if let popover, popover.isShown {
            popover.close()
            logger.debug("Popover closed")
            return
        }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.contentViewController = NSHostingController(
            rootView: PopoverHostView(coordinator: coordinator, preferences: preferences)
        )
        self.popover = popover
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        logger.debug("Popover opened")
    }

    private func showContextMenu(for sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: isPaused ? "再開" : "一時停止", action: #selector(togglePause), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func togglePause() {
        isPaused.toggle()

        if isPaused {
            coordinator.stop()
            logger.debug("Sampling paused from menu bar")
        } else {
            coordinator.start(interval: preferences.samplingDuration)
            logger.debug("Sampling resumed from menu bar")
        }
    }

    @objc private func quit() {
        logger.debug("Quit requested from menu bar")
        NSApp.terminate(nil)
    }
}
