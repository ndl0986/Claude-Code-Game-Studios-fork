package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import com.galaxyandsun.daidatanhhung.core.content.FightParams
import com.galaxyandsun.daidatanhhung.core.content.MissionFile
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sign
import kotlin.math.sin

/** The four game actions a pad or key produces. */
enum class Action { LEFT, RIGHT, ATTACK, DEFEND }

/** One fixed step's input: actions held now, and actions newly pressed this step. */
class InputFrame {
    val held = mutableSetOf<Action>()
    val tapped = mutableSetOf<Action>()
    fun clearTaps() = tapped.clear()
}

/** Sounds the simulation asks for; the platform layer plays them (placeholder tones in the slice). */
enum class Sfx { TAP, DRUM, CLANG, SWOOSH, BONK, CHIME, SOFT }

/** Phases inside the play screen. CAPTION is the prototype's caption screen. */
enum class Phase { WALK, FIGHT, CAPTION }

/** The prototype's enemy state names, exactly (TASK-007 brief item 5). */
enum class EnemyState(val id: String) { ENTER("enter"), APPROACH("approach"), WINDUP("windup"), STRIKE("strike"), REST("rest"), HURT("hurt"), FLEE("flee") }

class Hero(var x: Double) {
    var face = 1
    /** Swing progress 0..1, or -1 when not attacking. */
    var atk = -1.0
    var hitDone = false
    var cool = 0.0
    var hurt = 0.0
    var def = false
    var walk = false
}

class Enemy(val id: Int, val kind: String, var x: Double, var face: Int) {
    var state = EnemyState.ENTER
    var t = 0.0
    var hits = 0
    var kb = 0.0
    var moving = true
}

class Dropped(val x: Double, val kind: String, val rot: Double) { var life = 4.0 }
class Particle(var x: Double, var y: Double, var vx: Double, var vy: Double, var life: Double, val color: Long, val r: Double, var rot: Double)
/** A floating word ("Ối!", "Đỡ được!"): a UI string id, never baked into art. */
class Pop(val textId: String, val x: Double, var y: Double, var life: Double, val color: Long)

class Tutorial { var moved = false; var hit = false; var blocked = false; var windupSeen = false; var enemySeen = false }

/** Which control the first-use hand points at. */
enum class HandHint { NONE, MOVE, ATTACK, DEFEND }

/** Palette shared with the renderer for particles and pops (ARGB). */
object Palette {
    const val GLOW = 0xFFFFE24AL
    const val WHITE = 0xFFFFFFFFL
    const val INDIGO = 0xFF2B4C8CL
    const val RED = 0xFFD9342BL
}

/**
 * One run of a hero's mission screen: walk, stop-and-go fights, captions. A port of the
 * prototype's updatePlay / updateEnemies / heroAttack (index.html @203d73e), every number read
 * from [tuning]. The camera locks at each fight until the group is gone.
 */
