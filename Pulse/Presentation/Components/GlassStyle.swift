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
    /// 背景全体のマテリアル不透明度。
    static func backdropMaterialOpacity(for opacity: Double, blurRadius: Double) -> Double {
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return Swift.min(Swift.max(0.04 + opacity * (0.30 + blurStrength * 0.70), 0.04), 0.92)
    }

    /// 背景全体のハイライト不透明度。
    static func backdropHighlightOpacity(for opacity: Double, blurRadius: Double) -> Double {
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return Swift.min(Swift.max(opacity * (0.16 + blurStrength * 0.18), 0.02), 0.34)
    }

    /// ウィジェットカード用のマテリアル不透明度。
    static func panelMaterialOpacity(for opacity: Double, blurRadius: Double = 14) -> Double {
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return Swift.min(Swift.max(0.06 + opacity * (0.28 + blurStrength * 0.42), 0.10), 0.64)
    }

    /// 小さなピル要素用のマテリアル不透明度。
    static func pillMaterialOpacity(for opacity: Double, blurRadius: Double = 14) -> Double {
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return Swift.min(Swift.max(0.05 + opacity * (0.22 + blurStrength * 0.34), 0.08), 0.48)
    }

    private static func normalizedBlurStrength(for blurRadius: Double) -> Double {
        Swift.min(Swift.max(blurRadius / 30, 0), 1)
    }
}

/// ガラス背景の色調。
enum PulseGlassTone {
    case adaptive
    case clearBlack

    var baseColor: Color {
        switch self {
        case .adaptive:
            Color(nsColor: .windowBackgroundColor)
        case .clearBlack:
            .black
        }
    }

    var baseOpacityMultiplier: Double {
        switch self {
        case .adaptive:
            1
        case .clearBlack:
            1.18
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .adaptive:
            0.08
        case .clearBlack:
            0.18
        }
    }
}

/// Pulse 全体で使うクリアなすりガラス背景。
struct PulseGlassBackdrop: View {
    let opacity: Double
    let blurRadius: Double
    let tone: PulseGlassTone

    init(opacity: Double, blurRadius: Double = 14, tone: PulseGlassTone = .adaptive) {
        self.opacity = opacity
        self.blurRadius = blurRadius
        self.tone = tone
    }

    var body: some View {
        let materialOpacity = PulseGlassStyle.backdropMaterialOpacity(
            for: opacity,
            blurRadius: blurRadius
        )
        let highlightOpacity = PulseGlassStyle.backdropHighlightOpacity(
            for: opacity,
            blurRadius: blurRadius
        )

        ZStack {
            Rectangle()
                .fill(.clear)

            ZStack {
                Rectangle()
                    .fill(tone.baseColor.opacity(opacity * tone.baseOpacityMultiplier))

                backdropMaterial
                    .opacity(materialOpacity)

                LinearGradient(
                    colors: [
                        .white.opacity(highlightOpacity),
                        .clear,
                        .accentColor.opacity(highlightOpacity * 0.65),
                        .cyan.opacity(highlightOpacity * 0.40),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .blur(radius: blurRadius * 0.10)

            LinearGradient(
                colors: [
                    .white.opacity(highlightOpacity * 1.2),
                    .clear,
                    .white.opacity(highlightOpacity * 0.5),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var backdropMaterial: some View {
        switch tone {
        case .adaptive:
            Rectangle()
                .fill(.ultraThinMaterial)
        case .clearBlack:
            ActiveGlassMaterial(material: .hudWindow)
        }
    }
}

extension View {
    /// クリアなすりガラスのパネル装飾を適用する。
    func pulseGlassPanel(
        cornerRadius: CGFloat = 8,
        tint: Color = .accentColor,
        materialOpacity: Double = 0.82,
        tone: PulseGlassTone = .adaptive
    ) -> some View {
        modifier(
            PulseGlassPanelModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                materialOpacity: materialOpacity,
                tone: tone
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
    let tone: PulseGlassTone

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                ZStack {
                    shape
                        .fill(
                            tone.baseColor.opacity(
                                materialOpacity * 0.22 * tone.baseOpacityMultiplier
                            )
                        )

                    panelMaterial(shape: shape)
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
            .shadow(color: .black.opacity(tone.shadowOpacity), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private func panelMaterial(shape: RoundedRectangle) -> some View {
        switch tone {
        case .adaptive:
            shape
                .fill(.ultraThinMaterial)
        case .clearBlack:
            ActiveGlassMaterial(material: .hudWindow)
                .clipShape(shape)
        }
    }
}

private struct ActiveGlassMaterial: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: NSVisualEffectView) {
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
    }
}
