import SwiftUI
import AppKit

@main
struct TigerMomApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(
                appState: appDelegate.appState,
                screenCapture: appDelegate.screenCapture
            )
            .frame(minWidth: 1080, minHeight: 760)
            .background(TigerPalette.background)
        }
        .defaultSize(width: 1360, height: 860)
        .windowStyle(.hiddenTitleBar)
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
            button.image = TigerStatusImage.makeTemplateImage()
            button.contentTintColor = NSColor(red: 0.949, green: 0.753, blue: 0.471, alpha: 1.0)
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

enum TigerStatusImage {
    static func makeTemplateImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let canvas = NSRect(x: 0, y: 0, width: size, height: size)
        let eyeRect = canvas.insetBy(dx: size * 0.18, dy: size * 0.33)

        let eyePath = NSBezierPath()
        eyePath.move(to: NSPoint(x: eyeRect.minX, y: eyeRect.midY))
        eyePath.curve(
            to: NSPoint(x: eyeRect.maxX, y: eyeRect.midY),
            controlPoint1: NSPoint(x: eyeRect.minX + eyeRect.width * 0.2, y: eyeRect.maxY),
            controlPoint2: NSPoint(x: eyeRect.minX + eyeRect.width * 0.8, y: eyeRect.maxY)
        )
        eyePath.curve(
            to: NSPoint(x: eyeRect.minX, y: eyeRect.midY),
            controlPoint1: NSPoint(x: eyeRect.minX + eyeRect.width * 0.8, y: eyeRect.minY),
            controlPoint2: NSPoint(x: eyeRect.minX + eyeRect.width * 0.2, y: eyeRect.minY)
        )
        eyePath.close()

        NSColor.white.setFill()
        eyePath.fill()

        let irisRect = NSRect(
            x: canvas.midX - size * 0.13,
            y: canvas.midY - size * 0.13,
            width: size * 0.26,
            height: size * 0.26
        )
        let irisCutout = NSBezierPath(ovalIn: irisRect)
        NSColor.black.setFill()
        irisCutout.fill()

        let pupilRect = NSRect(
            x: canvas.midX - size * 0.022,
            y: canvas.midY - size * 0.13,
            width: size * 0.044,
            height: size * 0.26
        )
        let pupil = NSBezierPath(roundedRect: pupilRect, xRadius: size * 0.025, yRadius: size * 0.025)
        NSColor.white.setFill()
        pupil.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
