// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Child lock-in on macOS (-kiosk 1): AppKit presentation options that hide the Dock and menu bar and disable process
// switching, force quit, session termination (log out / restart / shut down) and hiding. The window fills the
// screen. Only the parent chord ⌃⌥⌘Q quits (Input.swift). On iPadOS there is no app-side equivalent: the parent uses
// Guided Access.
import Foundation
#if os(macOS)
import AppKit
#endif

enum Kiosk {
    static let on = UserDefaults.standard.bool(forKey: "kiosk")

    #if os(macOS)
    static let options: NSApplication.PresentationOptions = [
        .hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit, .disableSessionTermination, .disableHideApplication, .disableAppleMenu,
    ]

    /// Applies the options (valid combination: hideMenuBar and disableProcessSwitching need hideDock) and fills the
    /// screen with the window. Logs what the system reports back.
    @MainActor static func apply() {
        guard on else { return }
        var o = options
        if #available(macOS 27.0, *) { o.insert(.disableScreenCornerInteractions) } // hot corners (macOS 27+)
        NSApp.presentationOptions = o
        if let w = NSApp.windows.first, let screen = w.screen ?? NSScreen.main {
            w.setFrame(screen.frame, display: true)
            w.level = .normal
        }
        NSApp.activate()
        let got = NSApp.currentSystemPresentationOptions
        NSLog("[spike] kiosk requested=%lu current=%lu (hideDock=%d hideMenuBar=%d disableProcessSwitching=%d disableForceQuit=%d)", options.rawValue, got.rawValue,
              got.contains(.hideDock) ? 1 : 0, got.contains(.hideMenuBar) ? 1 : 0, got.contains(.disableProcessSwitching) ? 1 : 0, got.contains(.disableForceQuit) ? 1 : 0)
    }
    #endif
}