class MissionRun(
    val mission: MissionFile,
    private val tuning: Tuning,
    private val rng: Mulberry32,
    private val sfx: (Sfx) -> Unit,
) {
    val ground get() = tuning["ground_y"]
    val hero = Hero(tuning["hero_start_x"])
    var t = 0.0; private set
    var cam = 0.0; private set
    var beat = 0; private set
    var phase = Phase.WALK; private set
    var lockX = 0.0; private set
    /** The scene line shown in the caption (one sentence per box). */
    var captionLine = 0; private set
    private val queue = ArrayDeque<Pair<String, Boolean>>()
    private var spawnT = 0.0
    private var endT = 0.0
    private var nextId = 1
    val enemies = mutableListOf<Enemy>()
    val dropped = mutableListOf<Dropped>()
    val parts = mutableListOf<Particle>()
    val pops = mutableListOf<Pop>()
    var stall = 0.0; private set
    var idle = 0.0; private set
    val tut = Tutorial()
    /** Beats whose type is not built yet and so play as a fight (D-08); the app logs them once. */
    val stubbedBeats = mutableListOf<Int>()

    val beats get() = mission.beats
    fun beatX(i: Int) = tuning["beat_start_x"] + i * tuning["beat_gap"]

    private fun hp(kind: String) = when (kind) {
        "shield" -> tuning.int("hp_shield"); "leader" -> tuning.int("hp_leader"); else -> tuning.int("hp_spear")
    }
    private fun speed(kind: String) = tuning["enemy_speed"] * (if (kind == "leader") tuning["leader_speed_mul"] else 1.0)

    /** The fight params of beat [i]; a type that is not built yet plays as one spear soldier (D-08). */
    fun fightParams(i: Int): FightParams {
        val b = beats[i]
        val p = if (b.type == "fight") ContentLoader.fightParams(b) else null
        if (p != null) return p
        if (i !in stubbedBeats) stubbedBeats += i
        return ContentLoader.fightParams(b) ?: FightParams(listOf("spear"), 1, emptyList())
    }

    fun startBeat(i: Int) {
        val p = fightParams(i)
        phase = Phase.FIGHT
        lockX = beatX(i) - tuning["lock_offset"]; cam = lockX
        queue.clear(); p.enemies.forEachIndexed { j, k -> queue.addLast(k to (j in p.fromLeft)) }
        spawnT = tuning["first_spawn_delay"]; stall = 0.0; endT = 0.0
    }

    private fun spawn(kind: String, left: Boolean) {
        val x = if (left) lockX - tuning["spawn_offset"] else lockX + WORLD_W + tuning["spawn_offset"]
        enemies += Enemy(nextId++, kind, x, if (left) 1 else -1)
        tut.enemySeen = true
    }

    private fun pop(id: String, x: Double, y: Double, color: Long) {
        pops += Pop(id, x.coerceIn(cam + 90, cam + WORLD_W - 90), y, 0.9, color)
    }

    private fun burst(x: Double, y: Double, n: Int, color: Long) {
        repeat(n) {
            val a = rng.next() * Math.PI * 2; val v = 160 + rng.next() * 260
            parts += Particle(x, y, cos(a) * v, sin(a) * v - 120, 0.5 + rng.next() * 0.4, color, 8 + rng.next() * 8, rng.next() * 6)
        }
    }

    private fun side(e: Enemy): Int = (e.x - hero.x).sign.toInt().let { if (it == 0) 1 else it }

    private fun updateEnemies(dt: Double) {
        val h = hero
        for (e in enemies) {
            e.t += dt
            if (e.kb != 0.0) { val m = e.kb * min(1.0, dt / tuning["kb_decay"]); e.x += m; e.kb -= m; if (abs(e.kb) < 2) e.kb = 0.0 }
            val side = side(e); val dist = abs(e.x - h.x)
            if (e.state != EnemyState.FLEE) e.face = -side
            // Only the nearest enemy on each side may strike; the others wait a little further back.
            val sameSide = enemies.filter { it.state != EnemyState.FLEE && side(it) == side }.sortedBy { abs(it.x - h.x) }
            val rank = sameSide.indexOf(e)
            val stand = tuning["enemy_reach"] - tuning["stand_gap"] + maxOf(0, rank) * tuning["queue_spacing"]
            when (e.state) {
                EnemyState.ENTER, EnemyState.APPROACH -> {
                    val target = h.x + side * stand; val dx = target - e.x
                    e.moving = abs(dx) > 6
                    val far = tuning["enter_to_approach_dist"]
                    if (e.moving) e.x += dx.sign * min(abs(dx), (if (e.state == EnemyState.ENTER || abs(dx) > far) tuning["enter_speed"] else speed(e.kind)) * dt)
                    if (e.state == EnemyState.ENTER && abs(dx) < far) { e.state = EnemyState.APPROACH; e.t = 0.0 }
                    if (e.state == EnemyState.APPROACH && rank == 0 && dist <= tuning["enemy_reach"] + tuning["windup_reach_extra"] &&
                        e.t > tuning["approach_min_time"] && enemies.none { it !== e && (it.state == EnemyState.WINDUP || it.state == EnemyState.STRIKE) }) {
                        e.state = EnemyState.WINDUP; e.t = 0.0; tut.windupSeen = true
                    }
                }
                EnemyState.WINDUP -> if (e.t >= windupTime(e.kind)) {
                    e.state = EnemyState.STRIKE; e.t = 0.0
                    if (dist <= tuning["enemy_reach"] + tuning["strike_reach_extra"]) {
                        if (h.def) {
                            e.kb = side * tuning["block_knock"]; sfx(Sfx.CLANG)
                            burst((e.x + h.x) / 2, ground - 140, 6, Palette.WHITE)
                            pop("ui.play.blocked", h.x, ground - 300, Palette.INDIGO); tut.blocked = true
                        } else {
                            h.x -= side * tuning["hero_pushback"]; h.hurt = tuning["hurt_time"]; sfx(Sfx.BONK)
                            pop("ui.play.oof", h.x, ground - 300, Palette.RED)
                        }
                    }
                }
                EnemyState.STRIKE -> if (e.t >= tuning["strike_time"]) { e.state = EnemyState.REST; e.t = 0.0 }
                EnemyState.REST -> {
                    val dx = h.x + side * stand - e.x
                    if (abs(dx) > 6) e.x += dx.sign * min(abs(dx), speed(e.kind) * tuning["rest_speed_mul"] * dt)
                    if (e.t >= tuning["enemy_rest"]) { e.state = EnemyState.APPROACH; e.t = tuning["approach_min_time"] }
                }
                EnemyState.HURT -> if (e.t >= tuning["hurt_recover"]) { e.state = EnemyState.APPROACH; e.t = 0.0 }
                EnemyState.FLEE -> e.x += e.face * tuning["flee_speed"] * dt
            }
        }
        val margin = tuning["flee_remove_margin"]
        enemies.removeAll { it.state == EnemyState.FLEE && (it.x < lockX - margin || it.x > lockX + WORLD_W + margin) }
    }

    /** The windup (telegraph) length: 1.1 s, the leader's × leader_telegraph_mul. */
    fun windupTime(kind: String) = tuning["telegraph"] * (if (kind == "leader") tuning["leader_telegraph_mul"] else 1.0)

    private fun heroAttack() {
        val h = hero
        sfx(Sfx.SWOOSH)
        for (e in enemies) {
            if (e.state == EnemyState.FLEE) continue
            val dx = e.x - h.x
            if ((dx.sign.toInt() == h.face && abs(dx) <= tuning["attack_range"]) || abs(dx) < tuning["attack_close_range"]) {
                e.hits++
                val dir = (if (dx != 0.0) dx.sign else h.face.toDouble())
                e.kb = dir * tuning["knockback"] * (if (e.kind == "leader") tuning["leader_knock_mul"] else 1.0)
                burst(e.x - (if (dx != 0.0) dx.sign else 1.0) * 30, ground - 160, 8, Palette.GLOW); sfx(Sfx.DRUM)
                stall = 0.0; tut.hit = true
                if (e.hits >= hp(e.kind)) {
                    e.state = EnemyState.FLEE; e.face = dir.toInt(); e.t = 0.0
                    dropped += Dropped(e.x, e.kind, (rng.next() - 0.5) * 0.3)
                } else { e.state = EnemyState.HURT; e.t = 0.0 }
            }
        }
    }

    /** One fixed step of the play screen. */
    fun update(dt: Double, input: InputFrame) {
        val h = hero; val fight = phase == Phase.FIGHT; val canAct = phase != Phase.CAPTION
        t += dt
        h.def = canAct && Action.DEFEND in input.held
        h.cool = maxOf(0.0, h.cool - dt); h.hurt = maxOf(0.0, h.hurt - dt)
        if (h.atk >= 0) {
            h.atk += dt / tuning["attack_time"]
            if (h.atk >= tuning["attack_hit_at"] && !h.hitDone) { heroAttack(); h.hitDone = true }
            if (h.atk >= 1) { h.atk = -1.0; h.cool = tuning["attack_cooldown"] }
        }
        if (canAct && !h.def && h.atk < 0 && h.cool <= 0 && Action.ATTACK in input.tapped) { h.atk = 0.0; h.hitDone = false }
        var mv = 0
        if (canAct && !h.def) { if (Action.LEFT in input.held) mv -= 1; if (Action.RIGHT in input.held) mv += 1 }
        h.walk = mv != 0
        if (mv != 0) {
            h.face = mv; h.x += mv * tuning["hero_speed"] * dt * (if (h.atk >= 0) tuning["attack_move_mul"] else 1.0)
            if (mv > 0) tut.moved = true; idle = 0.0
        } else idle += dt
        val edge = tuning["hero_edge_margin"]
        if (fight || phase == Phase.CAPTION) { h.x = h.x.coerceIn(lockX + edge, lockX + WORLD_W - edge); cam = lockX }
        else { h.x = maxOf(cam + edge, h.x); cam = maxOf(cam, h.x - tuning["camera_follow_offset"]) }
        if (phase == Phase.WALK && beat < beats.size && h.x >= beatX(beat)) startBeat(beat)
        if (phase == Phase.FIGHT) {
            stall += dt; spawnT -= dt
            val active = enemies.count { it.state != EnemyState.FLEE }
            if (queue.isNotEmpty() && active < fightParams(beat).maxActive && spawnT <= 0) {
                val (k, left) = queue.removeFirst(); spawn(k, left); spawnT = tuning["spawn_gap"]
            }
            updateEnemies(dt)
            if (queue.isEmpty() && enemies.isEmpty()) {
                endT += dt
                if (endT >= tuning["end_pause"]) { phase = Phase.CAPTION; captionLine = 0 }
            }
        } else updateEnemies(dt)
        for (p in parts) { p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 900 * dt; p.life -= dt; p.rot += dt * 6 }
        parts.removeAll { it.life <= 0 }
        for (p in pops) { p.y -= 60 * dt; p.life -= dt }
        pops.removeAll { it.life <= 0 }
        for (d in dropped) d.life -= dt * 0.25
        dropped.removeAll { it.life <= 0 }
    }

    /**
     * The caption's Next: the next scene line of this beat, else the next beat. Returns true when
     * the last beat's caption closes (the mission goes to its ending). The 5 s hints count from here.
     */
    fun captionNext(): Boolean {
        if (phase != Phase.CAPTION) return false
        idle = 0.0; stall = 0.0
        if (captionLine < beats[beat].scene.size - 1) { captionLine++; return false }
        beat++
        if (beat >= beats.size) return true
        phase = Phase.WALK
        return false
    }

    // ---- Hints (first-use hands, the 5 s stall pulse) ----
    val stalled get() = phase == Phase.FIGHT && stall > tuning["hint_delay"]
    val pulseRight get() = (!tut.moved && beat == 0) || (phase == Phase.WALK && idle > tuning["hint_delay"])
    val pulseAttack get() = stalled
    val hand: HandHint get() = when {
        phase == Phase.CAPTION -> HandHint.NONE
        !tut.moved && beat == 0 && phase == Phase.WALK -> HandHint.MOVE
        tut.enemySeen && !tut.hit -> HandHint.ATTACK
        tut.windupSeen && !tut.blocked && enemies.any { it.state == EnemyState.WINDUP } -> HandHint.DEFEND
        else -> HandHint.NONE
    }
    /** The enemy the stall arrow points at. */
    val stallTarget: Enemy? get() = if (!stalled) null else enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - hero.x) }

    // ---- Debug jumps (screenshots; players never see them) ----
    fun debugStartBeat(i: Int, telegraph: Boolean, caption: Boolean) {
        beat = i.coerceIn(0, beats.size - 1)
        tut.moved = true; tut.hit = true; tut.blocked = true; tut.windupSeen = true; tut.enemySeen = true
        hero.x = beatX(beat) + 10; startBeat(beat)
        if (telegraph) {
            tut.blocked = false
            val kinds = fightParams(beat).enemies
            if (queue.isNotEmpty()) queue.removeFirst()
            enemies += Enemy(99, kinds[0], hero.x + tuning["enemy_reach"], -1).also { it.state = EnemyState.WINDUP; it.moving = false }
            spawnT = 99.0
        }
        if (caption) { queue.clear(); phase = Phase.CAPTION; captionLine = 0 }
    }

    companion object {
        const val WORLD_W = 1280.0
        const val WORLD_H = 720.0
    }
}
