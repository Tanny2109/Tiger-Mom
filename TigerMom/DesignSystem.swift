import SwiftUI

// MARK: - Color Palette

enum TigerPalette {
    // Backgrounds - deeper, richer blacks
    static let background = Color(hex: 0x0A0A0B)
    static let backgroundSecondary = Color(hex: 0x111113)
    static let backgroundTertiary = Color(hex: 0x18181B)
    
    // Surfaces - more visible elevation
    static let surface = Color(hex: 0x1C1C1F)
    static let surfaceElevated = Color(hex: 0x232326)
    static let surfaceHover = Color.white.opacity(0.04)
    
    // Legacy panel colors (for compatibility)
    static let panel = Color.white.opacity(0.06)
    static let panelStrong = Color.white.opacity(0.10)
    
    // Borders - cleaner separation
    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.12)
    static let line = Color.white.opacity(0.08)
    
    // Text - improved contrast hierarchy
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.65)
    static let textMuted = Color.white.opacity(0.40)
    static let textDisabled = Color.white.opacity(0.25)
    
    // Accents - refined, cohesive
    static let gold = Color(hex: 0xF5C563)      // Primary brand
    static let amber = Color(hex: 0xFFE4C4)     // Warm highlight
    static let coral = Color(hex: 0xE87B6B)     // Warning/distraction
    static let jade = Color(hex: 0x3ECF8E)      // Success/deep work
    static let mist = Color(hex: 0x7DD3FC)      // Info/communication
    static let violet = Color(hex: 0xA78BFA)    // Secondary accent
    static let obsidian = Color(hex: 0x0D1015)
}

// MARK: - Typography Scale

enum TigerTypography {
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .medium)
    static let bodySmall = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 11, weight: .semibold)
    static let overline = Font.system(size: 10, weight: .bold)
}

// MARK: - Spacing Scale

enum TigerSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Animation Presets

extension Animation {
    static let tigerSpring = Animation.spring(response: 0.3, dampingFraction: 0.75)
    static let tigerQuick = Animation.easeOut(duration: 0.15)
    static let tigerSmooth = Animation.easeInOut(duration: 0.25)
}

// MARK: - App Background

struct TigerAppBackground: View {
    var body: some View {
        ZStack {
            TigerPalette.background
            
            // Subtle warm gradient in top-left
            RadialGradient(
                colors: [TigerPalette.gold.opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 40,
                endRadius: 400
            )
            .offset(x: -80, y: -100)
            
            // Subtle cool accent top-right
            RadialGradient(
                colors: [TigerPalette.mist.opacity(0.08), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 300
            )
            .offset(x: 150, y: -50)
            
            // Very subtle noise texture
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.015), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Panel Component

struct TigerPanel<Content: View>: View {
    var padding: CGFloat = TigerSpacing.xl
    var cornerRadius: CGFloat = 16
    var emphasis: Double = 1.0
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(TigerPalette.surface.opacity(0.8 + (0.2 * emphasis)))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Navigation Item

struct TigerNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: TigerSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? TigerPalette.gold : TigerPalette.textSecondary)
                    .frame(width: 20)
                
                Text(label)
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(isSelected ? TigerPalette.textPrimary : TigerPalette.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, TigerSpacing.md)
            .padding(.vertical, TigerSpacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? TigerPalette.gold.opacity(0.12) : (isHovered ? TigerPalette.surfaceHover : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? TigerPalette.gold.opacity(0.2) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.tigerQuick, value: isHovered)
        .animation(.tigerQuick, value: isSelected)
    }
}

// MARK: - Section Label (for sidebar)

struct TigerSectionLabel: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(TigerTypography.overline)
            .tracking(1.2)
            .foregroundColor(TigerPalette.textMuted)
            .padding(.horizontal, TigerSpacing.md)
            .padding(.top, TigerSpacing.lg)
            .padding(.bottom, TigerSpacing.xs)
    }
}

// MARK: - Eye Shape

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

// MARK: - Tiger Mark (Logo)

struct TigerMark: View {
    var size: CGFloat = 44
    var framed: Bool = true
    var luminous: Bool = true

    var body: some View {
        ZStack {
            if framed {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                TigerPalette.obsidian,
                                Color(hex: 0x151519)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                            .strokeBorder(TigerPalette.borderStrong, lineWidth: 1)
                    )
            }

            if luminous {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TigerPalette.gold.opacity(0.25), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.45
                        )
                    )
                    .frame(width: size * 0.8, height: size * 0.8)
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
        }
        .frame(width: size, height: size)
        .shadow(color: TigerPalette.gold.opacity(luminous ? 0.2 : 0.1), radius: size * 0.15, x: 0, y: size * 0.06)
    }
}

// MARK: - Tiger Mark Strip

