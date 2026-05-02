//
//  DisplaySettingsView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

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
                Toggle("アイコンを表示", isOn: iconBinding)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var iconBinding: Binding<Bool> {
        Binding {
            preferences.showMenuBarIcons
        } set: { newValue in
            preferences.showMenuBarIcons = newValue
        }
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
