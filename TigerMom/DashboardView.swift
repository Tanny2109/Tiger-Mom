import SwiftUI

struct DashboardView: View {
    let appState: AppState
    let screenCapture: ScreenCapture

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Dashboard")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()

                // Tracking toggle
                Button {
                    appState.isTracking.toggle()
                    if appState.isTracking {
                        screenCapture.start(appState: appState)
                    } else {
                        screenCapture.stop()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.isTracking ? Color.green : Color.red.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Text(appState.isTracking ? "Tracking" : "Paused")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Screen recording permission banner
            if !appState.hasScreenRecordingPermission {
                PermissionBanner {
                    screenCapture.requestPermission()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }

            // Placeholder content
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: 0xF59E0B).opacity(0.3))
                Text("Dashboard")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("Focus metrics and activity overview will appear here.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct PermissionBanner: View {
    let onGrantAccess: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xF59E0B))

            VStack(alignment: .leading, spacing: 2) {
                Text("Screen Recording Permission Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("Tiger Mom needs screen access to track your activity.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button("Grant Access") {
                onGrantAccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0xF59E0B))
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0xF59E0B).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(hex: 0xF59E0B).opacity(0.2), lineWidth: 1)
                )
        )
    }
}
