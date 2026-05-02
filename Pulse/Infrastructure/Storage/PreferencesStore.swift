//
//  PreferencesStore.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import Observation

/// 温度表示の単位。
enum TemperatureUnit: String, CaseIterable, Codable, Identifiable, Sendable {
    /// セルシウス。
    case celsius

    /// 華氏。
    case fahrenheit

    /// 識別子。
    var id: String {
        rawValue
    }

    /// UI に表示する日本語名。
    var displayName: String {
        switch self {
        case .celsius:
            "摂氏"
        case .fahrenheit:
            "華氏"
        }
    }
}

/// データ量表示の単位系。
enum DataUnit: String, CaseIterable, Codable, Identifiable, Sendable {
    /// SI 単位系(1000)。
    case si

    /// IEC 単位系(1024)。
    case iec

    /// 識別子。
    var id: String {
        rawValue
    }

    /// UI に表示する日本語名。
    var displayName: String {
        switch self {
        case .si:
            "SI"
        case .iec:
            "IEC"
        }
    }
}

/// メニューバーに表示するメトリクスの表現方法。
enum MenuBarDisplayStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    /// 横バーで表示する。
    case bar

    /// 小さな時系列グラフで表示する。
    case graph

    /// 従来の数値テキストで表示する。
    case text

    /// 識別子。
    var id: String {
        rawValue
    }

    /// UI に表示する日本語名。
    var displayName: String {
        switch self {
        case .bar:
            "バー"
        case .graph:
            "グラフ"
        case .text:
            "数値"
        }
    }
}

/// アプリの外観モード。
enum AppearanceMode: String, CaseIterable, Codable, Identifiable, Sendable {
    /// システム設定に追従する。
    case system

    /// ライトモード。
    case light

    /// ダークモード。
    case dark

    /// 識別子。
    var id: String {
        rawValue
    }

    /// UI に表示する日本語名。
    var displayName: String {
        switch self {
        case .system:
            "自動"
        case .light:
            "ライト"
        case .dark:
            "ダーク"
        }
    }
}

/// UserDefaults をバックエンドにしたアプリ設定ストア。
@Observable
@MainActor
final class PreferencesStore {
    /// アプリ全体で共有する設定ストア。
    static let shared = PreferencesStore()

    @ObservationIgnored private static let defaultDisplayedItems: [DisplayItem] = [
        .cpuUsage,
        .memoryUsage,
        .networkSpeed,
    ]

    @ObservationIgnored static let allowedSamplingIntervals = [1.0, 3.0, 5.0, 10.0]
    @ObservationIgnored private static let maximumDisplayedItemCount = 4

    @ObservationIgnored private let userDefaults: UserDefaults

    private var displayedItemsStorage: [DisplayItem]
    private var samplingIntervalSecondsStorage: Double
    private var menuBarDisplayStyleStorage: MenuBarDisplayStyle
    private var temperatureUnitStorage: TemperatureUnit
    private var dataUnitStorage: DataUnit
    private var showMenuBarIconsStorage: Bool
    private var automaticallyChecksForUpdatesStorage: Bool
    private var appearanceStorage: AppearanceMode
    private var popoverBackgroundOpacityStorage: Double

    /// メニューバーに表示する項目。順序付きで最大4件。
    var displayedItems: [DisplayItem] {
        get {
            displayedItemsStorage
        }
        set {
            let sanitizedItems = Self.sanitizeDisplayedItems(newValue)
            guard displayedItemsStorage != sanitizedItems else {
                return
            }

            displayedItemsStorage = sanitizedItems
            userDefaults.set(sanitizedItems.map(\.rawValue), forKey: Key.displayedItems)
        }
    }

