//
//  Logger+Pulse.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
import os

/// Pulse のログカテゴリ。
enum LogCategory: String, Sendable {
    case app = "App"
    case sampler = "Sampler"
    case menuBar = "MenuBar"
    case ui = "UI"
    case update = "Update"
    case storage = "Storage"
}

extension Logger {
    /// Pulse 共通 subsystem を使う Logger を作成する。
    init(category: LogCategory) {
        self.init(subsystem: "com.hirofumi.pulse", category: category.rawValue)
    }
}
