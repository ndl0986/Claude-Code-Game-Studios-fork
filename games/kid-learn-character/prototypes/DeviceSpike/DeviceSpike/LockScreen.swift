// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0008; M-2..M-7, P-4)
// Mac: the two candidate kiosk modes (borderless window at the screen frame, or native full screen) with Child
// Lock-in R2's options, covers on extra displays, an in-window overlay stub for the gate and panel, and the
// ⌃⌥⌘Q stub chord. Every step is logged with uptime so the ⌘ window and the engage timing can be read (M-2).
// iPad: the Guided Access page (Child Lock-in R8).
import SwiftUI
import SpikeKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct LockScreen: View {
    #if os(macOS)
    @StateObject private var kiosk = Kiosk()
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Kiosk mode (ADR-0008)", selection: $kiosk.mode) { ForEach(Kiosk.Mode.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented)
                HStack {
                    Button(kiosk.locked ? "Locked" : "Lock now") { kiosk.lock() }.disabled(kiosk.locked)
                    Button("Unlock") { kiosk.unlock() }.disabled(!kiosk.locked)
                    Button("Open gate overlay") { kiosk.overlay = true }
                }.buttonStyle(.bordered)
                Text("While locked: ⌃⌥⌘Q opens the overlay; the overlay's Quit (hold 1.5 s) unlocks and quits.").font(.callout)
                LogView()
            }.padding()
            if kiosk.overlay {
                Color(red: 0.07, green: 0.09, blue: 0.2).opacity(0.55).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("Gate / panel overlay stub (in the main window)").font(.title3)
                    Button("Close") { kiosk.overlay = false }
                    HoldButton(title: "Quit (hold 1.5 s)") { kiosk.unlock(); NSApp.terminate(nil) }
                }.padding(30).background(Color(red: 0.98, green: 0.96, blue: 0.9)).clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .onAppear { kiosk.installChord() }
    }
    #else
    @State private var enabled = UIAccessibility.isGuidedAccessEnabled
    var body: some View {
        VStack(spacing: 16) {
            Text(enabled ? "Guided Access is ON" : "Guided Access is OFF").font(.largeTitle)
            Text("Start Guided Access with a triple-click (F-4); this page updates live (P-4).").font(.callout)
            LogView()
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.guidedAccessStatusDidChangeNotification)) { _ in
            enabled = UIAccessibility.isGuidedAccessEnabled
            SpikeLog.shared.line("[lock] guidedAccessEnabled=\(enabled)")
        }
    }
    #endif
}

struct HoldButton: View {
    let title: String; let action: () -> Void
    @State private var start: Date?
    var body: some View {
        Text(title).padding(10).background(Color.red.opacity(start == nil ? 0.15 : 0.4)).clipShape(Capsule())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if start == nil { start = Date(); DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { if start != nil { action() } } } }
                .onEnded { _ in start = nil })
    }
}

