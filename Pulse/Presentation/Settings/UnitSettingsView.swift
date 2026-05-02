//
//  UnitSettingsView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// 表示単位を設定するビュー。
struct UnitSettingsView: View {
    @Environment(PreferencesStore.self) private var preferences

    var body: some View {
        Form {
            Section("温度") {
                Picker("単位", selection: temperatureBinding) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.displayName)
                            .tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("データ") {
                Picker("単位系", selection: dataUnitBinding) {
                    ForEach(DataUnit.allCases) { unit in
                        Text(unit.displayName)
                            .tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("外観") {
                Picker("テーマ", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases) { appearance in
                        Text(appearance.displayName)
                            .tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var temperatureBinding: Binding<TemperatureUnit> {
        Binding {
            preferences.temperatureUnit
        } set: { newValue in
            preferences.temperatureUnit = newValue
        }
    }

    private var dataUnitBinding: Binding<DataUnit> {
        Binding {
            preferences.dataUnit
        } set: { newValue in
            preferences.dataUnit = newValue
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding {
            preferences.appearance
        } set: { newValue in
            preferences.appearance = newValue
        }
    }
}

#Preview {
    UnitSettingsView()
        .environment(PreferencesStore())
}
