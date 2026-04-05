import SwiftUI

struct NudgePopoverView: View {
    let nudge: NudgeData
    let onResponse: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Severity indicator bar
            Rectangle()
                .fill(severityColor)
                .frame(height: 3)

            VStack(spacing: TigerSpacing.lg) {
                // Logo
                TigerMark(size: 48)
                    .padding(.top, TigerSpacing.lg)

                // Message
                Text(nudge.message)
                    .font(TigerTypography.body)
                    .foregroundColor(TigerPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .lineSpacing(3)
                    .padding(.horizontal, TigerSpacing.lg)

                // Trigger context
                if !nudge.trigger.isEmpty {
                    Text(nudge.trigger)
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textSecondary)
                        .padding(.horizontal, TigerSpacing.md)
                        .padding(.vertical, TigerSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(TigerPalette.backgroundTertiary)
                        )
                }

                // Action buttons
                HStack(spacing: TigerSpacing.md) {
                    Button {
                        onResponse("acknowledged")
                    } label: {
                        Text("OK fine...")
                            .font(TigerTypography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(TigerPalette.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TigerSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(severityColor)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onResponse("snoozed")
                    } label: {
                        Text("5 more minutes")
                            .font(TigerTypography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(TigerPalette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TigerSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(TigerPalette.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, TigerSpacing.lg)
                .padding(.bottom, TigerSpacing.lg)
            }
        }
        .frame(width: 300)
        .background(TigerPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(TigerPalette.border, lineWidth: 1)
        )
    }
    
    private var severityColor: Color {
        switch nudge.severity {
        case .green: return TigerPalette.jade
        case .yellow: return TigerPalette.gold
        case .red: return TigerPalette.coral
        case .gray: return TigerPalette.textMuted
        }
    }
}
