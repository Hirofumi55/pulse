//
//  GlassStyle.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import SwiftUI

/// ガラス表現の不透明度を一元的に調整するヘルパー。
enum PulseGlassStyle {
    /// ウィジェットカード用のマテリアル不透明度。
    static func panelMaterialOpacity(for opacity: Double) -> Double {
        Swift.min(Swift.max(0.08 + opacity * 0.48, 0.12), 0.58)
    }

    /// 小さなピル要素用のマテリアル不透明度。
    static func pillMaterialOpacity(for opacity: Double) -> Double {
        Swift.min(Swift.max(0.06 + opacity * 0.36, 0.10), 0.42)
    }
}

/// Pulse 全体で使うクリアなすりガラス背景。
struct PulseGlassBackdrop: View {
    let opacity: Double
    let blurRadius: Double

    init(opacity: Double, blurRadius: Double = 14) {
        self.opacity = opacity
        self.blurRadius = blurRadius
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)

            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(opacity))

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(Swift.min(Swift.max(opacity * 0.85, 0.05), 0.75))

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
            .blur(radius: blurRadius)

            LinearGradient(
                colors: [
                    .white.opacity(opacity * 0.22),
                    .clear,
                    .white.opacity(opacity * 0.08),
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
                ZStack {
                    shape
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(materialOpacity * 0.22))

                    shape
                        .fill(.ultraThinMaterial)
                        .opacity(materialOpacity)

                    shape
                        .fill(tint.opacity(materialOpacity * 0.08))
                }
            }
            .overlay(alignment: .topLeading) {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(materialOpacity * 0.34),
                                .white.opacity(materialOpacity * 0.08),
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
                    .strokeBorder(.white.opacity(0.20), lineWidth: 0.8)
            }
            .overlay {
                shape
                    .strokeBorder(tint.opacity(materialOpacity * 0.35), lineWidth: 1)
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}
