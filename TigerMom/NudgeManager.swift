import AppKit
import SwiftUI

@Observable
class NudgeManager {
    private var pollTimer: Timer?
    private weak var appState: AppState?
    private var popover: NSPopover?
    private weak var statusItem: NSStatusItem?

    func start(appState: AppState, statusItem: NSStatusItem?) {
        self.appState = appState
        self.statusItem = statusItem
        startPolling()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        dismissPopover()
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNudge()
            }
        }
    }

    private func checkForNudge() async {
        guard appState?.activeNudge == nil else { return }

        do {
            let response = try await APIClient.shared.getNudge()

            guard let hasNudge = response["has_nudge"] as? Bool, hasNudge,
                  let nudge = response["nudge"] as? [String: Any] else { return }

            let nudgeData = NudgeData(
                id: nudge["id"] as? String ?? UUID().uuidString,
                emoji: nudge["emoji"] as? String ?? "",
                message: nudge["message"] as? String ?? "",
                severity: parseSeverity(nudge["severity"] as? String),
                trigger: nudge["trigger"] as? String ?? ""
            )

            appState?.activeNudge = nudgeData
            updateMenuBarIcon(isNudgeActive: true)
            showPopover(nudge: nudgeData)

        } catch {
            // Server not reachable or no nudge — silently continue
        }
    }

    private func parseSeverity(_ raw: String?) -> NudgeData.NudgeSeverity {
        guard let raw else { return .gray }
        return NudgeData.NudgeSeverity(rawValue: raw.lowercased()) ?? .gray
    }

    // MARK: - Popover

    private func showPopover(nudge: NudgeData) {
        guard let button = statusItem?.button else { return }

        let popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.contentSize = NSSize(width: 336, height: 360)
        popover.animates = true

        let view = NudgePopoverView(nudge: nudge) { [weak self] response in
            self?.handleNudgeResponse(response: response)
        }

        popover.contentViewController = NSHostingController(rootView: view)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popover = popover
    }

    func dismissPopover() {
        popover?.performClose(nil)
        popover = nil
    }

    // MARK: - Response

    private func handleNudgeResponse(response: String) {
        guard let nudge = appState?.activeNudge else { return }

        Task { @MainActor in
            let body: [String: Any] = [
                "nudge_id": nudge.id,
                "response": response
            ]
            _ = try? await APIClient.shared.nudgeResponse(body: body)

            appState?.activeNudge = nil
            updateMenuBarIcon(isNudgeActive: false)
            dismissPopover()
        }
    }

    // MARK: - Menu Bar Icon

    private func updateMenuBarIcon(isNudgeActive: Bool) {
        guard let button = statusItem?.button else { return }
        if isNudgeActive {
            button.contentTintColor = NSColor(red: 0.843, green: 0.604, blue: 0.451, alpha: 1.0)
        } else {
            button.contentTintColor = NSColor(red: 0.949, green: 0.753, blue: 0.471, alpha: 1.0)
        }
    }
}
