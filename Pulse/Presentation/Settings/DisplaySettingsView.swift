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
                    .accessibilityHint(displayHint(for: item))
                }

                Text("メニューバーには最大4項目を表示できます。少なくとも1項目は選択してください。")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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

                    Toggle("縦バー内にパーセントを表示", isOn: barPercentageBinding)
                        .disabled(preferences.menuBarBarLayout == .horizontal)
                        .help(verticalPercentageHelp)
                        .accessibilityHint(verticalPercentageHelp)
                }

                Picker("更新頻度", selection: samplingIntervalBinding) {
                    ForEach(PreferencesStore.allowedSamplingIntervals, id: \.self) { interval in
                        Text(intervalTitle(interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("短縮ラベルを表示", isOn: iconBinding)
                    .help("CPU、MEM、NET などの短縮ラベルをメニューバー内に表示します。")
                    .accessibilityHint("CPU、MEM、NET などの短縮ラベルをメニューバー内に表示します。")

                MenuBarPreviewView()

                Text("ウィジェットを開いている間は、詳細情報を毎秒更新します。")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                        .accessibilityLabel("背景の濃さ")
                        .accessibilityValue("\(Int((preferences.popoverBackgroundOpacity * 100).rounded()))%")

                    HStack {
                        Text("ブラー")
                        Spacer()
                        Text("\(Int(preferences.popoverBackgroundBlurRadius.rounded()))pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: popoverBlurBinding, in: 0...30, step: 1)
                        .accessibilityLabel("背景ブラー")
                        .accessibilityValue("\(Int(preferences.popoverBackgroundBlurRadius.rounded()))pt")

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

    private var popoverBlurBinding: Binding<Double> {
        Binding {
            preferences.popoverBackgroundBlurRadius
        } set: { newValue in
            preferences.popoverBackgroundBlurRadius = newValue
        }
    }

    private var verticalPercentageHelp: String {
        if preferences.menuBarBarLayout == .horizontal {
            return "横バーではラベルを優先するため、パーセント表示は縦バーでのみ使えます。"
        }

        return "縦バーの中に現在値のパーセントを表示します。"
    }

    private var popoverOpacityPreview: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.35), .purple.opacity(0.3), .cyan.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            PulseGlassBackdrop(
                opacity: preferences.popoverBackgroundOpacity,
                blurRadius: preferences.popoverBackgroundBlurRadius,
                tone: .clearBlack
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
            }
            .overlay {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)
                    Text("背景越しに内容が自然に透けます")
                        .lineLimit(1)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            .accessibilityLabel("\(item.displayName)を上へ移動")
            .accessibilityHint("メニューバーでの表示順を一つ前にします")

            Button {
                moveItem(from: index, offset: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(index == preferences.displayedItems.count - 1)
            .help("下へ")
            .accessibilityLabel("\(item.displayName)を下へ移動")
            .accessibilityHint("メニューバーでの表示順を一つ後にします")
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

        if preferences.displayedItems.contains(item), preferences.displayedItems.count == 1 {
            return true
        }

        return !preferences.displayedItems.contains(item) && preferences.displayedItems.count >= 4
    }

    private func displayHint(for item: DisplayItem) -> String {
        if !item.isAvailableInPhase1 {
            return "次フェーズで対応予定です。"
        }

        if preferences.displayedItems.contains(item), preferences.displayedItems.count == 1 {
            return "メニューバーには少なくとも1項目が必要です。"
        }

        if !preferences.displayedItems.contains(item), preferences.displayedItems.count >= 4 {
            return "メニューバーに表示できる項目は最大4件です。"
        }

        return "メニューバーに表示する項目を切り替えます。"
    }
}

private struct MenuBarPreviewView: View {
    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        HStack {
            Text("プレビュー")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            previewContent
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("メニューバープレビュー")
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var previewContent: some View {
        let width = MenuBarRenderer.preferredLength(
            for: preferences.displayedItems,
            style: preferences.menuBarDisplayStyle,
            options: renderOptions
        )

        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.black.opacity(0.78))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.7)
                }

            switch preferences.menuBarDisplayStyle {
            case .text:
                Text(title)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 6)
            case .bar, .graph:
                Image(nsImage: image)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: min(max(width, 72), 220), height: 26)
    }

    private var image: NSImage {
        MenuBarRenderer.image(
            for: preferences.displayedItems,
            snapshot: nil,
            history: [],
            style: preferences.menuBarDisplayStyle,
            options: renderOptions
        )
    }

    private var title: String {
        MenuBarRenderer.title(
            for: preferences.displayedItems,
            snapshot: nil,
            showIcon: preferences.showMenuBarIcons,
            dataUnit: preferences.dataUnit,
            temperatureUnit: preferences.temperatureUnit
        )
    }

    private var accessibilityValue: String {
        "\(preferences.menuBarDisplayStyle.displayName)、\(title)"
    }

    private var renderOptions: MenuBarRenderOptions {
        MenuBarRenderOptions(
            showIcon: preferences.showMenuBarIcons,
            barLayout: preferences.menuBarBarLayout,
            showBarPercentage: preferences.showMenuBarBarPercentage
        )
    }
}

#Preview {
    DisplaySettingsView()
        .environment(PreferencesStore())
}
