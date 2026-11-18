/// The platform the record is for: `childLock` exists only on macOS (Settings Store R1, R6).
public enum SettingsPlatform: Sendable { case macOS, iPadOS, android }

/// Scene weather (Settings Store R1).
public enum Weather: String, CaseIterable, Sendable { case clear, cloudy, lightRain, snow }

/// The in-memory record (Settings Store R1). `childLock` is meaningful on macOS only.
public struct SettingsRecord: Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion = SettingsRecord.currentSchemaVersion
    public var volume = 8
    public var muted = false
    public var themeId = "dinosaurs"
    public var weather = Weather.clear
    public var windy = false
    public var keyboardRow = false
    public var childLock = false

    public init() {}

    /// The canonical bytes (R6a): members sorted by key, no whitespace; `childLock` only on macOS; this app's version.
    public func canonicalBytes(platform: SettingsPlatform) -> [UInt8] {
        var o: [UInt8] = [0x7B]
        func key(_ k: String, first: Bool = false) {
            if !first { o.append(0x2C) }
            CanonicalJSON.appendString(k, to: &o)
            o.append(0x3A)
        }
        func bool(_ b: Bool) { o.append(contentsOf: Array((b ? "true" : "false").utf8)) }
        var first = true
        if platform == .macOS { key("childLock", first: true); bool(childLock); first = false }
        key("keyboardRow", first: first); bool(keyboardRow)
        key("muted"); bool(muted)
        key("schemaVersion"); CanonicalJSON.appendInt(SettingsRecord.currentSchemaVersion, to: &o)
        key("themeId"); CanonicalJSON.appendString(themeId, to: &o)
        key("volume"); CanonicalJSON.appendInt(volume, to: &o)
        key("weather"); CanonicalJSON.appendString(weather.rawValue, to: &o)
        key("windy"); bool(windy)
        o.append(0x7D)
        return o
    }
}

/// One grown-up change from the panel (R4).
public enum SettingsChange: Equatable, Sendable {
    case volume(Int), muted(Bool), themeId(String), weather(Weather), windy(Bool), keyboardRow(Bool)
}

/// F1, from the slider: `clamp(round(x), 0, 10)`; nil for a non-finite position (TASK-082: no change).
public func sliderLevel(_ x: Double) -> Int? {
    guard x.isFinite else { return nil }
    return Int(min(10, max(0, roundHalfAwayFromZero(x))))
}

/// F2: the linear gain handed to Audio.
public func settingsGain(volume: Int, muted: Bool) -> Double { muted ? 0 : Double(volume) / 10 }

/// The Settings Store (R1–R10): reads, validates, writes the canonical record behind `SettingsBackend`, and notifies.
public final class SettingsStore {
    public let platform: SettingsPlatform
    let backend: SettingsBackend
    let log: DebugLog
    /// Called once per change (R10), with the whole record and the run value.
    public var onChange: ((SettingsRecord, Bool) -> Void)?

    public private(set) var record = SettingsRecord()
    /// The run value (R8, macOS): at launch the stored `childLock`; OFF lasts for this run only.
    public private(set) var childLockActive = false

    public init(platform: SettingsPlatform, backend: SettingsBackend, log: DebugLog) {
        self.platform = platform
        self.backend = backend
        self.log = log
    }

    /// The launch read (R5): never writes, never notifies; one `.debug` line per fallback, in R1's order (R6a).
    public func read() {
        record = SettingsRecord()
        childLockActive = false
        guard let bytes = backend.read() else { return }
        guard case .object(let members)? = try? CanonicalJSON.parse(bytes) else {
            log.log("settings record: unreadable")
            return
        }
        var m: [String: CanonicalJSON.Value] = [:]
        for (k, v) in members { m[k] = v }
        func fallback(_ field: String) { log.log("settings \(field): default") }

        if case .number(let v)? = m["schemaVersion"], v.isFinite, v >= 1, v == roundHalfAwayFromZero(v) {} else { fallback("schemaVersion") }
        if case .number(let v)? = m["volume"], v.isFinite, v >= 0, v <= 10 { record.volume = Int(roundHalfAwayFromZero(v)) } else { fallback("volume") }
        if case .bool(let v)? = m["muted"] { record.muted = v } else { fallback("muted") }
        if case .string(let v)? = m["themeId"], !v.isEmpty { record.themeId = v } else { fallback("themeId") }
        if case .string(let v)? = m["weather"], let w = Weather(rawValue: v) { record.weather = w } else { fallback("weather") }
        if case .bool(let v)? = m["windy"] { record.windy = v } else { fallback("windy") }
        if case .bool(let v)? = m["keyboardRow"] { record.keyboardRow = v } else { fallback("keyboardRow") }
        if platform == .macOS {
            if case .bool(let v)? = m["childLock"] { record.childLock = v } else { fallback("childLock") }
        }
        childLockActive = platform == .macOS && record.childLock
    }

    /// A grown-up change (R4, R10). A no-op change does nothing (R6a, SS-Q7).
    public func apply(_ change: SettingsChange) {
        var r = record
        switch change {
        case .volume(let v): r.volume = min(10, max(0, v))
        case .muted(let v): r.muted = v
        case .themeId(let v): if !v.isEmpty { r.themeId = v }
        case .weather(let v): r.weather = v
        case .windy(let v): r.windy = v
        case .keyboardRow(let v): r.keyboardRow = v
        }
        commit(r, active: childLockActive)
    }

    /// The slider released at position `x` (F1). Non-finite: no change, one log line (TASK-082).
    public func sliderReleased(_ x: Double) {
        guard let level = sliderLevel(x) else { log.log("settings volume: slider not finite"); return }
        apply(.volume(level))
    }

    /// The child-lock switch (R8, macOS). ON writes `childLock: true`; OFF changes only the run value.
    public func setChildLock(_ on: Bool) {
        guard platform == .macOS else { return }
        if on {
            var r = record
            r.childLock = true
            commit(r, active: true)
        } else if childLockActive {
            childLockActive = false
            onChange?(record, false)
        }
    }

    /// Reset (R9): remove the record, back to defaults, one notification.
    public func reset() {
        backend.remove()
        record = SettingsRecord()
        childLockActive = false
        onChange?(record, false)
    }

    /// F2 for the current record.
    public var gain: Double { settingsGain(volume: record.volume, muted: record.muted) }

    func commit(_ r: SettingsRecord, active: Bool) {
        if r == record && active == childLockActive { return }
        record = r
        childLockActive = active
        _ = backend.write(r.canonicalBytes(platform: platform))
        onChange?(record, childLockActive)
    }
}
