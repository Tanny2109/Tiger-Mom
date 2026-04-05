import SwiftUI

enum TigerPalette {
    static let background = Color(hex: 0x060709)
    static let backgroundSecondary = Color(hex: 0x11141A)
    static let panel = Color.white.opacity(0.07)
    static let panelStrong = Color.white.opacity(0.13)
    static let line = Color.white.opacity(0.09)
    static let textPrimary = Color.white.opacity(0.982)
    static let textSecondary = Color.white.opacity(0.72)
    static let textMuted = Color.white.opacity(0.44)
    static let gold = Color(hex: 0xF2C078)
    static let amber = Color(hex: 0xFFF3E2)
    static let coral = Color(hex: 0xD59A73)
    static let jade = Color(hex: 0xCDD4DE)
    static let mist = Color(hex: 0xEEF1F5)
    static let obsidian = Color(hex: 0x0D1015)
}

struct TigerAppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TigerPalette.background,
                    Color(hex: 0x0C0E13),
                    TigerPalette.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [TigerPalette.gold.opacity(0.24), .clear],
                center: .topLeading,
                startRadius: 40,
                endRadius: 480
            )
            .offset(x: -90, y: -130)

            RadialGradient(
                colors: [TigerPalette.mist.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 360
            )
            .offset(x: 200, y: -30)

            RadialGradient(
                colors: [TigerPalette.coral.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .offset(x: 170, y: 240)

            RadialGradient(
                colors: [TigerPalette.amber.opacity(0.1), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 280
            )
            .offset(x: -140, y: 260)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.022), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
    }
}

struct TigerPanel<Content: View>: View {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 26
    var emphasis: Double = 1.0
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(TigerPalette.panel.opacity(0.94 + (0.05 * emphasis)))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18),
                                        TigerPalette.amber.opacity(0.08),
                                        Color.white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.42), radius: 34, x: 0, y: 24)
            )
    }
}

struct TigerEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let midY = rect.midY

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: midY),
            control1: CGPoint(x: rect.minX + width * 0.22, y: rect.minY),
            control2: CGPoint(x: rect.minX + width * 0.78, y: rect.minY + height * 0.04)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: midY),
            control1: CGPoint(x: rect.minX + width * 0.78, y: rect.maxY - height * 0.04),
            control2: CGPoint(x: rect.minX + width * 0.22, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

struct TigerMark: View {
    var size: CGFloat = 44
    var framed: Bool = true
    var luminous: Bool = true

    var body: some View {
        ZStack {
            if framed {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                TigerPalette.obsidian,
                                Color(hex: 0x171B22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18),
                                        TigerPalette.amber.opacity(0.18),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: max(1, size * 0.026)
                            )
                    )

                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            if luminous {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TigerPalette.gold.opacity(0.28), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.48
                        )
                    )
                    .frame(width: size * 0.8, height: size * 0.8)
                    .blur(radius: size * 0.02)
            }

            TigerEyeShape()
                .fill(
                    LinearGradient(
                        colors: [
                            TigerPalette.amber.opacity(0.95),
                            TigerPalette.gold,
                            TigerPalette.coral
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.62, height: size * 0.28)
                .overlay(
                    TigerEyeShape()
                        .stroke(Color.white.opacity(0.28), lineWidth: max(0.8, size * 0.015))
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            TigerPalette.amber.opacity(0.95),
                            TigerPalette.gold.opacity(0.95),
                            TigerPalette.coral.opacity(0.88)
                        ],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: size * 0.14
                    )
                )
                .frame(width: size * 0.22, height: size * 0.22)

            Capsule(style: .continuous)
                .fill(Color(hex: 0x050607))
                .frame(width: size * 0.05, height: size * 0.22)

            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: -size * 0.06, y: -size * 0.03)
                .blur(radius: size * 0.004)
        }
        .frame(width: size, height: size)
        .shadow(color: TigerPalette.gold.opacity(luminous ? 0.28 : 0.16), radius: size * 0.18, x: 0, y: size * 0.08)
    }
}

struct TigerMarkStrip: View {
    var size: CGFloat = 40

    var body: some View {
        HStack(spacing: 10) {
            TigerMark(size: size)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tiger Mom")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Watchful coaching for your Mac")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
    }
}

struct TigerInlineGlyph: View {
    var size: CGFloat = 34

    var body: some View {
        TigerMark(size: size, framed: false, luminous: false)
            .frame(width: size, height: size)
    }
}

struct TigerSectionHeader: View {
    let eyebrow: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundColor(TigerPalette.textMuted)

            Text(title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(TigerPalette.textPrimary)

            if let detail {
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
    }
}

struct TigerMetricTile: View {
    let label: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct TigerCapsuleBadge: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = TigerPalette.gold

    var body: some View {
        HStack(spacing: 7) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(tint.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

struct TigerInsetFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func tigerInsetField() -> some View {
        modifier(TigerInsetFieldStyle())
    }
}

struct TigerDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, TigerPalette.line, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

extension Int {
    var tigerDuration: String {
        let hours = self / 60
        let minutes = self % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    var tigerClock: String {
        let hours = self / 60
        let minutes = self % 60
        return "\(hours):\(String(format: "%02d", minutes))"
    }
}
