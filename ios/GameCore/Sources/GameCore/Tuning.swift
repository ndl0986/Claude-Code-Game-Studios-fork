import Foundation

/// `tuning.json`: every gameplay value, {value, min, max, unit}, in a 1280×720 world.
public struct Tuning: Sendable {
    public struct Entry: Codable, Sendable { public let value: Double; public let min: Double; public let max: Double; public let unit: String }
    struct World: Codable { let width: Double; let height: Double }
    struct File: Codable { let schemaVersion: String; let seed: Int; let values: [String: Entry]; let world: World? }

    public let schemaVersion: String
    public let seed: Int
    public let values: [String: Entry]
    /// `world.width` (1280 today): the screen width W in Combat Rule 15b and R14b.
    public let worldWidth: Double

    /// Every key the iOS core reads. A missing key fails the content test, never a silent default.
    public static let requiredKeys = [
        "volume", "hero_speed", "attack_time", "attack_cooldown", "attack_range", "knockback", "hero_pushback",
        "hurt_time", "enemy_speed", "enter_speed", "enemy_reach", "telegraph", "strike_time", "enemy_rest",
        "spawn_gap", "flee_speed", "hp_spear", "hp_shield", "hp_leader", "leader_speed_mul", "stand_gap",
        "queue_spacing", "kb_decay", "spawn_offset", "lock_offset", "leader_knock_mul", "pad_min", "hint_delay",
        "end_pause", "quiz_count", "feedback_time", "first_spawn_delay", "hurt_recover", "leader_telegraph_mul",
        "enter_to_approach_dist", "approach_min_time", "windup_reach_extra", "strike_reach_extra", "block_knock",
        "rest_speed_mul", "attack_hit_at", "attack_close_range", "attack_move_mul", "flee_remove_margin",
        "hero_edge_margin", "camera_follow_offset", "ground_y", "beat_start_x", "beat_gap", "hero_start_x",
        "dummy_spacing", "advance_debounce", "pad_gap", "screen_enter_lock",
    ]

    public init(data: Data) throws {
        let f = try ContentJSON.decode(File.self, from: data)
        schemaVersion = f.schemaVersion; seed = f.seed; worldWidth = f.world?.width ?? 1280
        // decode keeps the dictionary keys as written (snake_case): convertFromSnakeCase leaves dictionary keys alone.
        values = f.values
    }

    public init(values: [String: Double], seed: Int = 1) {
        schemaVersion = "1.0"; self.seed = seed; worldWidth = 1280
        self.values = values.mapValues { Entry(value: $0, min: $0, max: $0, unit: "") }
    }

    /// The value for `key`. Crashes in debug on a missing key: the content test guards every key first.
    public subscript(_ key: String) -> Double {
        guard let e = values[key] else { assertionFailure("tuning.json has no '\(key)'"); return 0 }
        return e.value
    }

    /// The keys from `requiredKeys` this file lacks.
    public var missingKeys: [String] { Self.requiredKeys.filter { values[$0] == nil } }
}
