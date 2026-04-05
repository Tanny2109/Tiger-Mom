import SwiftUI

enum TigerPalette {
    static let background = Color(hex: 0x111316)
    static let backgroundSecondary = Color(hex: 0x191D22)
    static let panel = Color.white.opacity(0.05)
    static let panelStrong = Color.white.opacity(0.08)
    static let line = Color.white.opacity(0.10)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.68)
    static let textMuted = Color.white.opacity(0.45)
    static let gold = Color(hex: 0xD2AF80)
    static let amber = Color(hex: 0xEFE2CF)
    static let coral = Color(hex: 0xC88969)
    static let jade = Color(hex: 0xC6D0DC)
    static let mist = Color(hex: 0xE8EDF4)
    static let obsidian = Color(hex: 0x171A1F)
}

struct TigerAppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TigerPalette.background,
                    Color(hex: 0x15181D),
                    TigerPalette.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [TigerPalette.amber.opacity(0.08), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 420
            )
            .offset(x: -80, y: -100)

            RadialGradient(
                colors: [Color.white.opacity(0.05), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 340
            )
            .offset(x: 120, y: -20)

            Rectangle()
                .fill(Color.black.opacity(0.08))
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

struct TigerPanel<Content: View>: View {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    var emphasis: Double = 1.0
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(TigerPalette.panel.opacity(0.96 + (0.03 * emphasis)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08 + (0.02 * emphasis)), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: 0.2)
                    }
                    .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
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
                                Color(hex: 0x1F242B)
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
                                        Color.white.opacity(0.16),
                                        TigerPalette.amber.opacity(0.14),
                                        Color.white.opacity(0.04)
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
                            colors: [Color.white.opacity(0.05), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            if luminous {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TigerPalette.gold.opacity(0.18), .clear],
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
                            TigerPalette.amber.opacity(0.88),
                            TigerPalette.gold.opacity(0.96),
                            TigerPalette.coral.opacity(0.9)
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
                            Color.white.opacity(0.45),
                            TigerPalette.amber.opacity(0.9),
                            TigerPalette.gold.opacity(0.85),
                            TigerPalette.coral.opacity(0.75)
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
        .shadow(color: TigerPalette.gold.opacity(luminous ? 0.16 : 0.08), radius: size * 0.14, x: 0, y: size * 0.05)
    }
}

struct TigerMarkStrip: View {
    var size: CGFloat = 40

    var body: some View {
        HStack(spacing: 10) {
            TigerMark(size: size)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tiger Mom")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Watchful coaching for your Mac")
                    .font(.system(size: 11, weight: .medium))
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
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundColor(TigerPalette.textMuted)

            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(TigerPalette.textPrimary)

            if let detail {
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(TigerPalette.textSecondary)
                    .lineSpacing(2)
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
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
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
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.1))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(tint.opacity(0.14), lineWidth: 1)
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
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
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
                    colors: [.clear, TigerPalette.line.opacity(0.9), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

enum TigerButtonProminence {
    case primary
    case secondary
    case quiet
}

struct TigerButtonStyle: ButtonStyle {
    var tint: Color = TigerPalette.gold
    var prominence: TigerButtonProminence = .secondary
    var cornerRadius: CGFloat = 15

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, prominence == .quiet ? 12 : 14)
            .padding(.vertical, 10)
            .background(background(configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        prominence == .primary ? TigerPalette.background : tint
    }

    @ViewBuilder
    private func background(_ isPressed: Bool) -> some View {
        let opacityShift = isPressed ? 0.08 : 0

        switch prominence {
        case .primary:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint.opacity(0.9 - opacityShift))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        case .secondary:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint.opacity(0.1 + opacityShift))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(tint.opacity(0.14), lineWidth: 1)
                )
        case .quiet:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.035 + opacityShift))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
        }
    }
}

struct TigerPillButtonStyle: ButtonStyle {
    var tint: Color = TigerPalette.textPrimary
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? tint : TigerPalette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? tint.opacity(0.12) : Color.white.opacity(0.035 + (configuration.isPressed ? 0.03 : 0)))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(isSelected ? tint.opacity(0.16) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TigerLabeledValueRow: View {
    let label: String
    let value: String
    var tint: Color? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(TigerPalette.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(tint ?? TigerPalette.textPrimary)
        }
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
