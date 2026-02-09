import SwiftUI

struct AppColors {
    static let primaryGradientStart = Color(red: 0.36, green: 0.62, blue: 0.92)
    static let primaryGradientEnd = Color(red: 0.28, green: 0.50, blue: 0.82)

    static let hitGradientStart = Color(red: 0.31, green: 0.91, blue: 0.60)
    static let hitGradientEnd = Color(red: 0.09, green: 0.74, blue: 0.51)

    static let missGradientStart = Color(red: 0.98, green: 0.43, blue: 0.34)
    static let missGradientEnd = Color(red: 0.83, green: 0.27, blue: 0.30)

    static let idleGradientStart = Color(red: 0.94, green: 0.74, blue: 0.33)
    static let idleGradientEnd = Color(red: 0.84, green: 0.57, blue: 0.24)

    static let brassPrimary = Color(red: 0.62, green: 0.66, blue: 0.72)
    static let brassSecondary = Color(red: 0.44, green: 0.48, blue: 0.54)
    static let cyanAccent = Color(red: 0.43, green: 0.76, blue: 0.92)

    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.14)
    static let glassHighlight = Color.white.opacity(0.2)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.5)

    static let backgroundDeep = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let backgroundMid = Color(red: 0.09, green: 0.11, blue: 0.14)
    static let backgroundWarm = Color(red: 0.12, green: 0.12, blue: 0.13)
}

struct AppGradients {
    static let primary = LinearGradient(
        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let hit = LinearGradient(
        colors: [AppColors.hitGradientStart, AppColors.hitGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let miss = LinearGradient(
        colors: [AppColors.missGradientStart, AppColors.missGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let idle = LinearGradient(
        colors: [AppColors.idleGradientStart, AppColors.idleGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brass = LinearGradient(
        colors: [AppColors.brassPrimary, AppColors.brassSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassShine = LinearGradient(
        colors: [Color.white.opacity(0.18), Color.white.opacity(0.0)],
        startPoint: .topLeading,
        endPoint: .center
    )

    static let ambientGlow = RadialGradient(
        colors: [
            AppColors.primaryGradientStart.opacity(0.2),
            AppColors.cyanAccent.opacity(0.12),
            Color.clear
        ],
        center: .center,
        startRadius: 40,
        endRadius: 330
    )

    static let backgroundFallback = RadialGradient(
        colors: [
            AppColors.backgroundMid,
            AppColors.backgroundDeep
        ],
        center: .center,
        startRadius: 0,
        endRadius: 500
    )
}

struct AppTypography {
    static let title: Font = .custom("AvenirNextCondensed-DemiBold", size: 28)
    static let hero: Font = .custom("AvenirNextCondensed-DemiBold", size: 52)
    static let sectionLabel: Font = .custom("AvenirNext-DemiBold", size: 12)
    static let body: Font = .custom("AvenirNext-Medium", size: 15)
    static let bodyStrong: Font = .custom("AvenirNext-DemiBold", size: 15)
    static let caption: Font = .custom("AvenirNext-Regular", size: 12)
    static let mono: Font = .custom("Menlo-Bold", size: 14)
}

struct BackgroundGradientView: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    AppColors.backgroundDeep,
                    AppColors.backgroundMid,
                    AppColors.backgroundDeep,
                    AppColors.backgroundWarm,
                    Color(red: 0.11, green: 0.13, blue: 0.17),
                    AppColors.backgroundWarm,
                    AppColors.backgroundDeep,
                    AppColors.backgroundMid,
                    AppColors.backgroundDeep
                ]
            )
        } else {
            AppGradients.backgroundFallback
        }
    }
}

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var intensity: Double = 0.08

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(intensity * 0.7))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppGradients.glassShine)
                        .mask(
                            LinearGradient(
                                colors: [.white, .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.48),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, intensity: Double = 0.08) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, intensity: intensity))
    }

    func innerGlow(radius: CGFloat = 14) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                .blur(radius: 0.3)
        )
    }
}
