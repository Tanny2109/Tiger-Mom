import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View

struct SettingsView: View {
    @State private var apiKey = ""
    @State private var apiKeyStatus: ApiKeyStatus = .untested

    @State private var availableModels: [ModelInfo] = []
    @State private var visionModel = ""
    @State private var brainModel = ""

    @State private var screenshotInterval: Double = 120
    @State private var distractionThreshold: Double = 15
    @State private var nudgeCooldown: Double = 30
    @State private var workStart = defaultTime(hour: 9)
    @State private var workEnd = defaultTime(hour: 17)
    @State private var trackOutsideHours = false
    @State private var pauseWhenIdle = true

    @State private var intensity = "medium"
    @State private var enableNudgeSounds = true

    @State private var storeScreenshots = true
    @State private var showClearConfirmation = false

    @State private var launchAtLogin = false
    @State private var showInDock = true
    @State private var startTrackingOnLaunch = false

    @State private var isSaving = false
    @State private var selectedSection: SettingsSection = .api

    var body: some View {
        VStack(spacing: 0) {
            // Header
            settingsHeader
                .padding(.horizontal, TigerSpacing.xxl)
                .padding(.top, TigerSpacing.xxl)
                .padding(.bottom, TigerSpacing.lg)
            
            // Tab bar
            sectionTabs
                .padding(.horizontal, TigerSpacing.xxl)
                .padding(.bottom, TigerSpacing.lg)
            
            // Content
            ScrollView(.vertical, showsIndicators: false) {
                sectionContent
                    .padding(.horizontal, TigerSpacing.xxl)
                    .padding(.bottom, TigerSpacing.xxl)
            }
        }
        .task {
            await loadSettings()
            await loadModels()
        }
    }

    // MARK: - Header
    
    private var settingsHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                Text("Settings")
                    .font(TigerTypography.headline)
                    .foregroundColor(TigerPalette.textPrimary)
                