#if os(macOS)
@MainActor
final class Kiosk: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable { case borderless = "Borderless window at the screen frame", native = "Native full screen"; var id: String { rawValue } }
    @Published var mode: Mode = .borderless
    @Published var locked = false
    @Published var overlay = false
    private var covers: [NSWindow] = []
    private var chord: Any?
    private var savedFrame: NSRect = .zero
    private var savedStyle: NSWindow.StyleMask = []
    private let delegate = FullScreenDelegate()
    /// TASK-134 dead-man (game-qc-ios, required for Mac session 1): every lock auto-unlocks after `deadManS` seconds
    /// (default 240; `-deadman <s>` overrides, 30…600). It runs on its own queue so a hung main thread cannot stop it:
    /// it asks the main thread to unlock and, if the main thread has not answered within 2 s, ends the process
    /// (`_exit`), which hands the Dock, menu bar, Force Quit and process switching back to macOS.
    private var deadMan: DispatchSourceTimer?
    private var lockGeneration = 0
    static var deadManS: Double {
        let v = UserDefaults.standard.double(forKey: "deadman")
        return v > 0 ? min(600, max(30, v)) : 240
    }

    /// Child Lock-in R2's set; .disableScreenCornerInteractions on macOS 27+ (with .hideDock).
    static var options: NSApplication.PresentationOptions {
        var o: NSApplication.PresentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, .disableForceQuit,
                                                    .disableSessionTermination, .disableHideApplication, .disableAppleMenu]
        if #available(macOS 27.0, *) { o.insert(.disableScreenCornerInteractions) }
        return o
    }
    var window: NSWindow? { NSApp.keyWindow ?? NSApp.windows.first }

    func installChord() {
        guard chord == nil else { return }
        chord = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            let e = KeyMap.fromMac(keyCode: Int(ev.keyCode), characters: ev.charactersIgnoringModifiers,
                                   modifiers: KeysScreen.mask(ev.modifierFlags), kind: .down, isRepeat: ev.isARepeat, time: ev.timestamp)
            if KeyMap.isParentChord(e) { SpikeLog.shared.line("[lock] chord ⌃⌥⌘Q"); self?.overlay = true; return nil }
            if self?.locked == true && e.modifiers & Mod.cmd != 0 { SpikeLog.shared.line("[lock] swallowed ⌘ key \(e.physicalId)"); return nil }
            return ev
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { n in
            MainActor.assumeIsolated { SpikeLog.shared.line("[lock] window resigned key: \((n.object as? NSWindow)?.title ?? "?")") }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { SpikeLog.shared.line("[lock] app resigned active") }
        }
        SpikeLog.shared.line("[lock] chord handler installed")
    }

    func lock() {
        guard let w = window, let screen = w.screen ?? NSScreen.main else { return }
        let t0 = ProcessInfo.processInfo.systemUptime
        savedFrame = w.frame; savedStyle = w.styleMask
        switch mode {
        case .borderless:
            w.styleMask = [.borderless]; w.setFrame(screen.frame, display: true); w.level = .normal
            NSApp.presentationOptions = Self.options
        case .native:
            delegate.options = Self.options; w.delegate = delegate
            w.collectionBehavior.insert(.fullScreenPrimary); w.toggleFullScreen(nil)
        }
        for s in NSScreen.screens where s != screen {
            let c = NSWindow(contentRect: s.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            c.backgroundColor = NSColor(red: 0.12, green: 0.15, blue: 0.30, alpha: 1); c.setFrame(s.frame, display: true)
            c.ignoresMouseEvents = false; c.orderFront(nil); covers.append(c)
        }
        locked = true
        armDeadMan()
        let covers = w.frame == screen.frame
        SpikeLog.shared.line("[lock] locked mode=\(mode == .borderless ? "borderless" : "native") applied in \(String(format: "%.1f", (ProcessInfo.processInfo.systemUptime - t0) * 1000)) ms windowCoversDisplay=\(covers) covers=\(self.covers.count)")
    }

    private func armDeadMan() {
        lockGeneration += 1
        let gen = lockGeneration, after = Self.deadManS
        deadMan?.cancel()
        let q = DispatchQueue(label: "spike.deadman", qos: .userInitiated)
        let t = DispatchSource.makeTimerSource(queue: q)
        t.schedule(deadline: .now() + after)
        t.setEventHandler { [weak self] in
            let answered = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    if let self, self.locked, self.lockGeneration == gen {
                        SpikeLog.shared.line("[lock] dead-man: auto-unlock after \(Int(after)) s locked")
                        self.unlock()
                    }
                }
                answered.signal()
            }
            if answered.wait(timeout: .now() + 2) == .timedOut {
                NSLog("[lock] dead-man: main thread did not answer in 2 s after %d s locked; exiting to restore the desktop", Int(after))
                _exit(3)
            }
        }
        deadMan = t; t.resume()
        SpikeLog.shared.line("[lock] dead-man armed: auto-unlock in \(Int(after)) s")
    }

    func unlock() {
        deadMan?.cancel(); deadMan = nil
        NSApp.presentationOptions = []
        if let w = window {
            if w.styleMask.contains(.fullScreen) { w.toggleFullScreen(nil) }
            else if mode == .borderless { w.styleMask = savedStyle; w.setFrame(savedFrame, display: true) }
        }
        covers.forEach { $0.close() }; covers = []
        locked = false; overlay = false
        SpikeLog.shared.line("[lock] unlocked")
    }
}

final class FullScreenDelegate: NSObject, NSWindowDelegate {
    var options: NSApplication.PresentationOptions = []
    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposed: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        options.union([.fullScreen, .autoHideToolbar])
    }
}
#endif
