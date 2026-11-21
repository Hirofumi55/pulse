//
//  GlassStyle.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import AppKit
import SwiftUI

/// Pulse 全体で統一するモーション定義。
enum PulseMotion {
    /// タブ切替やホバーなどの軽快なスプリング。
    static let snappy = Animation.spring(duration: 0.30, bounce: 0.14)

    /// ゲージ・バー・カード展開などの滑らかなスプリング。
    static let smooth = Animation.spring(duration: 0.44, bounce: 0.06)

    /// 数値ロールや微細な色遷移。
    static let numeric = Animation.snappy(duration: 0.28, extraBounce: 0.0)

    /// Reduce Motion を尊重してアニメーションを返す。
    static func resolve(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

/// ガラス表現の不透明度を一元的に調整するヘルパー。
enum PulseGlassStyle {
    /// 背景全体のマテリアル不透明度。
    static func backdropMaterialOpacity(for opacity: Double, blurRadius: Double) -> Double {
        let backgroundOpacity = normalizedOpacity(opacity)
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return clamped(blurStrength * (0.90 - backgroundOpacity * 0.75), to: 0...0.86)
    }

    /// 背景全体のハイライト不透明度。
    static func backdropHighlightOpacity(for opacity: Double, blurRadius: Double) -> Double {
        let backgroundOpacity = normalizedOpacity(opacity)
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return clamped(0.015 + backgroundOpacity * 0.10 + blurStrength * 0.08, to: 0.015...0.18)
    }

    /// ウィジェットカード用のマテリアル不透明度。
    static func panelMaterialOpacity(for opacity: Double, blurRadius: Double = 14) -> Double {
        let backgroundOpacity = normalizedOpacity(opacity)
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return clamped(0.12 + backgroundOpacity * 0.32 + blurStrength * 0.22, to: 0.12...0.64)
    }

    /// 小さなピル要素用のマテリアル不透明度。
    static func pillMaterialOpacity(for opacity: Double, blurRadius: Double = 14) -> Double {
        let backgroundOpacity = normalizedOpacity(opacity)
        let blurStrength = normalizedBlurStrength(for: blurRadius)
        return clamped(0.08 + backgroundOpacity * 0.22 + blurStrength * 0.16, to: 0.08...0.46)
    }

    private static func normalizedOpacity(_ opacity: Double) -> Double {
        clamped(opacity, to: 0...1)
    }

    private static func normalizedBlurStrength(for blurRadius: Double) -> Double {
        clamped(blurRadius / 30, to: 0...1)
    }

    private static func clamped(_ value: Double, to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
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

    func backdropBaseOpacity(for opacity: Double) -> Double {
        switch self {
        case .adaptive:
            opacity
        case .clearBlack:
            Swift.min(Swift.max(0.08 + opacity * 0.72, 0.14), 0.73)
        }
    }

    func panelBaseOpacity(for materialOpacity: Double) -> Double {
        switch self {
        case .adaptive:
            materialOpacity * 0.18
        case .clearBlack:
            Swift.min(Swift.max(0.12 + materialOpacity * 0.36, 0.16), 0.38)
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .adaptive:
            0.08
        case .clearBlack:
            0.14
        }
    }
}

/// macOS 26+ で Liquid Glass 要素の光学的な融合を有効にするコンテナ。
struct PulseGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: spacing) {
                    content
                }
            } else {
                content
            }
        #else
            content
        #endif
    }
}

/// Pulse 全体で使う透過性の高い Liquid Glass 調背景。
struct PulseGlassBackdrop: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

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
            if reduceTransparency {
                Rectangle()
                    .fill(tone == .clearBlack ? Color(white: 0.14) : tone.baseColor)
            } else {
                backdropMaterial
                    .opacity(materialOpacity)

                Rectangle()
                    .fill(tone.baseColor.opacity(tone.backdropBaseOpacity(for: opacity)))

                // 上端から柔らかな環境光を落とす控えめなスペキュラ層。
                LinearGradient(
                    colors: [
                        .white.opacity(highlightOpacity * 0.72),
                        .clear,
                        .black.opacity(highlightOpacity * 0.32),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    .white.opacity(highlightOpacity * 1.45),
                    .white.opacity(highlightOpacity * 0.45),
                    .white.opacity(highlightOpacity * 0.12),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 0.75)
            .allowsHitTesting(false)
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
            ActiveGlassMaterial(material: .hudWindow, blendingMode: .behindWindow)
        }
    }
}

/// サンプリング稼働中を静かに伝えるライブインジケータ。
struct PulseLiveIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let pulseDate: Date?

    @State private var isExpanding = false

    var body: some View {
        ZStack {
            if isActive, !reduceMotion {
                Circle()
                    .fill(Color.green.opacity(isExpanding ? 0 : 0.26))
                    .frame(width: 7, height: 7)
                    .scaleEffect(isExpanding ? 1.65 : 1.0)
            }

            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 6, height: 6)
        }
        .frame(width: 14, height: 14)
        .onChange(of: pulseDate) { _, _ in
            guard isActive, !reduceMotion else {
                return
            }
            isExpanding = false
            withAnimation(.easeOut(duration: 0.85)) {
                isExpanding = true
            }
        }
    }
}

