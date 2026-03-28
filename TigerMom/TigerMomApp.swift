import SwiftUI

@main
struct TigerMomApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .background(Color(hex: 0x07070A))
        }
        .defaultSize(width: 1000, height: 700)
        .windowStyle(.titleBar)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    let appState = AppState()
    let screenCapture = ScreenCapture()
    let nudgeManager = NudgeManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        nudgeManager.start(appState: appState, statusItem: statusItem)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            reopenWindow()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        screenCapture.stop()
        nudgeManager.stop()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Tiger Mom")
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let tintedImage = image?.withSymbolConfiguration(config)
            button.image = tintedImage
            button.contentTintColor = NSColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1.0)
            button.action = #selector(menuBarClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func menuBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Open Tiger Mom", action: #selector(reopenWindow), keyEquivalent: "o"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit Tiger Mom", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            reopenWindow()
        }
    }

    @objc private func reopenWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
