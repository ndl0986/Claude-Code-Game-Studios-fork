// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0007 spike)
// Maps raw platform key data to ADR-0002 D5's normalized KeyEvent, so the Keys screen can show what the adapter
// would emit. The rules follow Input & Key Filter R2 (character first, US-position fallback, numpad by position).

/// ADR-0002 D5 modifier bits.
public enum Mod {
    public static let shift = 1, caps = 2, ctrl = 4, alt = 8, cmd = 16, fn = 32, numLock = 64
}

public enum KeyKind: String, Sendable { case down, up, cancel, modifiersChanged }

/// ADR-0002 D5's normalized key event (time filled by the caller from the uptime clock).
public struct KeyEvent: Equatable, Sendable {
    public var character: String?
    public var positionKey: String?
    public var modifiers: Int
    public var isRepeat: Bool
    public var physicalId: String
    public var kind: KeyKind
    public var time: Double
    /// What Input R2 resolves the key to: the character if it folds to A–Z/0–9, else the position, else nil.
    public var resolved: String? {
        if let n = KeyMap.numpadDigit(physicalId) { return n }
        if let c = character, let f = KeyMap.foldASCII(c) { return f }
        return positionKey
    }
}

public enum KeyMap {
    /// ASCII-only upper-casing of a one-scalar string; A–Z or 0–9 only (Input R2's fold; ADR-0002 D2).
    public static func foldASCII(_ s: String) -> String? {
        let scalars = Array(s.unicodeScalars)
        guard scalars.count == 1 else { return nil }
        var v = scalars[0].value
        if v >= 0x61 && v <= 0x7A { v -= 0x20 }
        if (v >= 0x41 && v <= 0x5A) || (v >= 0x30 && v <= 0x39) { return String(UnicodeScalar(UInt8(v))) }
        return nil
    }

    /// USB HID usage (UIKeyboardHIDUsage) → US-position key.
    public static func hidPosition(_ usage: Int) -> String? {
        if usage >= 0x04 && usage <= 0x1D { return String(UnicodeScalar(UInt8(0x41 + usage - 0x04))) }
        if usage >= 0x1E && usage <= 0x26 { return String(usage - 0x1E + 1) }
        if usage == 0x27 { return "0" }
        if usage >= 0x59 && usage <= 0x61 { return String(usage - 0x59 + 1) }   // keypad 1–9
        if usage == 0x62 { return "0" }                                         // keypad 0
        return nil
    }

    /// macOS virtual key code (ANSI) → US-position key.
    public static let macPositions: [Int: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K", 37: "L",
        46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
        16: "Y", 6: "Z", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
        82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
    ]
    static let macKeypad: Set<Int> = [82, 83, 84, 85, 86, 87, 88, 89, 91, 92]

    /// A numpad key resolves to its digit by position, whatever Num Lock says (Input R2.1).
    public static func numpadDigit(_ physicalId: String) -> String? {
        if physicalId.hasPrefix("hid:"), let u = Int(physicalId.dropFirst(4)), (0x59...0x62).contains(u) { return hidPosition(u) }
        if physicalId.hasPrefix("mac:"), let k = Int(physicalId.dropFirst(4)), macKeypad.contains(k) { return macPositions[k] }
        return nil
    }

    public static func fromHID(usage: Int, characters: String?, modifiers: Int, kind: KeyKind, isRepeat: Bool, time: Double) -> KeyEvent {
        KeyEvent(character: characters, positionKey: hidPosition(usage), modifiers: modifiers, isRepeat: isRepeat,
                 physicalId: "hid:\(usage)", kind: kind, time: time)
    }

    public static func fromMac(keyCode: Int, characters: String?, modifiers: Int, kind: KeyKind, isRepeat: Bool, time: Double) -> KeyEvent {
        KeyEvent(character: characters, positionKey: macPositions[keyCode], modifiers: modifiers, isRepeat: isRepeat,
                 physicalId: "mac:\(keyCode)", kind: kind, time: time)
    }

    /// The Mac parent chord ⌃⌥⌘Q: exactly those three modifiers plus Q (Shift and Caps ignored; Fn disqualifies).
    public static func isParentChord(_ e: KeyEvent) -> Bool {
        let relevant = e.modifiers & (Mod.ctrl | Mod.alt | Mod.cmd | Mod.fn)
        return e.kind == .down && relevant == (Mod.ctrl | Mod.alt | Mod.cmd) && e.positionKey == "Q"
    }
}
