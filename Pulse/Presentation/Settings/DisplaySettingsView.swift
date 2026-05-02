//
//  DisplaySettingsView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import SwiftUI

/// メニューバー表示項目を設定するビュー。
struct DisplaySettingsView: View {
    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        Form {
            Section("表示項目") {
                ForEach(DisplayItem.allCases) { item in
                    Toggle(isOn: displayBinding(for: item)) {
                        HStack {
                            Text(item.displayName)
                            if !item.isAvailableInPhase1 {
                                Text("次フェーズ")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isDisabled(item))
                }
            }

            Section("順序") {
                VStack(spacing: 6) {
                    ForEach(Array(preferences.displayedItems.enumerated()), id: \.element.id) { entry in
                        orderRow(item: entry.element, index: entry.offset)
                    }
                }
            }

            Section("メニューバー") {
                Picker("表示形式", selection: menuBarStyleBinding) {
                    ForEach(MenuBarDisplayStyle.allCases) { style in
                        Text(style.displayName)
                            .tag(style)
                    }
                }
                .pickerStyle(.segmented)

                if preferences.menuBarDisplayStyle == .bar {
                    Picker("バー方向", selection: menuBarBarLayoutBinding) {
                        ForEach(MenuBarBarLayout.allCases) { layout in
                            Text(layout.displayName)
                                .tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("バー内にパーセントを表示", isOn: barPercentageBinding)
                }

                Picker("更新頻度", selection: samplingIntervalBinding) {
                    ForEach(PreferencesStore.allowedSamplingIntervals, id: \.self) { interval in
                        Text(intervalTitle(interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("アイコンを表示", isOn: iconBinding)
            }

            Section("詳細ポップオーバー") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("背景の濃さ")
                        Spacer()
                        Text("\(Int((preferences.popoverBackgroundOpacity * 100).rounded()))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: popoverOpacityBinding, in: 0.08...0.9, step: 0.01)

                    popoverOpacityPreview
                }
            }
        }
        .pulseGlassForm()
    }

    private var iconBinding: Binding<Bool> {
        Binding {
            preferences.showMenuBarIcons
        } set: { newValue in
            preferences.showMenuBarIcons = newValue
        }
    }

    private var menuBarStyleBinding: Binding<MenuBarDisplayStyle> {
        Binding {
            preferences.menuBarDisplayStyle
        } set: { newValue in
            preferences.menuBarDisplayStyle = newValue
        }
    }

    private var samplingIntervalBinding: Binding<Double> {
        Binding {
            preferences.samplingIntervalSeconds
        } set: { newValue in
            preferences.samplingIntervalSeconds = newValue
        }
    }

    private var menuBarBarLayoutBinding: Binding<MenuBarBarLayout> {
        Binding {
            preferences.menuBarBarLayout
        } set: { newValue in
            preferences.menuBarBarLayout = newValue
        }
    }

    private var barPercentageBinding: Binding<Bool> {
        Binding {
            preferences.showMenuBarBarPercentage
        } set: { newValue in
            preferences.showMenuBarBarPercentage = newValue
        }
    }

    private var popoverOpacityBinding: Binding<Double> {
        Binding {
            preferences.popoverBackgroundOpacity
        } set: { newValue in
            preferences.popoverBackgroundOpacity = newValue
        }
    }

    private var popoverOpacityPreview: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.35), .purple.opacity(0.3), .cyan.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor).opacity(preferences.popoverBackgroundOpacity))
                .overlay {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .symbolRenderingMode(.hierarchical)
                        Text("背景越しに内容が自然に透けます")
                            .lineLimit(1)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .padding(8)
        }
        .frame(height: 54)
        .pulseGlassPanel(tint: .cyan, materialOpacity: 0.48)
    }

    private func intervalTitle(_ interval: Double) -> String {
        if interval == floor(interval) {
            return "\(Int(interval))秒"
        }

        return String(format: "%.1f秒", interval)
    }

    private func displayBinding(for item: DisplayItem) -> Binding<Bool> {
        Binding {
            preferences.displayedItems.contains(item)
        } set: { isSelected in
            updateDisplayedItems(item: item, isSelected: isSelected)
        }
    }

    private func updateDisplayedItems(item: DisplayItem, isSelected: Bool) {
        var items = preferences.displayedItems

        if isSelected {
            guard !items.contains(item), items.count < 4, item.isAvailableInPhase1 else {
                return
            }
            items.append(item)
        } else {
            guard items.count > 1 else {
                return
            }
            items.removeAll { currentItem in
                currentItem == item
            }
        }

        preferences.displayedItems = items
    }

    private func orderRow(item: DisplayItem, index: Int) -> some View {
        HStack {
            Text(item.displayName)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Button {
                moveItem(from: index, offset: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(index == 0)
            .help("上へ")

            Button {
                moveItem(from: index, offset: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(index == preferences.displayedItems.count - 1)
            .help("下へ")
        }
    }

    private func moveItem(from index: Int, offset: Int) {
        let destination = index + offset
        guard
            preferences.displayedItems.indices.contains(index),
            preferences.displayedItems.indices.contains(destination)
        else {
            return
        }

        var items = preferences.displayedItems
        let item = items.remove(at: index)
        items.insert(item, at: destination)
        preferences.displayedItems = items
    }

    private func isDisabled(_ item: DisplayItem) -> Bool {
        if !item.isAvailableInPhase1 {
            return true
        }

        return !preferences.displayedItems.contains(item) && preferences.displayedItems.count >= 4
    }
}

#Preview {
    DisplaySettingsView()
        .environment(PreferencesStore())
}