                Text("Configure models, tracking, and preferences")
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textSecondary)
            }
            
            Spacer()
            
            TigerCapsuleBadge(
                title: isSaving ? "Saving..." : "Synced",
                symbol: isSaving ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill",
                tint: isSaving ? TigerPalette.gold : TigerPalette.jade
            )
        }
    }

    // MARK: - Section Tabs
    
    private var sectionTabs: some View {
        HStack(spacing: TigerSpacing.sm) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                SettingsTab(
                    title: section.title,
                    icon: section.icon,
                    isSelected: selectedSection == section
                ) {
                    withAnimation(.tigerSpring) {
                        selectedSection = section
                    }
                }
            }
            
            Spacer()
        }
    }

    // MARK: - Section Content
    
    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .api:
            VStack(spacing: TigerSpacing.lg) {
                apiConfigSection
                modelSelectionSection
            }
        case .tracking:
            trackingSection
        case .personality:
            personalitySection
        case .privacy:
            dataPrivacySection
        case .app:
            VStack(spacing: TigerSpacing.lg) {
                appBehaviorSection
                aboutSection
            }
        }
    }

    // MARK: - API Config Section
    
    private var apiConfigSection: some View {
        SettingsCard(title: "API Credentials", icon: "key.horizontal.fill") {
            VStack(alignment: .leading, spacing: TigerSpacing.md) {
                SettingsLabel("OpenRouter API Key")

                HStack(spacing: TigerSpacing.sm) {
                    SecureField("sk-or-...", text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(TigerPalette.textPrimary)
                        .tigerInsetField()
                        .onChange(of: apiKey) { apiKeyStatus = .untested }

                    Button {
                        Task { await testApiKey() }
                    } label: {
                        HStack(spacing: TigerSpacing.xs) {
                            statusIcon
                            Text("Test")
                                .font(TigerTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(TigerPalette.textPrimary)
                        .padding(.horizontal, TigerSpacing.md)
                        .padding(.vertical, TigerSpacing.sm + 2)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(TigerPalette.surfaceElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(TigerPalette.border, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    NSWorkspace.shared.open(URL(string: "https://openrouter.ai/keys")!)
                } label: {
                    Label("Open key manager", systemImage: "arrow.up.right.square.fill")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.gold)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch apiKeyStatus {
        case .untested:
            Image(systemName: "questionmark.circle")
                .foregroundColor(TigerPalette.textMuted)
        case .testing:
            ProgressView()
                .scaleEffect(0.5)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(TigerPalette.jade)
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(TigerPalette.coral)
        }
    }

    // MARK: - Model Selection Section
    
    private var modelSelectionSection: some View {
        SettingsCard(title: "Models", icon: "cpu.fill") {
            VStack(spacing: TigerSpacing.md) {
                SettingsPickerBlock(title: "Vision Model", selection: $visionModel, models: availableModels, onChange: saveSettings)
                SettingsPickerBlock(title: "Brain Model", selection: $brainModel, models: availableModels, onChange: saveSettings)
            }
        }
    }

    // MARK: - Tracking Section
    
    private var trackingSection: some View {
        SettingsCard(title: "Tracking", icon: "camera.aperture") {
            VStack(spacing: TigerSpacing.lg) {
                SettingsSlider(
                    label: "Screenshot interval",
                    value: $screenshotInterval,
                    range: 60...300,
                    step: 10,
                    format: { "\(Int($0)) sec" },
                    onChange: saveSettings
                )

                SettingsSlider(
                    label: "Distraction threshold",
                    value: $distractionThreshold,
                    range: 5...30,
                    step: 1,
                    format: { "\(Int($0)) min" },
                    onChange: saveSettings
                )

                SettingsSlider(
                    label: "Nudge cooldown",
                    value: $nudgeCooldown,
                    range: 10...60,
                    step: 5,
                    format: { "\(Int($0)) min" },
                    onChange: saveSettings
                )

                TigerDivider()

                HStack(spacing: TigerSpacing.lg) {
                    SettingsTimeField(title: "Work starts", selection: $workStart, onChange: saveSettings)
                    SettingsTimeField(title: "Work ends", selection: $workEnd, onChange: saveSettings)
                }

                SettingsToggle(label: "Track outside work hours", isOn: $trackOutsideHours, onChange: saveSettings)
                SettingsToggle(label: "Pause when idle", isOn: $pauseWhenIdle, onChange: saveSettings)
            }
        }
    }

    // MARK: - Personality Section
    
    private var personalitySection: some View {
        SettingsCard(title: "Tiger Mom Voice", icon: "theatermasks.fill") {
            VStack(alignment: .leading, spacing: TigerSpacing.md) {
                SettingsLabel("Intensity")

                Picker("", selection: $intensity) {
                    Text("Gentle").tag("gentle")
                    Text("Medium").tag("medium")
                    Text("Fierce").tag("fierce")
                }
                .pickerStyle(.segmented)
                .onChange(of: intensity) { saveSettings() }

                Text(intensityPreview)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(TigerPalette.textPrimary)
                    .lineSpacing(4)
                    .padding(TigerSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TigerPalette.backgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(TigerPalette.border, lineWidth: 1)
                            )
                    )

                SettingsToggle(label: "Enable nudge sounds", isOn: $enableNudgeSounds, onChange: saveSettings)
            }
        }
    }

    private var intensityPreview: String {
        switch intensity {
        case "gentle": return "\"Hey, you've been drifting a little. Let's tighten the next block.\""
        case "fierce": return "\"Twenty-five minutes on Reddit? Explain yourself. Close it now.\""
        default: return "\"You're not doomed, but this day could be sharper. Give me one clean hour.\""
        }
    }

    // MARK: - Data Privacy Section
    
    private var dataPrivacySection: some View {
        SettingsCard(title: "Data & Privacy", icon: "lock.shield.fill") {
            VStack(alignment: .leading, spacing: TigerSpacing.md) {
                HStack(spacing: TigerSpacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(TigerPalette.jade)

                    Text("All data stays on your Mac unless a model call needs it.")
                        .font(TigerTypography.bodySmall)
                        .foregroundColor(TigerPalette.textSecondary)
                }

                SettingsToggle(label: "Store screenshots locally", isOn: $storeScreenshots, onChange: saveSettings)

                TigerDivider()

                HStack(spacing: TigerSpacing.sm) {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                            .font(TigerTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(TigerPalette.coral)
                            .padding(.horizontal, TigerSpacing.md)
                            .padding(.vertical, TigerSpacing.sm + 2)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(TigerPalette.coral.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(TigerPalette.coral.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear", role: .destructive) {
                            Task { await clearData() }
                        }
                    } message: {
                        Text("This will delete activities, screenshots, nudges, and chat history.")
                    }

                    Button {
                        Task { await exportData() }
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up.fill")
                            .font(TigerTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(TigerPalette.textPrimary)
                            .padding(.horizontal, TigerSpacing.md)
                            .padding(.vertical, TigerSpacing.sm + 2)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(TigerPalette.surfaceElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - App Behavior Section
    
    private var appBehaviorSection: some View {
        SettingsCard(title: "App Behavior", icon: "switch.2") {
            VStack(spacing: TigerSpacing.md) {
                SettingsToggle(label: "Launch at login", isOn: $launchAtLogin, onChange: saveSettings)
                SettingsToggle(label: "Show in Dock", isOn: $showInDock, onChange: saveSettings)
                SettingsToggle(label: "Start tracking on launch", isOn: $startTrackingOnLaunch, onChange: saveSettings)
            }
        }
    }

    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsCard(title: "About", icon: "seal.fill") {
            VStack(alignment: .leading, spacing: TigerSpacing.sm) {
                HStack {
                    Text("Tiger Mom")
                        .font(TigerTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(TigerPalette.textPrimary)
                    Spacer()
                    Text("v1.0.0")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textMuted)
                }

                Text("An AI-powered productivity monitor that watches your screen, interprets your behavior, and gives you sharp, contextual coaching.")
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Data Loading
    
    private func loadSettings() async {
        do {
            let s = try await APIClient.shared.getSettings()
            apiKey = s["api_key"] as? String ?? ""
            visionModel = s["vision_model"] as? String ?? ""
            brainModel = s["brain_model"] as? String ?? ""
            screenshotInterval = s["screenshot_interval"] as? Double ?? 120
            distractionThreshold = s["distraction_threshold"] as? Double ?? 15
            nudgeCooldown = s["nudge_cooldown"] as? Double ?? 30
            trackOutsideHours = s["track_outside_hours"] as? Bool ?? false
            pauseWhenIdle = s["pause_when_idle"] as? Bool ?? true
            intensity = s["intensity"] as? String ?? "medium"
            enableNudgeSounds = s["enable_nudge_sounds"] as? Bool ?? true
            storeScreenshots = s["store_screenshots"] as? Bool ?? true
            launchAtLogin = s["launch_at_login"] as? Bool ?? false
            showInDock = s["show_in_dock"] as? Bool ?? true
            startTrackingOnLaunch = s["start_tracking_on_launch"] as? Bool ?? false

            if let startHour = s["work_start_hour"] as? Int {
                workStart = Self.defaultTime(hour: startHour)
            }
            if let endHour = s["work_end_hour"] as? Int {
                workEnd = Self.defaultTime(hour: endHour)
            }
        } catch {}
    }

    private func loadModels() async {
        do {
            let response = try await APIClient.shared.availableModels()
            if let models = response["models"] as? [[String: Any]] {
                availableModels = models.compactMap { model in
                    guard let id = model["id"] as? String,
                          let name = model["name"] as? String else { return nil }
                    return ModelInfo(id: id, name: name, price: model["price"] as? String ?? "")
                }
            }
        } catch {}
    }

    private func saveSettings() {
        guard !isSaving else { return }
        isSaving = true

        Task {
            let startHour = Calendar.current.component(.hour, from: workStart)
            let endHour = Calendar.current.component(.hour, from: workEnd)
            let body: [String: Any] = [
                "api_key": apiKey,
                "vision_model": visionModel,
                "brain_model": brainModel,
                "screenshot_interval": screenshotInterval,
                "distraction_threshold": distractionThreshold,
                "nudge_cooldown": nudgeCooldown,
                "work_start_hour": startHour,
                "work_end_hour": endHour,
                "track_outside_hours": trackOutsideHours,
                "pause_when_idle": pauseWhenIdle,
                "intensity": intensity,
                "enable_nudge_sounds": enableNudgeSounds,
                "store_screenshots": storeScreenshots,
                "launch_at_login": launchAtLogin,
                "show_in_dock": showInDock,
                "start_tracking_on_launch": startTrackingOnLaunch
            ]
            _ = try? await APIClient.shared.updateSettings(body: body)
            isSaving = false
        }
    }

    private func testApiKey() async {
        apiKeyStatus = .testing
        do {
            let response = try await APIClient.shared.testApiKey(key: apiKey)
            apiKeyStatus = (response["valid"] as? Bool ?? false) ? .valid : .invalid
        } catch {
            apiKeyStatus = .invalid
        }
    }

    private func clearData() async {
        _ = try? await APIClient.shared.clearData()
    }

    private func exportData() async {
        do {
            let response = try await APIClient.shared.exportData()
            if let jsonData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted) {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "tiger-mom-export.json"
                if panel.runModal() == .OK, let url = panel.url {
                    try jsonData.write(to: url)
                }
            }
        } catch {}
    }

    static func defaultTime(hour: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: 0)) ?? Date()
    }
}

// MARK: - Settings Section Enum

enum SettingsSection: CaseIterable {
    case api, tracking, personality, privacy, app
    
    var title: String {
        switch self {
        case .api: return "API"
        case .tracking: return "Tracking"
        case .personality: return "Voice"
        case .privacy: return "Privacy"
        case .app: return "App"
        }
    }
    
    var icon: String {
        switch self {
        case .api: return "key.horizontal.fill"
        case .tracking: return "camera.aperture"
        case .personality: return "theatermasks.fill"
        case .privacy: return "lock.shield.fill"
        case .app: return "switch.2"
        }
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: TigerSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(TigerTypography.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? TigerPalette.gold : TigerPalette.textSecondary)
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? TigerPalette.gold.opacity(0.12) : (isHovered ? TigerPalette.surfaceHover : .clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(isSelected ? TigerPalette.gold.opacity(0.15) : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.tigerQuick, value: isHovered)
    }
}

// MARK: - Supporting Types

enum ApiKeyStatus {
    case untested, testing, valid, invalid
}

struct ModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let price: String
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.lg) {
            HStack(spacing: TigerSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(TigerPalette.gold)

                Text(title)
                    .font(TigerTypography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(TigerPalette.textPrimary)
            }

            content()
        }
        .padding(TigerSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TigerPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(TigerPalette.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Label

struct SettingsLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(TigerTypography.overline)
            .tracking(1)
            .foregroundColor(TigerPalette.textMuted)
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(TigerTypography.bodySmall)
                .foregroundColor(TigerPalette.textPrimary)
        }
        .toggleStyle(.switch)
        .tint(TigerPalette.gold)
        .onChange(of: isOn) { onChange() }
    }
}

// MARK: - Settings Slider

struct SettingsSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            HStack {
                Text(label)
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textPrimary)
                Spacer()
                Text(format(value))
                    .font(TigerTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(TigerPalette.gold)
            }
            Slider(value: $value, in: range, step: step)
                .tint(TigerPalette.gold)
                .onChange(of: value) { onChange() }
        }
    }
}

// MARK: - Settings Picker Block

struct SettingsPickerBlock: View {
    let title: String
    @Binding var selection: String
    let models: [ModelInfo]
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            SettingsLabel(title)

            Picker("", selection: $selection) {
                Text("Select a model").tag("")
                ForEach(models) { model in
                    Text(model.price.isEmpty ? model.name : "\(model.name) / \(model.price)")
                        .tag(model.id)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .tigerInsetField()
            .onChange(of: selection) { onChange() }
        }
    }
}

// MARK: - Settings Time Field

struct SettingsTimeField: View {
    let title: String
    @Binding var selection: Date
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            SettingsLabel(title)
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .tigerInsetField()
                .onChange(of: selection) { onChange() }
        }
    }
}
