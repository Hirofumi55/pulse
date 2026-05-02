//
//  GlassStyle.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import SwiftUI

/// Pulse 全体で使うクリアなすりガラス背景。
struct PulseGlassBackdrop: View {
    let opacity: Double

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(opacity)

            LinearGradient(
                colors: [
                    .white.opacity(opacity * 0.20),
                    .clear,
                    .accentColor.opacity(opacity * 0.16),
                    .cyan.opacity(opacity * 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// クリアなすりガラスのパネル装飾を適用する。
    func pulseGlassPanel(
        cornerRadius: CGFloat = 8,
        tint: Color = .accentColor,
        materialOpacity: Double = 0.82
    ) -> some View {
        modifier(
            PulseGlassPanelModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                materialOpacity: materialOpacity
            )
        )
    }

    /// 設定画面用のガラス調フォーム装飾を適用する。
    func pulseGlassForm() -> some View {
        formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding(20)
            .background {
                PulseGlassBackdrop(opacity: 0.28)
            }
    }
}

private struct PulseGlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let materialOpacity: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .opacity(materialOpacity)
            }
            .overlay(alignment: .topLeading) {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.22),
                                .white.opacity(0.04),
                                .clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .strokeBorder(tint.opacity(0.22), lineWidth: 1)
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
    }
}