    /// サンプリング間隔(秒)。
    var samplingIntervalSeconds: Double {
        get {
            samplingIntervalSecondsStorage
        }
        set {
            let sanitizedInterval = Self.sanitizeSamplingInterval(newValue)
            guard samplingIntervalSecondsStorage != sanitizedInterval else {
                return
            }

            samplingIntervalSecondsStorage = sanitizedInterval
            userDefaults.set(sanitizedInterval, forKey: Key.samplingIntervalSeconds)
        }
    }

    /// サンプリング間隔を Duration として返す。
    var samplingDuration: Duration {
        .milliseconds(Int(samplingIntervalSeconds * 1000))
    }

    /// メニューバー表示の表現方法。
    var menuBarDisplayStyle: MenuBarDisplayStyle {
        get {
            menuBarDisplayStyleStorage
        }
        set {
            guard menuBarDisplayStyleStorage != newValue else {
                return
            }

            menuBarDisplayStyleStorage = newValue
            userDefaults.set(newValue.rawValue, forKey: Key.menuBarDisplayStyle)
        }
    }

    /// 温度単位。
    var temperatureUnit: TemperatureUnit {
        get {
            temperatureUnitStorage
        }
        set {
            guard temperatureUnitStorage != newValue else {
                return
            }

            temperatureUnitStorage = newValue
            userDefaults.set(newValue.rawValue, forKey: Key.temperatureUnit)
        }
    }

    /// データ単位。
    var dataUnit: DataUnit {
        get {
            dataUnitStorage
        }
        set {
            guard dataUnitStorage != newValue else {
                return
            }

            dataUnitStorage = newValue
            userDefaults.set(newValue.rawValue, forKey: Key.dataUnit)
        }
    }

    /// メニューバーアイコンを表示するかどうか。
    var showMenuBarIcons: Bool {
        get {
            showMenuBarIconsStorage
        }
        set {
            guard showMenuBarIconsStorage != newValue else {
                return
            }

            showMenuBarIconsStorage = newValue
            userDefaults.set(newValue, forKey: Key.showMenuBarIcons)
        }
    }

    /// Sparkle による自動アップデート確認を有効にするかどうか。
    var automaticallyChecksForUpdates: Bool {
        get {
            automaticallyChecksForUpdatesStorage
        }
        set {
            guard automaticallyChecksForUpdatesStorage != newValue else {
                return
            }

            automaticallyChecksForUpdatesStorage = newValue
            userDefaults.set(newValue, forKey: Key.automaticallyChecksForUpdates)
        }
    }

    /// 現在のテーマ。
    var appearance: AppearanceMode {
        get {
            appearanceStorage
        }
        set {
            guard appearanceStorage != newValue else {
                return
            }

            appearanceStorage = newValue
            userDefaults.set(newValue.rawValue, forKey: Key.appearance)
        }
    }

    /// 詳細ポップオーバー背景の不透明度。
    var popoverBackgroundOpacity: Double {
        get {
            popoverBackgroundOpacityStorage
        }
        set {
            let sanitizedOpacity = Self.sanitizePopoverBackgroundOpacity(newValue)
            guard popoverBackgroundOpacityStorage != sanitizedOpacity else {
                return
            }

            popoverBackgroundOpacityStorage = sanitizedOpacity
            userDefaults.set(sanitizedOpacity, forKey: Key.popoverBackgroundOpacity)
        }
    }

