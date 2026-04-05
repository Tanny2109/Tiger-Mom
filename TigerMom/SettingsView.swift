import SwiftUI
import UniformTypeIdentifiers

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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                header

                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 20) {
                        apiConfigSection
                        modelSelectionSection
                        personalitySection
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 20) {
                        trackingSection
                        dataPrivacySection
                        appBehaviorSection
                        aboutSection
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .task {
            await loadSettings()
            await loadModels()
        }
    }

    private var header: some View {
        TigerPanel(padding: 24, cornerRadius: 28, emphasis: 1.08) {
            HStack(alignment: .top, spacing: 18) {
                TigerSectionHeader(
                    eyebrow: "Configuration",
                    title: "Settings",
                    detail: "Tune models, timing, tone, and privacy without leaving the app."
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    TigerCapsuleBadge(title: isSaving ? "Saving" : "Live Sync", symbol: isSaving ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill", tint: isSaving ? TigerPalette.gold : TigerPalette.jade)
                    Text("Changes sync to the sidecar as you go.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                }
            }
        }
    }

    private var apiConfigSection: some View {
        SettingsCard(title: "API Credentials", icon: "key.horizontal.fill", detail: "Connect the app to your model layer.") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsLabel("OpenRouter API Key")

                HStack(spacing: 10) {
                    SecureField("sk-or-...", text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(TigerPalette.textPrimary)
                        .tigerInsetField()
                        .onChange(of: apiKey) { apiKeyStatus = .untested }

                    Button {
                        Task { await testApiKey() }
                    } label: {
                        HStack(spacing: 6) {
                            statusIcon
                            Text("Test Key")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(TigerPalette.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    NSWorkspace.shared.open(URL(string: "https://openrouter.ai/keys")!)
                } label: {
                    Label("Open key manager", systemImage: "arrow.up.right.square.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
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
                .scaleEffect(0.55)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(TigerPalette.jade)
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(TigerPalette.coral)
        }
    }

    private var modelSelectionSection: some View {
        SettingsCard(title: "Models", icon: "cpu.fill", detail: "Choose the visual and conversational engines.") {
            VStack(spacing: 14) {
                SettingsPickerBlock(title: "Vision Model", selection: $visionModel, models: availableModels, onChange: saveSettings)
                SettingsPickerBlock(title: "Brain Model", selection: $brainModel, models: availableModels, onChange: saveSettings)
            }
        }
    }

    private var trackingSection: some View {
        SettingsCard(title: "Tracking", icon: "camera.aperture", detail: "Control cadence, thresholds, and working hours.") {
            VStack(spacing: 16) {
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

                HStack(spacing: 14) {
                    SettingsTimeField(title: "Work starts", selection: $workStart, onChange: saveSettings)
                    SettingsTimeField(title: "Work ends", selection: $workEnd, onChange: saveSettings)
                }

                SettingsToggle(label: "Track outside work hours", isOn: $trackOutsideHours, onChange: saveSettings)
                SettingsToggle(label: "Pause when idle", isOn: $pauseWhenIdle, onChange: saveSettings)
            }
        }
    }

    private var personalitySection: some View {
        SettingsCard(title: "Tiger Mom Voice", icon: "theatermasks.fill", detail: "Adjust the emotional temperature of the coaching.") {
            VStack(alignment: .leading, spacing: 14) {
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
                    .foregroundColor(TigerPalette.textPrimary)
                    .lineSpacing(4)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                            )
                    )

                SettingsToggle(label: "Enable nudge sounds", isOn: $enableNudgeSounds, onChange: saveSettings)
            }
        }
    }

    private var intensityPreview: String {
        switch intensity {
        case "gentle": return "“Hey, you’ve been drifting a little. Let’s tighten the next block and make it count.”"
        case "fierce": return "“Twenty-five minutes on Reddit? Explain yourself later. Close it now and return to work.”"
        default: return "“You’re not doomed, but this day could be sharper. Reset and give me one clean hour.”"
        }
    }

    private var dataPrivacySection: some View {
        SettingsCard(title: "Data & Privacy", icon: "lock.shield.fill", detail: "Local-first controls for what gets stored and exported.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(TigerPalette.jade)

                    Text("All activity data stays on your Mac unless a model call needs it.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    SettingsLabel("Screenshot storage path")
                    Text("/Users/tanmay/Projects/TigerMom/screenshots")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(TigerPalette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        )
                }

                SettingsToggle(label: "Store screenshots", isOn: $storeScreenshots, onChange: saveSettings)

                TigerDivider()

                HStack(spacing: 10) {
                    destructiveButton(title: "Clear All Data", symbol: "trash.fill") {
                        showClearConfirmation = true
                    }
                    .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear", role: .destructive) {
                            Task { await clearData() }
                        }
                    } message: {
                        Text("This will delete activities, screenshots, nudges, and chat history.")
                    }

                    neutralButton(title: "Export JSON", symbol: "square.and.arrow.up.fill") {
                        Task { await exportData() }
                    }
                }
            }
        }
    }

    private var appBehaviorSection: some View {
        SettingsCard(title: "App Behavior", icon: "switch.2", detail: "How the app fits into your desktop routine.") {
            VStack(spacing: 12) {
                SettingsToggle(label: "Launch at login", isOn: $launchAtLogin, onChange: saveSettings)
                SettingsToggle(label: "Show in Dock", isOn: $showInDock, onChange: saveSettings)
                SettingsToggle(label: "Start tracking on launch", isOn: $startTrackingOnLaunch, onChange: saveSettings)
            }
        }
    }

    private var aboutSection: some View {
        SettingsCard(title: "About", icon: "seal.fill", detail: "A polished local companion for focus and accountability.") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tiger Mom")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(TigerPalette.textPrimary)
                    Spacer()
                    Text("v1.0.0")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(TigerPalette.textMuted)
                }

                Text("An AI-powered productivity monitor that watches your screen, interprets your behavior, and gives you sharp, contextual coaching in real time.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
                    .lineSpacing(4)
            }
        }
    }

    private func destructiveButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(TigerPalette.coral)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TigerPalette.coral.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(TigerPalette.coral.opacity(0.18), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func neutralButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(TigerPalette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

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

enum ApiKeyStatus {
    case untested, testing, valid, invalid
}

struct ModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let price: String
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let detail: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        TigerPanel(padding: 22, cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(TigerPalette.gold.opacity(0.12))
                            .frame(width: 34, height: 34)

                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(TigerPalette.gold)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(TigerPalette.textPrimary)
                        Text(detail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TigerPalette.textSecondary)
                    }
                }

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SettingsLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundColor(TigerPalette.textMuted)
    }
}

struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(TigerPalette.textPrimary)
        }
        .toggleStyle(.switch)
        .tint(TigerPalette.gold)
        .onChange(of: isOn) { onChange() }
    }
}

struct SettingsSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TigerPalette.textPrimary)
                Spacer()
                Text(format(value))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.gold)
            }
            Slider(value: $value, in: range, step: step)
                .tint(TigerPalette.gold)
                .onChange(of: value) { onChange() }
        }
    }
}

struct SettingsPickerBlock: View {
    let title: String
    @Binding var selection: String
    let models: [ModelInfo]
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsLabel(title)

            Picker("", selection: $selection) {
                Text("Select a model").tag("")
                ForEach(models) { model in
                    Text(model.price.isEmpty ? model.name : "\(model.name) • \(model.price)")
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

struct SettingsTimeField: View {
    let title: String
    @Binding var selection: Date
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsLabel(title)
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .tigerInsetField()
                .onChange(of: selection) { onChange() }
        }
    }
}
