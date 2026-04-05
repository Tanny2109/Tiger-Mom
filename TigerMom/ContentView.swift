import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    let screenCapture: ScreenCapture

    var body: some View {
        ZStack {
            TigerAppBackground()

            HStack(spacing: 18) {
                SidebarView(appState: appState, screenCapture: screenCapture)
                    .frame(width: 260)

                contentStage
            }
            .padding(18)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var contentStage: some View {
        TigerPanel(padding: 0, cornerRadius: 34, emphasis: 1.1) {
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.03), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                switch appState.selectedTab {
                case .dashboard:
                    DashboardView(appState: appState, screenCapture: screenCapture)
                case .chat:
                    ChatView(appState: appState)
                case .activity:
                    ActivityView()
                case .settings:
                    SettingsView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SidebarView: View {
    @Bindable var appState: AppState
    let screenCapture: ScreenCapture

    var body: some View {
        TigerPanel(padding: 18, cornerRadius: 30, emphasis: 0.9) {
            VStack(alignment: .leading, spacing: 18) {
                brandHeader
                statusHero
                navigation
                Spacer()
                commandDock
                SidebarFooter(appState: appState)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var brandHeader: some View {
        TigerMarkStrip(size: 44)
    }

    private var statusHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TigerCapsuleBadge(
                    title: appState.isTracking ? "Tracking Live" : "Standby",
                    symbol: appState.isTracking ? "dot.radiowaves.left.and.right" : "pause.fill",
                    tint: appState.isTracking ? TigerPalette.jade : TigerPalette.textSecondary
                )

                Spacer()

                Text("\(appState.focusScore)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Today’s posture")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundColor(TigerPalette.textMuted)

                Text(statusHeadline)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text(statusDetail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            TigerPalette.amber.opacity(0.24),
                            TigerPalette.gold.opacity(0.14),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var navigation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Navigate")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundColor(TigerPalette.textMuted)
                .padding(.horizontal, 6)

            VStack(spacing: 6) {
                ForEach(SidebarTab.allCases) { tab in
                    SidebarItem(
                        tab: tab,
                        isSelected: appState.selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appState.selectedTab = tab
                        }
                    }
                }
            }
        }
    }

    private var commandDock: some View {
        HStack(spacing: 10) {
            SidebarCommandButton(
                title: appState.isTracking ? "Pause" : "Track",
                symbol: appState.isTracking ? "pause.fill" : "record.circle.fill",
                tint: appState.isTracking ? TigerPalette.coral : TigerPalette.jade
            ) {
                appState.isTracking.toggle()
                if appState.isTracking {
                    screenCapture.start(appState: appState)
                } else {
                    screenCapture.stop()
                }
            }

            SidebarCommandButton(
                title: "Chat",
                symbol: "bubble.left.and.bubble.right.fill",
                tint: TigerPalette.gold
            ) {
                appState.selectedTab = .chat
            }
        }
    }

    private var statusHeadline: String {
        if appState.isIdle {
            return "Quiet for now."
        }
        if appState.isTracking {
            return appState.focusScore >= 75 ? "Locked in and visible." : "Still room to tighten up."
        }
        return "Ready when you are."
    }

    private var statusDetail: String {
        if appState.isIdle {
            return "Tiger Mom pauses the pressure when you step away."
        }
        if appState.isTracking {
            return "\(appState.captureCountToday) captures logged today. Keep the streak clean."
        }
        return "Start tracking to fill the timeline, activity log, and report card."
    }
}

struct SidebarFooter: View {
    let appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TigerDivider()

            HStack(spacing: 12) {
                Circle()
                    .fill(appState.isIdle ? TigerPalette.amber : TigerPalette.jade)
                    .frame(width: 9, height: 9)
                    .shadow(color: (appState.isIdle ? TigerPalette.amber : TigerPalette.jade).opacity(0.6), radius: 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.isIdle ? "Paused for idle time" : "Session pulse")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(TigerPalette.textPrimary)

                    Text(lastCaptureText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                }
            }

            Text("\(appState.captureCountToday) captures today")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(TigerPalette.textMuted)
        }
    }

    private var lastCaptureText: String {
        guard let lastCapture = appState.lastCaptureTime else {
            return "No captures yet"
        }
        return "Last seen at \(lastCapture.formatted(date: .omitted, time: .shortened))"
    }
}

struct SidebarItem: View {
    let tab: SidebarTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 34, height: 34)

                    Image(systemName: tab.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                        .foregroundColor(TigerPalette.textPrimary)

                    Text(tab.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                }

                Spacer()

                if isSelected {
                    Circle()
                        .fill(TigerPalette.amber)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var backgroundFill: Color {
        if isSelected { return Color.white.opacity(0.08) }
        if isHovered { return Color.white.opacity(0.04) }
        return .clear
    }

    private var borderColor: Color {
        isSelected ? Color.white.opacity(0.08) : .clear
    }

    private var iconBackground: Color {
        isSelected ? TigerPalette.amber.opacity(0.16) : Color.white.opacity(0.05)
    }

    private var iconColor: Color {
        isSelected ? TigerPalette.amber : TigerPalette.textSecondary
    }
}

struct SidebarCommandButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(tint.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