struct TigerMarkStrip: View {
    var size: CGFloat = 36
    var showSubtitle: Bool = true

    var body: some View {
        HStack(spacing: TigerSpacing.md) {
            TigerMark(size: size)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tiger Mom")
                    .font(TigerTypography.title)
                    .foregroundColor(TigerPalette.textPrimary)

                if showSubtitle {
                    Text("Watchful coaching")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textMuted)
                }
            }
        }
    }
}

// MARK: - Inline Glyph

struct TigerInlineGlyph: View {
    var size: CGFloat = 34

    var body: some View {
        TigerMark(size: size, framed: false, luminous: false)
            .frame(width: size, height: size)
    }
}

// MARK: - Section Header

struct TigerSectionHeader: View {
    let eyebrow: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            Text(eyebrow.uppercased())
                .font(TigerTypography.overline)
                .tracking(1.4)
                .foregroundColor(TigerPalette.textMuted)

            Text(title)
                .font(TigerTypography.headline)
                .foregroundColor(TigerPalette.textPrimary)

            if let detail {
                Text(detail)
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Metric Tile

struct TigerMetricTile: View {
    let label: String
    let value: String
    let symbol: String
    let tint: Color
    
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                Text(value)
                    .font(TigerTypography.headline)
                    .foregroundColor(TigerPalette.textPrimary)

                Text(label)
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TigerSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TigerPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isHovered ? TigerPalette.borderStrong : TigerPalette.border, lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.tigerSpring, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Capsule Badge

struct TigerCapsuleBadge: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = TigerPalette.gold

    var body: some View {
        HStack(spacing: TigerSpacing.xs + 2) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
            }

            Text(title)
                .font(TigerTypography.caption)
        }
        .foregroundColor(tint)
        .padding(.horizontal, TigerSpacing.sm + 2)
        .padding(.vertical, TigerSpacing.xs + 2)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.1))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(tint.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Inset Field Style

struct TigerInsetFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TigerPalette.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func tigerInsetField() -> some View {
        modifier(TigerInsetFieldStyle())
    }
}

// MARK: - Hover Scale Modifier

struct TigerHoverScale: ViewModifier {
    var scale: CGFloat = 1.02
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.tigerSpring, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func tigerHoverScale(_ scale: CGFloat = 1.02) -> some View {
        modifier(TigerHoverScale(scale: scale))
    }
}

// MARK: - Divider

struct TigerDivider: View {
    var vertical: Bool = false
    
    var body: some View {
        if vertical {
            Rectangle()
                .fill(TigerPalette.border)
                .frame(width: 1)
        } else {
            Rectangle()
                .fill(TigerPalette.border)
                .frame(height: 1)
        }
    }
}

// MARK: - Skeleton Loading

struct TigerSkeleton: View {
    var cornerRadius: CGFloat = 8
    @State private var shimmer = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(TigerPalette.surfaceHover)
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.05),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmer ? 200 : -200)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
    }
}

// MARK: - Button Style (for .buttonStyle modifier)

enum TigerButtonProminence {
    case primary
    case secondary
    case quiet
}

struct TigerButtonStyle: ButtonStyle {
    var tint: Color = TigerPalette.gold
    var prominence: TigerButtonProminence = .secondary
    var cornerRadius: CGFloat = 10
    
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TigerTypography.bodySmall)
            .fontWeight(prominence == .primary ? .semibold : .medium)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.md)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: prominence == .quiet ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.tigerQuick, value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
    
    private var foregroundColor: Color {
        switch prominence {
        case .primary:
            return TigerPalette.background
        case .secondary:
            return tint
        case .quiet:
            return TigerPalette.textSecondary
        }
    }
    
    private var background: some View {
        Group {
            switch prominence {
            case .primary:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint)
            case .secondary:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(0.12))
            case .quiet:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? TigerPalette.surfaceHover : .clear)
            }
        }
    }
    
    private var borderColor: Color {
        switch prominence {
        case .primary:
            return .clear
        case .secondary:
            return tint.opacity(0.2)
        case .quiet:
            return TigerPalette.border
        }
    }
}

// MARK: - Primary Button

struct TigerPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: TigerSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(TigerTypography.bodySmall)
                    .fontWeight(.semibold)
            }
            .foregroundColor(TigerPalette.background)
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TigerPalette.gold)
            )
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .animation(.tigerSpring, value: isHovered)
            .animation(.tigerQuick, value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Secondary Button

struct TigerSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: TigerSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(TigerTypography.bodySmall)
            }
            .foregroundColor(TigerPalette.textSecondary)
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? TigerPalette.surfaceHover : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                    )
            )
            .animation(.tigerQuick, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Color Extension

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

// MARK: - Int Extensions

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
