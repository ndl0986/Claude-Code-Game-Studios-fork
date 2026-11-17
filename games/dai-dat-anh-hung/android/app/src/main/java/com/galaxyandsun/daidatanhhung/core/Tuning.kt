package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.TuningFile

/**
 * Typed access to content/data/tuning.json. Every gameplay number comes from here; nothing is
 * hard-coded in the simulation. A key missing from the file is a content error: [require] throws,
 * and the content tests check that every key in [Keys.ALL] exists.
 */
class Tuning(private val values: Map<String, Double>, val seed: Long) {
    operator fun get(key: String): Double =
        values[key] ?: throw IllegalStateException("tuning.json has no value '$key'")

    fun int(key: String): Int = get(key).toInt()

    object Keys {
        val ALL = listOf(
            "volume", "hero_speed", "attack_time", "attack_cooldown", "attack_range", "knockback",
            "hero_pushback", "hurt_time", "enemy_speed", "enter_speed", "enemy_reach", "telegraph",
            "strike_time", "enemy_rest", "spawn_gap", "flee_speed", "hp_spear", "hp_shield",
            "hp_leader", "leader_speed_mul", "stand_gap", "queue_spacing", "kb_decay",
            "spawn_offset", "lock_offset", "leader_knock_mul", "pad_min", "hint_delay",
            "end_pause", "quiz_count", "feedback_time",
            "first_spawn_delay", "hurt_recover", "leader_telegraph_mul", "enter_to_approach_dist",
            "approach_min_time", "windup_reach_extra", "strike_reach_extra", "block_knock",
            "rest_speed_mul", "attack_hit_at", "attack_close_range", "attack_move_mul",
            "flee_remove_margin", "hero_edge_margin", "camera_follow_offset", "ground_y",
            "beat_start_x", "beat_gap", "hero_start_x",
        )
    }

    companion object {
        fun from(file: TuningFile): Tuning = Tuning(file.values.mapValues { it.value.value }, file.seed)
    }
}