    /// 設定ストアを作成する。
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.displayedItemsStorage = Self.loadDisplayedItems(from: userDefaults)
        self.samplingIntervalSecondsStorage = Self.sanitizeSamplingInterval(
            userDefaults.object(forKey: Key.samplingIntervalSeconds) as? Double ?? 3.0
        )
        self.menuBarDisplayStyleStorage = Self.loadEnum(
            MenuBarDisplayStyle.self,
            forKey: Key.menuBarDisplayStyle,
            from: userDefaults,
            fallback: .bar
        )
        self.temperatureUnitStorage = Self.loadEnum(
            TemperatureUnit.self,
            forKey: Key.temperatureUnit,
            from: userDefaults,
            fallback: .celsius
        )
        self.dataUnitStorage = Self.loadEnum(
            DataUnit.self,
            forKey: Key.dataUnit,
            from: userDefaults,
            fallback: .iec
        )
        self.showMenuBarIconsStorage = Self.loadBool(
            forKey: Key.showMenuBarIcons,
            from: userDefaults,
            fallback: true
        )
        self.automaticallyChecksForUpdatesStorage = Self.loadBool(
            forKey: Key.automaticallyChecksForUpdates,
            from: userDefaults,
            fallback: true
        )
        self.appearanceStorage = Self.loadEnum(
            AppearanceMode.self,
            forKey: Key.appearance,
            from: userDefaults,
            fallback: .system
        )
        self.popoverBackgroundOpacityStorage = Self.sanitizePopoverBackgroundOpacity(
            userDefaults.object(forKey: Key.popoverBackgroundOpacity) as? Double ?? 0.28
        )
    }

    /// すべての設定をデフォルト値に戻す。
    func resetToDefaults() {
        displayedItems = Self.defaultDisplayedItems
        samplingIntervalSeconds = 3.0
        menuBarDisplayStyle = .bar
        temperatureUnit = .celsius
        dataUnit = .iec
        showMenuBarIcons = true
        automaticallyChecksForUpdates = true
        appearance = .system
        popoverBackgroundOpacity = 0.28
    }

    private static func loadDisplayedItems(from userDefaults: UserDefaults) -> [DisplayItem] {
        let rawValues = userDefaults.stringArray(forKey: Key.displayedItems) ?? []
        let items = rawValues.compactMap(DisplayItem.init(rawValue:))
        return sanitizeDisplayedItems(items)
    }

    private static func loadEnum<Value>(
        _ type: Value.Type,
        forKey key: String,
        from userDefaults: UserDefaults,
        fallback: Value
    ) -> Value where Value: RawRepresentable, Value.RawValue == String {
        guard
            let rawValue = userDefaults.string(forKey: key),
            let value = type.init(rawValue: rawValue)
        else {
            return fallback
        }

        return value
    }

    private static func loadBool(
        forKey key: String,
        from userDefaults: UserDefaults,
        fallback: Bool
    ) -> Bool {
        guard userDefaults.object(forKey: key) != nil else {
            return fallback
        }

        return userDefaults.bool(forKey: key)
    }

    private static func sanitizeDisplayedItems(_ items: [DisplayItem]) -> [DisplayItem] {
        var seenItems = Set<DisplayItem>()
        let sanitizedItems = items.reduce(into: [DisplayItem]()) { result, item in
            guard
                item.isAvailableInPhase1,
                !seenItems.contains(item),
                result.count < maximumDisplayedItemCount
            else {
                return
            }

            seenItems.insert(item)
            result.append(item)
        }

        if sanitizedItems.isEmpty {
            return defaultDisplayedItems
        }

        return sanitizedItems
    }

    private static func sanitizeSamplingInterval(_ value: Double) -> Double {
        allowedSamplingIntervals.min { left, right in
            abs(left - value) < abs(right - value)
        } ?? 3.0
    }

    private static func sanitizePopoverBackgroundOpacity(_ value: Double) -> Double {
        Swift.min(Swift.max(value, 0.08), 0.9)
    }
}

private enum Key {
    static let displayedItems = "displayedItems"
    static let samplingIntervalSeconds = "samplingIntervalSeconds"
    static let menuBarDisplayStyle = "menuBarDisplayStyle"
    static let temperatureUnit = "temperatureUnit"
    static let dataUnit = "dataUnit"
    static let showMenuBarIcons = "showMenuBarIcons"
    static let automaticallyChecksForUpdates = "automaticallyChecksForUpdates"
    static let appearance = "appearance"
    static let popoverBackgroundOpacity = "popoverBackgroundOpacity"
}
