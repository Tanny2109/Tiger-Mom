import SwiftUI

struct ContentView: View {
    var body: some View {
        let appDelegate = NSApp.delegate as! AppDelegate
        let appState = appDelegate.appState

        HStack(spacing: 0) {
            SidebarView(appState: appState, screenCapture: appDelegate.screenCapture)
                .frame(width: 200)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)

            Group {
                switch appState.selectedTab {
                case .dashboard:
                    DashboardView(appState: appState, screenCapture: appDelegate.screenCapture)
                case .chat:
                    ChatView()
                case .activity:
                    ActivityView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0x07070A))
        }
        .background(Color(hex: 0x07070A))
        .preferredColorScheme(.dark)
    }
}

struct SidebarView: View {
    @Bindable var appState: AppState
    let screenCapture: ScreenCapture

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: 0xF59E0B))
                Text("Tiger Mom")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)

            VStack(spacing: 2) {
                ForEach(SidebarTab.allCases) { tab in
                    SidebarItem(
                        tab: tab,
                        isSelected: appState.selectedTab == tab
                    ) {
                        appState.selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Capture status footer
            if appState.isTracking {
                SidebarFooter(appState: appState)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(hex: 0x0E0E14))
    }
}

struct SidebarFooter: View {
    let appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.bottom, 4)

            HStack(spacing: 0) {
                Circle()
                    .fill(appState.isIdle ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)
                    .padding(.trailing, 6)

                if let lastCapture = appState.lastCaptureTime {
                    Text("Last: \(lastCapture.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    Text("No captures yet")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Text("\(appState.captureCountToday) today")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }

            if appState.isIdle {
                Text("Paused — idle")
                    .font(.system(size: 10))
                    .foregroundColor(.orange.opacity(0.6))
            }
        }
    }
}

struct SidebarItem: View {
    let tab: SidebarTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: 0xF59E0B) : .white.opacity(0.5))
                    .frame(width: 20)

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(hex: 0xF59E0B).opacity(0.12) : (isHovered ? Color.white.opacity(0.04) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
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

#Preview {
    ContentView()
}
