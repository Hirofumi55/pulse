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
    private var statusItemContentIdentifier: String?
    private var displayedItems: [DisplayItem] = []
    private var popover: NSPopover?
    private var popoverEventMonitors: [Any] = []
    private var popoverResignObserver: NSObjectProtocol?
    private var lastStatusItemRenderDate: Date?
    private var isPaused = false

    private let coordinator: MetricsCoordinator
    private let preferences: PreferencesStore
    private let openSettingsHandler: @MainActor () -> Void

    init(
        coordinator: MetricsCoordinator,
        preferences: PreferencesStore,
        openSettingsHandler: @escaping @MainActor () -> Void = {}
    ) {
        self.coordinator = coordinator
        self.preferences = preferences
        self.openSettingsHandler = openSettingsHandler
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
        removePopoverDismissObservers()
        removeStatusItems()
        coordinator.stop()
    }

    private func observePreferences() {
        withObservationTracking {
            _ = preferences.displayedItems
            _ = preferences.showMenuBarIcons
            _ = preferences.dataUnit
            _ = preferences.samplingIntervalSeconds
            _ = preferences.menuBarDisplayStyle
            _ = preferences.menuBarBarLayout
            _ = preferences.showMenuBarBarPercentage
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
            _ = coordinator.history
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleMetricsChanged()
                self?.observeMetrics()
            }
        }
    }

    private func handleMetricsChanged() {
        guard shouldRenderStatusItemForLatestSnapshot() else {
            return
        }

        updateStatusItemContent()
    }

    private func handlePreferencesChanged() {
        let nextDisplayedItems = filteredDisplayedItems()
        if displayedItems != nextDisplayedItems {
            displayedItems = nextDisplayedItems
            updateStatusItemLength()
            statusItemContentIdentifier = nil
            updateStatusItemContent(force: true)
            logger.debug(
                "Menu bar status item updated: \(self.displayedItems.count, privacy: .public)"
            )
        } else {
            updateStatusItemLength()
            updateStatusItemContent(force: true)
        }

        applyActiveSamplingInterval()
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
                style: preferences.menuBarDisplayStyle,
                options: renderOptions
            )
        )
        statusItem.button?.action = #selector(handleClick(_:))
        statusItem.button?.target = self
        statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.toolTip = "Pulse"
        statusItem.button?.setAccessibilityLabel("Pulse システムモニター")
        self.statusItem = statusItem

        updateStatusItemContent(force: true)
    }

    private func removeStatusItems() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        statusItemContentIdentifier = nil
    }

    private func updateStatusItemContent(force: Bool = false) {
        guard let statusItem else {
            return
        }

        let title = MenuBarRenderer.title(
            for: displayedItems,
            snapshot: coordinator.latestSnapshot,
            showIcon: preferences.showMenuBarIcons,
            dataUnit: preferences.dataUnit
        )
        let timestamp = coordinator.latestSnapshot?.timestamp.timeIntervalSinceReferenceDate ?? 0
        let identifier = [
            preferences.menuBarDisplayStyle.rawValue,
            preferences.menuBarBarLayout.rawValue,
            String(preferences.showMenuBarBarPercentage),
            title,
            String(timestamp),
        ].joined(separator: "|")
        guard force || statusItemContentIdentifier != identifier else {
            return
        }

        statusItemContentIdentifier = identifier
        lastStatusItemRenderDate = coordinator.latestSnapshot?.timestamp
        switch preferences.menuBarDisplayStyle {
        case .text:
            statusItem.button?.image = nil
            statusItem.button?.imagePosition = .noImage
            statusItem.button?.title = title
        case .bar, .graph:
            statusItem.button?.title = ""
            statusItem.button?.imagePosition = .imageOnly
            statusItem.button?.imageScaling = .scaleNone
            statusItem.button?.image = MenuBarRenderer.image(
                for: displayedItems,
                snapshot: coordinator.latestSnapshot,
                history: coordinator.history,
                style: preferences.menuBarDisplayStyle,
                options: renderOptions
            )
        }
    }

    private func shouldRenderStatusItemForLatestSnapshot() -> Bool {
        guard statusItemContentIdentifier != nil else {
            return true
        }

        guard let snapshotDate = coordinator.latestSnapshot?.timestamp else {
            return true
        }

        guard let lastStatusItemRenderDate else {
            return true
        }

        let elapsedSeconds = snapshotDate.timeIntervalSince(lastStatusItemRenderDate)
        return elapsedSeconds >= preferences.samplingIntervalSeconds - 0.05
    }

    private func updateStatusItemLength() {
        statusItem?.length = MenuBarRenderer.preferredLength(
            for: displayedItems,
            style: preferences.menuBarDisplayStyle,
            options: renderOptions
        )
    }

    private var renderOptions: MenuBarRenderOptions {
        MenuBarRenderOptions(
            showIcon: preferences.showMenuBarIcons,
            barLayout: preferences.menuBarBarLayout,
            showBarPercentage: preferences.showMenuBarBarPercentage
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
        popover.delegate = self
        popover.contentSize = NSSize(width: 420, height: 650)
        let hostingController = NSHostingController(
            rootView: PopoverHostView(coordinator: coordinator)
                .environment(preferences)
        )
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        popover.contentViewController = hostingController
        self.popover = popover
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        configurePopoverWindow(for: popover)
        installPopoverDismissObservers()
        applyActiveSamplingInterval()
        logger.debug("Popover opened")
    }

    private func configurePopoverWindow(for popover: NSPopover) {
        guard let window = popover.contentViewController?.view.window else {
            return
        }

        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func installPopoverDismissObservers() {
        removePopoverDismissObservers()

        let dismissEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: dismissEvents) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopoverFromFocusOut()
            }
        }
        if let globalMonitor {
            popoverEventMonitors.append(globalMonitor)
        }

        popoverResignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopoverFromFocusOut()
            }
        }
    }

    private func removePopoverDismissObservers() {
        for monitor in popoverEventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        popoverEventMonitors.removeAll()

        if let popoverResignObserver {
            NotificationCenter.default.removeObserver(popoverResignObserver)
            self.popoverResignObserver = nil
        }
    }

    private func closePopoverFromFocusOut() {
        guard let popover, popover.isShown else {
            return
        }

        popover.close()
    }

    private func applyActiveSamplingInterval() {
        guard !isPaused else {
            return
        }

        coordinator.updateInterval(popover?.isShown == true ? .seconds(1) : preferences.samplingDuration)
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
        openSettingsHandler()
    }

    @objc private func togglePause() {
        isPaused.toggle()

        if isPaused {
            coordinator.stop()
            logger.debug("Sampling paused from menu bar")
        } else {
            coordinator.start(interval: popover?.isShown == true ? .seconds(1) : preferences.samplingDuration)
            logger.debug("Sampling resumed from menu bar")
        }
    }

    @objc private func quit() {
        logger.debug("Quit requested from menu bar")
        NSApp.terminate(nil)
    }
}

extension MenuBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        guard
            let closedPopover = notification.object as? NSPopover,
            closedPopover === popover
        else {
            return
        }

        closedPopover.delegate = nil
        popover = nil
        removePopoverDismissObservers()
        applyActiveSamplingInterval()
        logger.debug("Popover closed")
    }
}