extension View {
    /// クリアなガラスパネル装飾を適用する。
    func pulseGlassPanel(
        cornerRadius: CGFloat = 14,
        tint: Color = .accentColor,
        materialOpacity: Double = 0.82,
        tone: PulseGlassTone = .adaptive,
        isInteractive: Bool = false,
        isHovered: Bool = false
    ) -> some View {
        modifier(
            PulseGlassPanelModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                materialOpacity: materialOpacity,
                tone: tone,
                isInteractive: isInteractive,
                isHovered: isHovered
            )
        )
    }

    /// タブバーなどのフローティング・カプセル装飾を適用する。
    func pulseGlassCapsule(isInteractive: Bool = false) -> some View {
        modifier(PulseGlassCapsuleModifier(isInteractive: isInteractive))
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

private struct PulseGlassCapsuleModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let isInteractive: Bool

    func body(content: Content) -> some View {
        let shape = Capsule(style: .continuous)

        #if compiler(>=6.2)
            if #available(macOS 26.0, *), !reduceTransparency {
                content
                    .glassEffect(
                        isInteractive ? .regular.interactive() : .regular,
                        in: shape
                    )
            } else {
                fallbackBody(content: content, shape: shape)
            }
        #else
            fallbackBody(content: content, shape: shape)
        #endif
    }

    private func fallbackBody(content: Content, shape: Capsule) -> some View {
        content
            .background {
                if reduceTransparency {
                    shape.fill(Color.black.opacity(0.75))
                } else {
                    shape.fill(.white.opacity(0.08))
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            }
            .clipShape(shape)
    }
}

private struct PulseGlassPanelModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let cornerRadius: CGFloat
    let tint: Color
    let materialOpacity: Double
    let tone: PulseGlassTone
    let isInteractive: Bool
    let isHovered: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        #if compiler(>=6.2)
            if #available(macOS 26.0, *), !reduceTransparency, tone == .clearBlack {
                liquidGlassCard(content: content, shape: shape)
            } else {
                layeredGlassCard(content: content, shape: shape)
            }
        #else
            layeredGlassCard(content: content, shape: shape)
        #endif
    }

    #if compiler(>=6.2)
        @available(macOS 26.0, *)
        private func liquidGlassCard(content: Content, shape: RoundedRectangle) -> some View {
            let tintAlpha = isHovered ? 0.065 : 0.025
            let baseTint = Color.black.opacity(tone.panelBaseOpacity(for: materialOpacity) * 0.55)
            let glassStyle = Glass.clear.tint(baseTint).interactive(isInteractive)

            return
                content
                .background {
                    shape.fill(tint.opacity(tintAlpha))
                }
                .glassEffect(glassStyle, in: shape)
                .overlay {
                    specularBorder(shape: shape)
                }
                .shadow(
                    color: .black.opacity(isHovered ? tone.shadowOpacity * 1.35 : tone.shadowOpacity),
                    radius: isHovered ? 12 : 7,
                    x: 0,
                    y: isHovered ? 6 : 3
                )
        }
    #endif

    private func layeredGlassCard(content: Content, shape: RoundedRectangle) -> some View {
        content
            .background {
                ZStack {
                    if reduceTransparency {
                        shape
                            .fill(
                                tone == .clearBlack
                                    ? Color(white: 0.14).opacity(0.96)
                                    : Color(nsColor: .windowBackgroundColor).opacity(0.96)
                            )
                    } else {
                        panelMaterial(shape: shape)
                            .opacity(materialOpacity)

                        shape
                            .fill(tone.baseColor.opacity(tone.panelBaseOpacity(for: materialOpacity)))

                        shape
                            .fill(tint.opacity(isHovered ? 0.055 : materialOpacity * 0.028))
                    }
                }
            }
            .overlay {
                if !reduceTransparency {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isHovered ? 0.14 : materialOpacity * 0.14),
                                    .white.opacity(0.02),
                                    .clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                specularBorder(shape: shape)
            }
            .clipShape(shape)
            .shadow(
                color: .black.opacity(isHovered ? tone.shadowOpacity * 1.4 : tone.shadowOpacity),
                radius: isHovered ? 10 : 7,
                x: 0,
                y: isHovered ? 5 : 3
            )
    }

    private func specularBorder(shape: RoundedRectangle) -> some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        .white.opacity(isHovered ? 0.36 : 0.24),
                        .white.opacity(isHovered ? 0.11 : 0.06),
                        .white.opacity(isHovered ? 0.18 : 0.12),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.75
            )
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func panelMaterial(shape: RoundedRectangle) -> some View {
        switch tone {
        case .adaptive:
            shape
                .fill(.ultraThinMaterial)
        case .clearBlack:
            ActiveGlassMaterial(material: .contentBackground, blendingMode: .withinWindow)
                .clipShape(shape)
        }
    }
}

private struct ActiveGlassMaterial: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

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
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
    }
}
