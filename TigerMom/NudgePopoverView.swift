import SwiftUI

struct NudgePopoverView: View {
    let nudge: NudgeData
    let onResponse: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Severity color strip
            Rectangle()
                .fill(nudge.severity.color)
                .frame(height: 4)

            VStack(spacing: 16) {
                // Emoji header
                Text(nudge.emoji)
                    .font(.system(size: 40))
                    .padding(.top, 8)

                // Message
                Text(nudge.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 16)

                // Trigger info
                if !nudge.trigger.isEmpty {
                    Text(nudge.trigger)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.05))
                        )
                }

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        onResponse("acknowledged")
                    } label: {
                        Text("OK fine...")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(nudge.severity.color)

                    Button {
                        onResponse("snoozed")
                    } label: {
                        Text("5 more minutes")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
