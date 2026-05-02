//
//  PreferencesStoreTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Testing

@testable import Pulse

@Suite("Preferences Store Tests")
@MainActor
struct PreferencesStoreTests {
    @Test("Store loads default values")
    func loadsDefaultValues() throws {
        let defaults = try makeUserDefaults()
        defer {
            defaults.cleanup()
        }

        let store = PreferencesStore(userDefaults: defaults.userDefaults)

        #expect(store.displayedItems == [.cpuUsage, .memoryUsage, .networkSpeed])
        #expect(store.samplingIntervalSeconds == 3.0)
        #expect(store.menuBarDisplayStyle == .bar)
        #expect(store.menuBarBarLayout == .horizontal)
        #expect(!store.showMenuBarBarPercentage)
        #expect(store.temperatureUnit == .celsius)
        #expect(store.dataUnit == .iec)
        #expect(store.showMenuBarIcons)
        #expect(store.automaticallyChecksForUpdates)
        #expect(store.appearance == .system)
        #expect(store.popoverBackgroundOpacity == 0.28)
    }

    @Test("Store persists changed values")
    func persistsChangedValues() throws {
        let defaults = try makeUserDefaults()
        defer {
            defaults.cleanup()
        }

        let store = PreferencesStore(userDefaults: defaults.userDefaults)

        store.displayedItems = [.diskIO, .cpuUsage, .memoryUsage]
        store.samplingIntervalSeconds = 5.0
        store.menuBarDisplayStyle = .graph
        store.menuBarBarLayout = .horizontal
        store.showMenuBarBarPercentage = false
        store.temperatureUnit = .fahrenheit
        store.dataUnit = .si
        store.showMenuBarIcons = false
        store.automaticallyChecksForUpdates = false
        store.appearance = .dark
        store.popoverBackgroundOpacity = 0.55

        let reloadedStore = PreferencesStore(userDefaults: defaults.userDefaults)

        #expect(reloadedStore.displayedItems == [.diskIO, .cpuUsage, .memoryUsage])
        #expect(reloadedStore.samplingIntervalSeconds == 5.0)
        #expect(reloadedStore.menuBarDisplayStyle == .graph)
        #expect(reloadedStore.menuBarBarLayout == .horizontal)
        #expect(!reloadedStore.showMenuBarBarPercentage)
        #expect(reloadedStore.temperatureUnit == .fahrenheit)
        #expect(reloadedStore.dataUnit == .si)
        #expect(!reloadedStore.showMenuBarIcons)
        #expect(!reloadedStore.automaticallyChecksForUpdates)
        #expect(reloadedStore.appearance == .dark)
        #expect(reloadedStore.popoverBackgroundOpacity == 0.55)
    }

    @Test("Store sanitizes displayed items and interval")
    func sanitizesDisplayedItemsAndInterval() throws {
        let defaults = try makeUserDefaults()
        defer {
            defaults.cleanup()
        }

        let store = PreferencesStore(userDefaults: defaults.userDefaults)

        store.displayedItems = [
            .diskIO,
            .gpuUsage,
            .cpuUsage,
            .diskIO,
            .memoryUsage,
            .networkSpeed,
            .diskUsage,
        ]
        store.samplingIntervalSeconds = 2.8
        store.popoverBackgroundOpacity = 2.0

        #expect(store.displayedItems == [.diskIO, .cpuUsage, .memoryUsage, .networkSpeed])
        #expect(store.samplingIntervalSeconds == 3.0)
        #expect(store.popoverBackgroundOpacity == 0.9)
    }

    @Test("Store resets values to defaults")
    func resetsValuesToDefaults() throws {
        let defaults = try makeUserDefaults()
        defer {
            defaults.cleanup()
        }

        let store = PreferencesStore(userDefaults: defaults.userDefaults)

        store.displayedItems = [.diskUsage]
        store.samplingIntervalSeconds = 5.0
        store.menuBarDisplayStyle = .text
        store.menuBarBarLayout = .horizontal
        store.showMenuBarBarPercentage = false
        store.temperatureUnit = .fahrenheit
        store.dataUnit = .si
        store.showMenuBarIcons = false
        store.automaticallyChecksForUpdates = false
        store.appearance = .light
        store.popoverBackgroundOpacity = 0.8

        store.resetToDefaults()

        #expect(store.displayedItems == [.cpuUsage, .memoryUsage, .networkSpeed])
        #expect(store.samplingIntervalSeconds == 3.0)
        #expect(store.menuBarDisplayStyle == .bar)
        #expect(store.menuBarBarLayout == .horizontal)
        #expect(!store.showMenuBarBarPercentage)
        #expect(store.temperatureUnit == .celsius)
        #expect(store.dataUnit == .iec)
        #expect(store.showMenuBarIcons)
        #expect(store.automaticallyChecksForUpdates)
        #expect(store.appearance == .system)
        #expect(store.popoverBackgroundOpacity == 0.28)
    }

    private func makeUserDefaults() throws -> TestUserDefaults {
        let suiteName = "com.hirofumi.pulse.tests.preferences.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return TestUserDefaults(suiteName: suiteName, userDefaults: userDefaults)
    }
}

private struct TestUserDefaults {
    let suiteName: String
    let userDefaults: UserDefaults

    func cleanup() {
        userDefaults.removePersistentDomain(forName: suiteName)
    }
}
