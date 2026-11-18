import ContractKit
import Foundation
import KidCore

/// An in-memory `SettingsBackend` that records what the store does to it.
final class MemoryBackend: SettingsBackend {
    var bytes: [UInt8]?
    var ops: [JSONValue] = []
    init(_ bytes: [UInt8]?) { self.bytes = bytes }
    func read() -> [UInt8]? { bytes }
    func write(_ b: [UInt8]) -> Bool? {
        bytes = b
        ops.append(.object(["out": .string("write"), "bytes": .string(String(decoding: b, as: UTF8.self))]))
        return true
    }
    func remove() { bytes = nil; ops.append(.object(["out": .string("remove")])) }
}

/// Collects the store's debug lines as `log` outputs (the field name only; reasons are not compared).
final class CollectingLog: DebugLog {
    var outs: [JSONValue] = []
    func log(_ line: String) {
        guard line.hasPrefix("settings "), let colon = line.firstIndex(of: ":") else { return }
        let field = String(line[line.index(line.startIndex, offsetBy: 9)..<colon])
        outs.append(.object(["out": .string("log"), "field": .string(field)]))
    }
}

/// settings-record-v1 (Settings Store R1–R10, R6a, F1, F2; ADR-0004 D3: KidCore layer).
struct SettingsRecordRunner: ContractRunner {
    static let contract = "settings-record-v1"
    static let declaration = ContractDeclaration(
        givenFields: ["platform", "settingsBytes"],
        events: ["read": [], "change": ["field", "value"], "sliderRelease": ["x"], "setChildLock": ["on"],
                 "reset": [], "relaunch": [], "gain": [], "roundHalfAwayFromZero": ["x"]])
    static func kind(out: String, field: String) -> String? { out == "gain" && field == "value" ? "gain" : nil }

    let platform: SettingsPlatform
    let backend: MemoryBackend
    var log = CollectingLog()
    var store: SettingsStore
    var notes: [JSONValue] = []

    init(given: [String: JSONValue], draws: DrawQueues) throws {
        switch given["platform"]?.string {
        case "iPadOS": platform = .iPadOS
        case "android": platform = .android
        default: platform = .macOS
        }
        backend = MemoryBackend(given["settingsBytes"]?.string.map { Array($0.utf8) })
        store = SettingsStore(platform: platform, backend: backend, log: log)
    }

    func recordJSON(_ r: SettingsRecord) -> JSONValue {
        var o: [String: JSONValue] = [
            "schemaVersion": .int(Int64(r.schemaVersion)), "volume": .int(Int64(r.volume)), "muted": .bool(r.muted),
            "themeId": .string(r.themeId), "weather": .string(r.weather.rawValue), "windy": .bool(r.windy),
            "keyboardRow": .bool(r.keyboardRow),
        ]
        if platform == .macOS { o["childLock"] = .bool(r.childLock) }
        return .object(o)
    }

    func recordOut(_ kind: String, _ r: SettingsRecord, _ active: Bool) -> JSONValue {
        .object(["out": .string(kind), "record": recordJSON(r), "childLockActive": .bool(active)])
    }

    mutating func step(uptime: Double, event e: [String: JSONValue]) throws -> Outputs {
        backend.ops = []
        log.outs = []
        var notified: [JSONValue] = []
        let platform = self.platform
        let toJSON = { (r: SettingsRecord, a: Bool) -> JSONValue in
            var o: [String: JSONValue] = [
                "schemaVersion": .int(Int64(r.schemaVersion)), "volume": .int(Int64(r.volume)), "muted": .bool(r.muted),
                "themeId": .string(r.themeId), "weather": .string(r.weather.rawValue), "windy": .bool(r.windy),
                "keyboardRow": .bool(r.keyboardRow),
            ]
            if platform == .macOS { o["childLock"] = .bool(r.childLock) }
            return .object(["out": .string("notify"), "record": .object(o), "childLockActive": .bool(a)])
        }
        store.onChange = { r, a in notified.append(toJSON(r, a)) }
        switch e["type"]?.string {
        case "read":
            store.read()
            return log.outs + [recordOut("record", store.record, store.childLockActive)]
        case "relaunch":
            store = SettingsStore(platform: platform, backend: backend, log: log)
            store.read()
            return log.outs + [recordOut("record", store.record, store.childLockActive)]
        case "change":
            let f = e["field"]?.string ?? "", v = e["value"] ?? .null
            let change: SettingsChange
            switch (f, v) {
            case ("volume", _): change = .volume(Int(v.number ?? 0))
            case ("muted", .bool(let b)): change = .muted(b)
            case ("themeId", .string(let s)): change = .themeId(s)
            case ("weather", .string(let s)):
                guard let w = Weather(rawValue: s) else { throw ContractError("unknown weather \(s)") }
                change = .weather(w)
            case ("windy", .bool(let b)): change = .windy(b)
            case ("keyboardRow", .bool(let b)): change = .keyboardRow(b)
            default: throw ContractError("unsupported change \(f)")
            }
            store.apply(change)
        case "sliderRelease":
            // settings-record-v2 spec.md: JSON has no non-finite numbers, so x may be "NaN", "Infinity" or "-Infinity".
            let x: Double
            switch e["x"]?.string {
            case "NaN"?: x = .nan
            case "Infinity"?: x = .infinity
            case "-Infinity"?: x = -.infinity
            default: x = e["x"]?.number ?? .nan
            }
            store.sliderReleased(x)
        case "setChildLock": store.setChildLock(e["on"] == .bool(true))
        case "reset": store.reset()
        case "gain": return [.object(["out": .string("gain"), "value": .double(store.gain)])]
        case "roundHalfAwayFromZero":
            return [.object(["out": .string("value"), "value": .double(roundHalfAwayFromZero(e["x"]?.number ?? .nan))])]
        default: throw ContractError("unknown event")
        }
        return log.outs + backend.ops + notified
    }
}

struct ContractError: Error, CustomStringConvertible {
    let description: String
    init(_ d: String) { description = d }
}
