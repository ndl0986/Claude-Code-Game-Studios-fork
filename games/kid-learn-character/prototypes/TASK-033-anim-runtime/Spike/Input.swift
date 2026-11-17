// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Press sources with their own event timestamps: hardware keys (iPad: pressesBegan on a first responder; Mac: a local
// keyDown monitor), and the on-screen keys (touchesBegan / mouseDown). Held keys and auto-repeat are ignored.
// Also runs the display link whose targetTimestamp estimates when a frame reaches the screen.
import SwiftUI
import QuartzCore

/// Which keys play: exactly one letter A–Z or digit 0–9 with no ⌘/⌃/⌥. Everything else is swallowed and counted.
enum KeyFilter {
    static func isPlayKey(_ c: String, command: Bool) -> Bool {
        guard !command, c.count == 1, let u = c.uppercased().unicodeScalars.first else { return false }
        return ("A"..."Z").contains(Character(u)) || ("0"..."9").contains(Character(u))
    }
    static func swallowed(_ c: String) {
        Metrics.shared.swallowed += 1
        NSLog("[spike] swallowed key %@", c.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))
    }
}

#if os(iOS)
import UIKit

final class KeyCatcherView: UIView {
    var onKey: ((String, Double) -> Void)?
    private var held = Set<UIKeyboardHIDUsage>()
    private var link: CADisplayLink?
    override var canBecomeFirstResponder: Bool { true }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            becomeFirstResponder()
            if link == nil { link = CADisplayLink(target: self, selector: #selector(tick(_:))); link?.add(to: .main, forMode: .common) }
        }
    }
    @objc func tick(_ l: CADisplayLink) { Metrics.shared.lastTargetTimestamp = l.targetTimestamp; Metrics.shared.lastLinkDuration = l.targetTimestamp - l.timestamp }
    /// Child lock-in, keys inside the app: a letter or digit (no ⌘/⌃/⌥) is a press; every other key is swallowed
    /// (never passed up the responder chain). System shortcuts the OS keeps (⌘Tab, ⌘H, Globe) never reach the app.
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for p in presses {
            guard let k = p.key else { continue }
            if held.contains(k.keyCode) { continue } // held key / auto-repeat
            held.insert(k.keyCode)
            let c = k.charactersIgnoringModifiers
            if KeyFilter.isPlayKey(c, command: k.modifierFlags.contains(.command) || k.modifierFlags.contains(.control) || k.modifierFlags.contains(.alternate)) {
                onKey?(c, p.timestamp)
            } else { KeyFilter.swallowed(c) }
        }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for p in presses { if let k = p.key { held.remove(k.keyCode) } }
        super.pressesEnded(presses, with: event)
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for p in presses { if let k = p.key { held.remove(k.keyCode) } }
        super.pressesCancelled(presses, with: event)
    }
}

struct KeyCatcher: UIViewRepresentable {
    let onKey: (String, Double) -> Void
    func makeUIView(context: Context) -> KeyCatcherView { let v = KeyCatcherView(); v.onKey = onKey; v.backgroundColor = .clear; v.isUserInteractionEnabled = false; return v }
    func updateUIView(_ v: KeyCatcherView, context: Context) { v.onKey = onKey }
}

final class TouchKeyView: UIView {
    var key = "", onKey: ((String, Double) -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { for t in touches { onKey?(key, t.timestamp) } }
}

struct TouchKey: UIViewRepresentable {
    let key: String, onKey: (String, Double) -> Void
    func makeUIView(context: Context) -> TouchKeyView {
        let v = TouchKeyView(); v.key = key; v.onKey = onKey; v.isMultipleTouchEnabled = true
        v.backgroundColor = UIColor(red: 1, green: 0.84, blue: 0.4, alpha: 1); v.layer.cornerRadius = 28
        let l = UILabel(); l.text = key; l.font = .systemFont(ofSize: 72, weight: .heavy); l.textColor = UIColor(red: 0.25, green: 0.18, blue: 0.1, alpha: 1)
        l.textAlignment = .center; l.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(l)
        NSLayoutConstraint.activate([l.centerXAnchor.constraint(equalTo: v.centerXAnchor), l.centerYAnchor.constraint(equalTo: v.centerYAnchor)])
        v.accessibilityIdentifier = "key-\(key)"; v.isAccessibilityElement = true; v.accessibilityLabel = key
        return v
    }
    func updateUIView(_ v: TouchKeyView, context: Context) { v.onKey = onKey }
}

#else
import AppKit

final class KeyCatcherView: NSView {
    var onKey: ((String, Double) -> Void)?
    private var monitor: Any?, link: CADisplayLink?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, monitor == nil else { return }
        // Child lock-in, keys inside the app: letters and digits play; every other key is swallowed. Without kiosk
        // mode ⌘-shortcuts still reach the menus (⌘Q works); in kiosk mode (-kiosk 1) they are swallowed too, and only
        // the parent chord ⌃⌥⌘Q quits.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            let mods = e.modifierFlags.intersection([.command, .control, .option])
            if Kiosk.on && mods == [.command, .control, .option] && e.charactersIgnoringModifiers?.lowercased() == "q" { NSApp.terminate(nil); return nil }
            if mods.contains(.command) && !Kiosk.on { return e }
            let c = e.charactersIgnoringModifiers ?? ""
            if e.isARepeat { return nil }
            if KeyFilter.isPlayKey(c, command: !mods.isEmpty) { self?.onKey?(c, e.timestamp) } else { KeyFilter.swallowed(c) }
            return nil
        }
        link = displayLink(target: self, selector: #selector(tick(_:))); link?.add(to: .main, forMode: .common)
    }
    @objc func tick(_ l: CADisplayLink) { Metrics.shared.lastTargetTimestamp = l.targetTimestamp; Metrics.shared.lastLinkDuration = l.targetTimestamp - l.timestamp }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

struct KeyCatcher: NSViewRepresentable {
    let onKey: (String, Double) -> Void
    func makeNSView(context: Context) -> KeyCatcherView { let v = KeyCatcherView(); v.onKey = onKey; return v }
    func updateNSView(_ v: KeyCatcherView, context: Context) { v.onKey = onKey }
}

final class TouchKeyView: NSView {
    var key = "", onKey: ((String, Double) -> Void)?
    override func mouseDown(with e: NSEvent) { onKey?(key, e.timestamp) }
}

struct TouchKey: NSViewRepresentable {
    let key: String, onKey: (String, Double) -> Void
    func makeNSView(context: Context) -> TouchKeyView {
        let v = TouchKeyView(); v.key = key; v.onKey = onKey; v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(red: 1, green: 0.84, blue: 0.4, alpha: 1).cgColor; v.layer?.cornerRadius = 28
        let l = NSTextField(labelWithString: key); l.font = .systemFont(ofSize: 72, weight: .heavy); l.textColor = NSColor(red: 0.25, green: 0.18, blue: 0.1, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(l)
        NSLayoutConstraint.activate([l.centerXAnchor.constraint(equalTo: v.centerXAnchor), l.centerYAnchor.constraint(equalTo: v.centerYAnchor)])
        return v
    }
    func updateNSView(_ v: TouchKeyView, context: Context) { v.onKey = onKey }
}
#endif
