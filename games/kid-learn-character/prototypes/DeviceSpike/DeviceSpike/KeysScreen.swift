// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0007; P-15, M-1, M-2)
// Shows each raw key event as ADR-0002 D5's normalized KeyEvent and what Input R2 resolves it to. On the Mac, the
// OS key-state read (KeyStateQuery candidate) is behind a switch that is OFF by default, so M-1 sees a clean launch.
import SwiftUI
import SpikeKit
#if os(iOS)
import UIKit
#else
import AppKit
import CoreGraphics
#endif

@MainActor
final class KeyFeed: ObservableObject {
    static let shared = KeyFeed()
    @Published var rows: [String] = []
    func add(_ e: KeyEvent) {
        let mods = [(Mod.shift, "⇧"), (Mod.caps, "⇪"), (Mod.ctrl, "⌃"), (Mod.alt, "⌥"), (Mod.cmd, "⌘"), (Mod.fn, "fn"), (Mod.numLock, "num")]
            .filter { e.modifiers & $0.0 != 0 }.map(\.1).joined()
        let chord = KeyMap.isParentChord(e) ? "  ← PARENT CHORD" : ""
        rows.insert("\(e.kind.rawValue.padding(toLength: 16, withPad: " ", startingAt: 0)) char=\(e.character.map { "\"\($0)\"" } ?? "nil") pos=\(e.positionKey ?? "-") mods=\(mods.isEmpty ? "-" : mods) repeat=\(e.isRepeat) id=\(e.physicalId) → \(e.resolved ?? "nothing")\(chord)", at: 0)
        if rows.count > 200 { rows.removeLast() }
    }
}

struct KeysScreen: View {
    @ObservedObject var feed = KeyFeed.shared
    #if os(macOS)
    @State private var keyStateOn = false      // ADR-0007 / M-1: OFF by default
    @State private var monitor: Any?
    #endif
    var body: some View {
        VStack(alignment: .leading) {
            Text("Press every key and modifier (P-15 on iPad, M-3 on Mac). The list shows the normalized events.").font(.callout)
            #if os(macOS)
            Toggle("Mac OS key-state read (KeyStateQuery candidate; M-1: leave OFF for the first launch)", isOn: $keyStateOn)
            #endif
            ZStack {
                #if os(iOS)
                KeyCatcher().frame(height: 1)
                #endif
                ScrollView { VStack(alignment: .leading) { ForEach(Array(feed.rows.enumerated()), id: \.offset) { Text($0.element).font(.caption.monospaced()) } } }
            }
        }
        .padding()
        #if os(macOS)
        .onAppear { install() }
        .onDisappear { if let m = monitor { NSEvent.removeMonitor(m) }; monitor = nil }
        #endif
    }

    #if os(macOS)
    private func install() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { ev in
            let kind: KeyKind = ev.type == .keyDown ? .down : (ev.type == .keyUp ? .up : .modifiersChanged)
            let chars = ev.type == .flagsChanged ? nil : ev.charactersIgnoringModifiers
            let e = KeyMap.fromMac(keyCode: Int(ev.keyCode), characters: chars, modifiers: Self.mask(ev.modifierFlags),
                                   kind: kind, isRepeat: ev.type == .keyDown && ev.isARepeat, time: ev.timestamp)
            KeyFeed.shared.add(e)
            if keyStateOn, kind == .modifiersChanged {
                SpikeLog.shared.line("[keys] key-state: anyNonModifierDown(except: \(e.physicalId)) = \(Self.anyNonModifierDown(except: Int(ev.keyCode)))")
            }
            return nil                                  // swallowed, as Input R5 would
        }
    }
    static func mask(_ f: NSEvent.ModifierFlags) -> Int {
        var m = 0
        if f.contains(.shift) { m |= Mod.shift }; if f.contains(.capsLock) { m |= Mod.caps }; if f.contains(.control) { m |= Mod.ctrl }
        if f.contains(.option) { m |= Mod.alt }; if f.contains(.command) { m |= Mod.cmd }; if f.contains(.function) { m |= Mod.fn }
        if f.contains(.numericPad) { m |= Mod.numLock }
        return m
    }
    /// The candidate KeyStateQuery: the adapter enumerates the platform key codes (ADR-0002 D6).
    static func anyNonModifierDown(except code: Int) -> Bool {
        let modifiers: Set<Int> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        for k in 0..<128 where k != code && !modifiers.contains(k) {
            if CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(k)) { return true }
        }
        return false
    }
    #endif
}

#if os(iOS)
/// A first responder that receives hardware key presses (pressesBegan/Ended/Cancelled) and forwards them unhandled.
struct KeyCatcher: UIViewRepresentable {
    func makeUIView(context: Context) -> CatcherView { let v = CatcherView(); DispatchQueue.main.async { v.becomeFirstResponder() }; return v }
    func updateUIView(_ v: CatcherView, context: Context) {}
    final class CatcherView: UIView {
        override var canBecomeFirstResponder: Bool { true }
        private var held: Set<Int> = []
        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) { handle(presses, .down) }
        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) { handle(presses, .up) }
        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) { handle(presses, .cancel) }
        private func handle(_ presses: Set<UIPress>, _ kind: KeyKind) {
            for p in presses.sorted(by: { $0.timestamp < $1.timestamp }) {
                guard let k = p.key else { continue }
                let usage = k.keyCode.rawValue
                let rep = kind == .down && held.contains(usage)
                if kind == .down { held.insert(usage) } else { held.remove(usage) }
                let e = KeyMap.fromHID(usage: usage, characters: k.charactersIgnoringModifiers, modifiers: Self.mask(k.modifierFlags),
                                       kind: kind, isRepeat: rep, time: p.timestamp)
                MainActor.assumeIsolated { KeyFeed.shared.add(e) }
            }
        }
        static func mask(_ f: UIKeyModifierFlags) -> Int {
            var m = 0
            if f.contains(.shift) { m |= Mod.shift }; if f.contains(.alphaShift) { m |= Mod.caps }; if f.contains(.control) { m |= Mod.ctrl }
            if f.contains(.alternate) { m |= Mod.alt }; if f.contains(.command) { m |= Mod.cmd }; if f.contains(.numericPad) { m |= Mod.numLock }
            return m
        }
    }
}
#endif
