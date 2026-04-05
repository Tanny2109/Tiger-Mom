import SwiftUI

struct NudgePopoverView: View {
    let nudge: NudgeData
    let onResponse: (String) -> Void

    var body: some View {
        ZStack {
            TigerAppBackground()

            TigerPanel(padding: 0, cornerRadius: 24, emphasis: 1.0) {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [nudge.severity.color.opacity(0.26), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 48)
                        .overlay(alignment: .topLeading) {
                            TigerCapsuleBadge(title: severityTitle, symbol: "bell.badge.fill", tint: nudge.severity.color)
                                .padding(14)
                        }

                    VStack(spacing: 16) {
                        TigerMark(size: 56)

                        Text(nudge.message)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(TigerPalette.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 18)

                        if !nudge.trigger.isEmpty {
                            Text(nudge.trigger)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(TigerPalette.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.035))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                                        )
                                )
                        }

                        HStack(spacing: 10) {
                            Button {
                                onResponse("acknowledged")
                            } label: {
                                Text("OK fine...")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(TigerButtonStyle(tint: nudge.severity.color, prominence: .secondary))

                            Button {
                                onResponse("snoozed")
                            } label: {
                                Text("5 more minutes")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(TigerButtonStyle(tint: TigerPalette.textPrimary, prominence: .quiet))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .padding(.bottom, 18)
                }
            }
        }
        .frame(width: 336)
        .preferredColorScheme(.dark)
    }

    private var severityTitle: String {
        nudge.severity.rawValue.capitalized
    }
}
