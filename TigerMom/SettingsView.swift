import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View

struct SettingsView: View {
    // API
    @State private var apiKey = ""
    @State private var apiKeyStatus: ApiKeyStatus = .untested

    // Models
    @State private var availableModels: [ModelInfo] = []
    @State private var visionModel = ""
    @State private var brainModel = ""

    // Tracking
    @State private var screenshotInterval: Double = 120
    @State private var distractionThreshold: Double = 15
    @State private var nudgeCooldown: Double = 30
    @State private var workStart = defaultTime(hour: 9)
    @State private var workEnd = defaultTime(hour: 17)
    @State private var trackOutsideHours = false
    @State private var pauseWhenIdle = true

    // Personality
    @State private var intensity = "medium"
    @State private var enableNudgeSounds = true

    // Data
    @State private var storeScreenshots = true
    @State private var showClearConfirmation = false

    // App Behavior
    @State private var launchAtLogin = false
    @State private var showInDock = true
    @State private var startTrackingOnLaunch = false

    @State private var isSaving = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.bottom, 4)

                apiConfigSection
                modelSelectionSection
                trackingSection
                personalitySection
                dataPrivacySection
                appBehaviorSection
                aboutSection
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .background(Color(hex: 0x07070A))
        .task {
            await loadSettings()
            await loadModels()
        }
    }

    // MARK: - 1. API Configuration

    private var apiConfigSection: some View {
        SettingsSection(title: "API Configuration", icon: "key.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenRouter API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                HStack(spacing: 8) {
                    SecureField("sk-or-...", text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                        .onChange(of: apiKey) {
                            apiKeyStatus = .untested
                        }

                    Button {
                        Task { await testApiKey() }
                    } label: {
                        HStack(spacing: 4) {
                            statusIcon
                            Text("Test")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    NSWorkspace.shared.open(URL(string: "https://openrouter.ai/keys")!)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                        Text("Get API Key")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: 0xF59E0B).opacity(0.7))
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
                .foregroundColor(.white.opacity(0.3))
                .font(.system(size: 12))
        case .testing:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 14, height: 14)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 12))
        }
    }

    // MARK: - 2. Model Selection

    private var modelSelectionSection: some View {
        SettingsSection(title: "Model Selection", icon: "cpu") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vision Model")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    ModelPicker(selection: $visionModel, models: availableModels, onChange: saveSettings)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Brain Model")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    ModelPicker(selection: $brainModel, models: availableModels, onChange: saveSettings)
                }
            }
        }
    }

    // MARK: - 3. Tracking

    private var trackingSection: some View {
        SettingsSection(title: "Tracking", icon: "camera.viewfinder") {
            VStack(spacing: 14) {
                SettingsSlider(
                    label: "Screenshot interval",
                    value: $screenshotInterval,
                    range: 60...300,
                    step: 10,
                    format: { "\(Int($0))s" },
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

                Divider().opacity(0.1)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Work hours start")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        DatePicker("", selection: $workStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: workStart) { saveSettings() }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Work hours end")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        DatePicker("", selection: $workEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: workEnd) { saveSettings() }
                    }
                }

                SettingsToggle(label: "Track outside work hours", isOn: $trackOutsideHours, onChange: saveSettings)
                SettingsToggle(label: "Pause when idle", isOn: $pauseWhenIdle, onChange: saveSettings)
            }
        }
    }

    // MARK: - 4. Personality

    private var personalitySection: some View {
        SettingsSection(title: "Tiger Mom Personality", icon: "theatermask.and.paintbrush") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Intensity")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Picker("", selection: $intensity) {
                    Text("Gentle").tag("gentle")
                    Text("Medium").tag("medium")
                    Text("Fierce").tag("fierce")
                }
                .pickerStyle(.segmented)
                .onChange(of: intensity) { saveSettings() }

                // Preview
                Text(intensityPreview)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.4))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))

                SettingsToggle(label: "Enable nudge sounds", isOn: $enableNudgeSounds, onChange: saveSettings)
            }
        }
    }

    private var intensityPreview: String {
        switch intensity {
        case "gentle": return "\"Hey, you've been on Reddit for a bit. Maybe take a break? 💛\""
        case "fierce": return "\"25 MINUTES on Reddit?! Do you think success comes from scrolling?! GET BACK TO WORK. 🐯\""
        default: return "\"You've spent 25 min on Reddit. Tiger Mom is not impressed. Time to refocus. 🐯\""
        }
    }

    // MARK: - 5. Data & Privacy

    private var dataPrivacySection: some View {
        SettingsSection(title: "Data & Privacy", icon: "lock.shield") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green.opacity(0.6))
                        .font(.system(size: 14))
                    Text("All data is stored locally on your Mac")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Screenshots stored at:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                    Text("~/projects/tiger-eye/screenshots/")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }

                SettingsToggle(label: "Store screenshots", isOn: $storeScreenshots, onChange: saveSettings)

                Divider().opacity(0.1)

                HStack(spacing: 12) {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Clear All Data")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear", role: .destructive) {
                            Task { await clearData() }
                        }
                    } message: {
                        Text("This will delete all activities, screenshots, and chat history. This cannot be undone.")
                    }

                    Button {
                        Task { await exportData() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                            Text("Export JSON")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 6. App Behavior

    private var appBehaviorSection: some View {
        SettingsSection(title: "App Behavior", icon: "gearshape.2") {
            VStack(spacing: 10) {
                SettingsToggle(label: "Launch at login", isOn: $launchAtLogin, onChange: saveSettings)
                SettingsToggle(label: "Show in Dock", isOn: $showInDock, onChange: saveSettings)
                SettingsToggle(label: "Start tracking on launch", isOn: $startTrackingOnLaunch, onChange: saveSettings)
            }
        }
    }

    // MARK: - 7. About

    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tiger Mom")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("v1.0.0")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }

                Text("An AI-powered productivity monitor that watches your screen and gives you real-time coaching — like having a Tiger Mom looking over your shoulder.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
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
        } catch {
            // Use defaults
        }
    }

    private func loadModels() async {
        do {
            let response = try await APIClient.shared.availableModels()
            if let models = response["models"] as? [[String: Any]] {
                availableModels = models.compactMap { m in
                    guard let id = m["id"] as? String,
                          let name = m["name"] as? String else { return nil }
                    let price = m["price"] as? String ?? ""
                    return ModelInfo(id: id, name: name, price: price)
                }
            }
        } catch {
            // No models available
        }
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
            let valid = response["valid"] as? Bool ?? false
            apiKeyStatus = valid ? .valid : .invalid
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
        } catch {
            // Export failed
        }
    }

    static func defaultTime(hour: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: 0)) ?? Date()
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

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0xF59E0B).opacity(0.6))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                )
        )
    }
}

struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
        .toggleStyle(.switch)
        .tint(Color(hex: 0xF59E0B))
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(format(value))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: 0xF59E0B).opacity(0.8))
            }
            Slider(value: $value, in: range, step: step)
                .tint(Color(hex: 0xF59E0B))
                .onChange(of: value) { onChange() }
        }
    }
}

struct ModelPicker: View {
    @Binding var selection: String
    let models: [ModelInfo]
    let onChange: () -> Void

    var body: some View {
        Picker("", selection: $selection) {
            Text("Select a model").tag("")
            ForEach(models) { model in
                HStack {
                    Text(model.name)
                    if !model.price.isEmpty {
                        Text("(\(model.price))")
                            .foregroundColor(.secondary)
                    }
                }
                .tag(model.id)
            }
        }
        .labelsHidden()
        .onChange(of: selection) { onChange() }
    }
}
