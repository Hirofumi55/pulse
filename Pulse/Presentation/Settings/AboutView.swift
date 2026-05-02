//
//  AboutView.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// アプリ情報を表示するビュー。
struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pulse")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Modern system monitor for Apple Silicon")
                        .foregroundStyle(.secondary)
                }
            }

            Section("バージョン") {
                LabeledContent("Pulse", value: Bundle.main.pulseVersion)
            }

            Section("リンク") {
                linkRow(title: "GitHub", urlString: "https://github.com/Hirofumi55/pulse")
                linkRow(title: "Issues", urlString: "https://github.com/Hirofumi55/pulse/issues")
            }

            Section("ライセンス") {
                Text("MIT License")
                Text("Copyright © 2026 Pulse Project")
                    .foregroundStyle(.secondary)
            }
        }
        .pulseGlassForm()
    }

    private func linkRow(title: String, urlString: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let url = URL(string: urlString) {
                Link(urlString, destination: url)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
            } else {
                Text(urlString)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
            }
        }
    }
}

#Preview {
    AboutView()
}
