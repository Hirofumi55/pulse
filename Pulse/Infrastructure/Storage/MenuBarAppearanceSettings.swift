//
//  MenuBarAppearanceSettings.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation

/// メニューバーに表示するメトリクスの表現方法。
enum MenuBarDisplayStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    /// バーで表示する。
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

/// メニューバーのバー表示レイアウト。
enum MenuBarBarLayout: String, CaseIterable, Codable, Identifiable, Sendable {
    /// 縦方向のバー。
    case vertical

    /// 横方向のバー。
    case horizontal

    /// 識別子。
    var id: String {
        rawValue
    }

    /// UI に表示する日本語名。
    var displayName: String {
        switch self {
        case .vertical:
            "縦バー"
        case .horizontal:
            "横バー"
        }
    }
}
