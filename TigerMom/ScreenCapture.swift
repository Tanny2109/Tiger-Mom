import ScreenCaptureKit
import AppKit

@Observable
class ScreenCapture {
    private var timer: Timer?
    private var idleCheckTimer: Timer?
    private let idleThreshold: TimeInterval = 300 // 5 minutes
    private weak var appState: AppState?

    func start(appState: AppState) {
        self.appState = appState
        checkPermission()
        startCaptureTimer()
        startIdleDetection()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        idleCheckTimer?.invalidate()
        idleCheckTimer = nil
    }

    // MARK: - Permission

    private func checkPermission() {
        Task {
            do {
                // Attempting to get shareable content will trigger the permission dialog
                // if not already granted, or succeed silently if granted
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                appState?.hasScreenRecordingPermission = true
            } catch {
                appState?.hasScreenRecordingPermission = false
            }
        }
    }

    func requestPermission() {
        // Open System Settings > Privacy > Screen Recording
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Idle Detection

    private func startIdleDetection() {
        idleCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }

    private func checkIdle() {
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )
        appState?.isIdle = idleSeconds >= idleThreshold
    }

    // MARK: - Capture Timer

    private func startCaptureTimer() {
        scheduleNextCapture()
    }

    private func scheduleNextCapture() {
        let interval = TimeInterval(appState?.captureIntervalSeconds ?? 120)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.appState?.isTracking == true,
                  self.appState?.isIdle == false,
                  self.appState?.hasScreenRecordingPermission == true else { return }
            Task { @MainActor in
                await self.captureAndUpload()
            }
        }
    }

    // MARK: - Capture

    private func captureAndUpload() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()

            // Downscale to max 1024px wide while keeping aspect ratio
            let scale = min(1024.0 / CGFloat(display.width), 1.0)
            config.width = Int(CGFloat(display.width) * scale)
            config.height = Int(CGFloat(display.height) * scale)

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            // Convert to JPEG
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
                return
            }

            // Upload
            _ = try await APIClient.shared.uploadScreenshot(imageData: jpegData)

            appState?.lastCaptureTime = Date()
            appState?.captureCountToday += 1

        } catch {
            if (error as NSError).domain == "com.apple.ScreenCaptureKit" {
                appState?.hasScreenRecordingPermission = false
            }
        }
    }
}
