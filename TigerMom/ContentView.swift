import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    let screenCapture: ScreenCapture

    var body: some View {
        ZStack {
            TigerAppBackground()

            HStack(spacing: TigerSpacing.lg) {
                SidebarView(appState: appState, screenCapture: screenCapture)
                    .frame(width: 240)

                contentStage
            }
            .padding(TigerSpacing.lg)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var contentStage: some View {
        TigerPanel(padding: 0, cornerRadius: 20, emphasis: 1.0) {
            ZStack {
                TigerPalette.surface.opacity(0.3)

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
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Bindable var appState: AppState
    let screenCapture: ScreenCapture

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with brand and status
            sidebarHeader
            
            Spacer().frame(height: TigerSpacing.xl)
            
            // Navigation sections
            navigationSections
            
            Spacer()
            
            // Quick actions
            quickActions
            
            Spacer().frame(height: TigerSpacing.lg)
            
            // Footer status
            sidebarFooter
        }
        .padding(TigerSpacing.lg)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TigerPalette.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(TigerPalette.border, lineWidth: 1)
                )
        )
    }

    // MARK: - Header
    
    private var sidebarHeader: some View {
        HStack(spacing: TigerSpacing.md) {
            TigerMark(size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Tiger Mom")
                    .font(TigerTypography.title)
                    .foregroundColor(TigerPalette.textPrimary)
                
                HStack(spacing: TigerSpacing.xs) {
                    Circle()
                        .fill(appState.isTracking ? TigerPalette.jade : TigerPalette.textMuted)
                        .frame(width: 6, height: 6)
                    
                    Text(appState.isTracking ? "Tracking" : "Standby")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textSecondary)
                }
            }
            
            Spacer()
            
            // Focus score badge
            Text("\(appState.focusScore)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(TigerPalette.gold)
        }
    }

    // MARK: - Navigation Sections
    
    private var navigationSections: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            // Overview Section
            TigerSectionLabel(title: "Overview")
            
            TigerNavItem(
                icon: "chart.bar.fill",
                label: "Dashboard",
                isSelected: appState.selectedTab == .dashboard
            ) {
                withAnimation(.tigerSpring) {
                    appState.selectedTab = .dashboard
                }
            }
            
            // Tools Section
            TigerSectionLabel(title: "Tools")
            
            TigerNavItem(
                icon: "bubble.left.and.bubble.right.fill",
                label: "Chat",
                isSelected: appState.selectedTab == .chat
            ) {
                withAnimation(.tigerSpring) {
                    appState.selectedTab = .chat
                }
            }
            
            TigerNavItem(
                icon: "list.bullet.rectangle.fill",
                label: "Activity",
                isSelected: appState.selectedTab == .activity
            ) {
                withAnimation(.tigerSpring) {
                    appState.selectedTab = .activity
                }
            }
            
            // System Section
            TigerSectionLabel(title: "System")
            
            TigerNavItem(
                icon: "gear",
                label: "Settings",
                isSelected: appState.selectedTab == .settings
            ) {
                withAnimation(.tigerSpring) {
                    appState.selectedTab = .settings
                }
            }
        }
    }

    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(spacing: TigerSpacing.sm) {
            TigerDivider()
            
            Spacer().frame(height: TigerSpacing.sm)
            
            // Primary tracking toggle
            Button {
                withAnimation(.tigerSpring) {
                    appState.isTracking.toggle()
                    if appState.isTracking {
                        screenCapture.start(appState: appState)
                    } else {
                        screenCapture.stop()
                    }
                }
            } label: {
                HStack(spacing: TigerSpacing.sm) {
                    Image(systemName: appState.isTracking ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                    
                    Text(appState.isTracking ? "Pause Tracking" : "Start Tracking")
                        .font(TigerTypography.bodySmall)
                        .fontWeight(.semibold)
                }
                .foregroundColor(appState.isTracking ? TigerPalette.coral : TigerPalette.jade)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TigerSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((appState.isTracking ? TigerPalette.coral : TigerPalette.jade).opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder((appState.isTracking ? TigerPalette.coral : TigerPalette.jade).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer
    
    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            TigerDivider()
            
            Spacer().frame(height: TigerSpacing.xs)
            
            HStack(spacing: TigerSpacing.sm) {
                Circle()
                    .fill(appState.isIdle ? TigerPalette.amber : TigerPalette.jade)
                    .frame(width: 8, height: 8)
                    .shadow(color: (appState.isIdle ? TigerPalette.amber : TigerPalette.jade).opacity(0.5), radius: 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isIdle ? "Idle detected" : "Active session")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textPrimary)
                    
                    Text(lastCaptureText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(TigerPalette.textMuted)
                }
                
                Spacer()
                
                Text("\(appState.captureCountToday)")
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textMuted)
                    .padding(.horizontal, TigerSpacing.sm)
                    .padding(.vertical, TigerSpacing.xs)
                    .background(
                        Capsule()
                            .fill(TigerPalette.surfaceHover)
                    )
            }
        }
    }
    
    private var lastCaptureText: String {
        guard let lastCapture = appState.lastCaptureTime else {
            return "No captures yet"
        }
        return "Last: \(lastCapture.formatted(date: .omitted, time: .shortened))"
    }
}
