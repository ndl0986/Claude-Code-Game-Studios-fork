package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import com.galaxyandsun.daidatanhhung.core.content.FightParams
import com.galaxyandsun.daidatanhhung.core.content.MissionFile
import com.galaxyandsun.daidatanhhung.core.content.Beat
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonArray
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sign
import kotlin.math.sin

/** The four game actions a pad or key produces. */
enum class Action { LEFT, RIGHT, ATTACK, DEFEND, SPECIAL }

/** One fixed step's input: actions held now, and actions newly pressed this step. */
class InputFrame {
    val held = mutableSetOf<Action>()
    val tapped = mutableSetOf<Action>()
    fun clearTaps() = tapped.clear()
}

/** Sounds the simulation asks for; the platform layer plays them (placeholder tones in the slice). */
enum class Sfx { TAP, DRUM, CLANG, SWOOSH, BONK, CHIME, SOFT }

/**
 * Phases inside the play screen (mission-flow GDD state table): WALK = walk_to[i], CARD = beat_card[i]
 * (non-fight beats, before play), PLAY = beat_play[i], END = beat_end[i] (end_pause), CAPTION =
 * caption[i] (fight beats only, after play).
 */
enum class Phase { WALK, CARD, PLAY, END, CAPTION }

/** The beat types the slice implements (D-08 B). */
enum class BeatType(val id: String) { FIGHT("fight"), WALK("walk"), HOLD("hold-meter"), TRAINING("training"), REACH("reach-the-flag");
    companion object { fun of(id: String) = entries.firstOrNull { it.id == id } }
}

/** Training's three parts, in order (mission-flow rule 7, F4). */
enum class TrainingStep { DUMMIES, BLOCKS, SPECIAL, DONE }

/** A straw dummy in a training beat: knocked over by one hit. */
class Dummy(val x: Double) { var down = false; var t = 0.0 }

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

class Tutorial { var moved = false; var hit = false; var blocked = false; var windupSeen = false; var enemySeen = false; var specialTapped = false; var holdPast25 = false }

/** Which control the first-use hand points at. */
enum class HandHint { NONE, MOVE, ATTACK, DEFEND, SPECIAL_TAP, SPECIAL_HOLD }

/** Palette shared with the renderer for particles and pops (ARGB). */
object Palette {
    const val GLOW = 0xFFFFE24AL
    const val WHITE = 0xFFFFFFFFL
    const val INDIGO = 0xFF2B4C8CL
    const val RED = 0xFFD9342BL
}

/**
 * One run of a hero's mission screen (mission-flow GDD): walk_to → (beat_card for non-fight beats)
 * → beat_play → beat_end (end_pause) → caption (fight beats only) → next beat. Fight rules are a
 * port of the prototype's updatePlay / updateEnemies / heroAttack (index.html @203d73e), in the
 * agreed frame order; every number is read from [tuning].
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
    /** The camera lock of the current fight or encounter; null while the camera scrolls free. */
    var lockX: Double? = null; private set
    /** The box shown in a caption or beat card (one sentence per box). */
    var captionLine = 0; private set
    var cardLine = 0; private set
    private val queue = ArrayDeque<Pair<String, Boolean>>()
    private var maxActive = 1
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
    /** Beats whose type this app doesn't build (none today); computed once, never mutated by a getter. */
    val stubbedBeats: List<Int> = mission.beats.indices.filter { BeatType.of(mission.beats[it].type) == null }

    // ---- Per-beat play state ----
    /** Hero x when beat_play started (walk, training, reach-the-flag measure from here, F2). */
    var xStart = 0.0; private set
    /** hold-meter: total time the special pad was held (F3), never drains. */
    var heldTotal = 0.0; private set
    var trainingStep = TrainingStep.DONE; private set
    val dummies = mutableListOf<Dummy>()
    var blocksDone = 0; private set
    var partner: Enemy? = null; private set
    var bannerRaised = false; private set
    private var encounterNext = 0
    /** True while a reach-the-flag encounter holds the camera. */
    var inEncounter = false; private set

    val beats get() = mission.beats
    val currentBeat: Beat get() = beats[beat.coerceAtMost(beats.size - 1)]
    val beatType: BeatType get() = typeOf(beat)

    /** All five schema types are built, so the P-02 stub (an unknown type plays as a fight) is only a fallback. */
    fun typeOf(i: Int): BeatType = BeatType.of(beats[i].type) ?: BeatType.FIGHT

    private fun num(b: Beat, k: String) = (b.params[k] as? JsonPrimitive)?.content?.toDoubleOrNull()
    private fun bool(b: Beat, k: String) = (b.params[k] as? JsonPrimitive)?.content == "true"
    fun lengthScreens(i: Int) = num(beats[i], "length_screens") ?: 0.0
    fun holdSeconds(i: Int) = num(beats[i], "hold_seconds") ?: 1.0
    fun dummyCount(i: Int) = (num(beats[i], "dummies") ?: 0.0).toInt()
    fun blockCount(i: Int) = (num(beats[i], "blocks") ?: 0.0).toInt()
    fun finishSpecial(i: Int) = bool(beats[i], "finish_special")
    private fun encounters(i: Int): List<Pair<Double, FightParams>> =
        ((beats[i].params["encounters"] as? JsonArray) ?: JsonArray(emptyList())).map { e ->
            val o = e as JsonObject
            (o["at_screen"] as JsonPrimitive).content.toDouble() to ContentLoader.JSON.decodeFromJsonElement(FightParams.serializer(), JsonObject(o - "at_screen"))
        }
    fun encounterAt(i: Int) = encounters(i).map { it.first }

    /** The world length a beat's play covers, so the next beat starts after it. */
    private fun extent(i: Int): Double = when (typeOf(i)) {
        BeatType.WALK, BeatType.REACH -> lengthScreens(i) * WORLD_W
        BeatType.TRAINING -> (dummyCount(i) + 1) * tuning["dummy_spacing"]
        else -> 0.0
    }

    /**
     * Where beat i starts: beat_start_x, then each beat starts beat_gap after the end of the one
     * before (= beat_start_x + i × beat_gap when no beat has a length, as with 4 fights).
     */
    fun beatX(i: Int): Double {
        var x = tuning["beat_start_x"]
        for (j in 0 until i) x += extent(j) + tuning["beat_gap"]
        return x
    }
    /** The flag of a reach-the-flag beat (or the end of a walk). */
    val goalX get() = xStart + lengthScreens(beat) * WORLD_W

    fun fightParams(i: Int): FightParams {
        val b = beats[i]
        val p = if (b.type == "fight") ContentLoader.fightParams(b) else null
        return p ?: FightParams(listOf("spear"), 1, emptyList())
    }

    private fun hp(kind: String) = when (kind) {
        "shield" -> tuning.int("hp_shield"); "leader" -> tuning.int("hp_leader"); else -> tuning.int("hp_spear")
    }
    private fun speed(kind: String) = tuning["enemy_speed"] * (if (kind == "leader") tuning["leader_speed_mul"] else 1.0)

    /** Reaching beat i's start: fights go straight to play, other types show their card first. */
    private fun arriveAtBeat(i: Int) {
        if (typeOf(i) == BeatType.FIGHT) startPlay(i) else { phase = Phase.CARD; cardLine = 0 }
    }

    /** The card's boxes: the scene lines, then the goal (title is the card's header). */
    fun cardBoxes() = currentBeat.scene + currentBeat.goal

    fun startBeat(i: Int) = startPlay(i)

    private fun startPlay(i: Int) {
        phase = Phase.PLAY; stall = 0.0; idle = 0.0; endT = 0.0
        xStart = hero.x
        when (typeOf(i)) {
            BeatType.FIGHT -> {
                val p = fightParams(i)
                startGroup(beatX(i) - tuning["lock_offset"], p)
            }
            BeatType.WALK -> Unit
            BeatType.HOLD -> heldTotal = 0.0
            BeatType.TRAINING -> {
                dummies.clear(); blocksDone = 0; partner = null; bannerRaised = false
                repeat(dummyCount(i)) { k -> dummies += Dummy(xStart + (k + 1) * tuning["dummy_spacing"]) }
                trainingStep = if (dummies.isNotEmpty()) TrainingStep.DUMMIES else nextTrainingStep(TrainingStep.DUMMIES, i)
            }
            BeatType.REACH -> encounterNext = 0
        }
    }

    private fun nextTrainingStep(after: TrainingStep, i: Int): TrainingStep = when (after) {
        TrainingStep.DUMMIES -> if (blockCount(i) > 0) TrainingStep.BLOCKS else nextTrainingStep(TrainingStep.BLOCKS, i)
        TrainingStep.BLOCKS -> if (finishSpecial(i)) TrainingStep.SPECIAL else TrainingStep.DONE
        else -> TrainingStep.DONE
    }

    private fun advanceTraining() {
        stall = 0.0
        trainingStep = nextTrainingStep(trainingStep, beat)
        if (trainingStep == TrainingStep.BLOCKS) spawnPartner()
        if (trainingStep != TrainingStep.BLOCKS) partner = null
    }

    private fun spawnPartner() {
        partner = Enemy(0, "partner", hero.x + hero.face * (tuning["enemy_reach"] - tuning["stand_gap"]), -hero.face)
            .also { it.state = EnemyState.REST; it.moving = false; it.t = tuning["enemy_rest"] - tuning["approach_min_time"] }
    }

    /** A fight group: the fight beat itself, or one reach-the-flag encounter. Locks the camera. */
    private fun startGroup(lock: Double, p: FightParams) {
        lockX = lock; cam = lock
        queue.clear(); p.enemies.forEachIndexed { j, k -> queue.addLast(k to (j in p.fromLeft)) }
        maxActive = p.maxActive
        spawnT = tuning["first_spawn_delay"]; stall = 0.0
    }

    private fun spawn(kind: String, left: Boolean) {
        val lock = lockX ?: cam
        val x = if (left) lock - tuning["spawn_offset"] else lock + WORLD_W + tuning["spawn_offset"]
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

    /** Resolves a strike at the hero: blocked if defend is held at this instant, else a push-back. */
    private fun resolveStrike(e: Enemy, side: Int, dist: Double): Boolean {
        val h = hero
        if (dist > tuning["enemy_reach"] + tuning["strike_reach_extra"]) return false
        return if (h.def) {
            e.kb = side * tuning["block_knock"]; sfx(Sfx.CLANG)
            burst((e.x + h.x) / 2, ground - 140, 6, Palette.WHITE)
            pop("ui.play.blocked", h.x, ground - 300, Palette.INDIGO); tut.blocked = true; true
        } else {
            h.x -= side * tuning["hero_pushback"]; h.hurt = tuning["hurt_time"]; sfx(Sfx.BONK)
            pop("ui.play.oof", h.x, ground - 300, Palette.RED); false
        }
    }

    private fun updateEnemies(dt: Double) {
        val h = hero
        for (e in enemies) {
            e.t += dt
            if (e.kb != 0.0) { val m = e.kb * min(1.0, dt / tuning["kb_decay"]); e.x += m; e.kb -= m; if (abs(e.kb) < 2) e.kb = 0.0 }
            val side = side(e); val dist = abs(e.x - h.x)
            if (e.state != EnemyState.FLEE) e.face = -side
            // Only the nearest enemy on each side may strike; the others wait a little further back.
            // Raw sign, as the prototype's Math.sign(o.x − h.x) === side: an enemy exactly at the hero is on no side.
            val sameSide = enemies.filter { it.state != EnemyState.FLEE && (it.x - h.x).sign.toInt() == side }.sortedBy { abs(it.x - h.x) }
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
                EnemyState.WINDUP -> if (e.t >= windupTime(e.kind)) { e.state = EnemyState.STRIKE; e.t = 0.0; resolveStrike(e, side, dist) }
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
        val margin = tuning["flee_remove_margin"]; val lock = lockX ?: cam
        enemies.removeAll { it.state == EnemyState.FLEE && (it.x < lock - margin || it.x > lock + WORLD_W + margin) }
    }

    /** Training's friendly partner: practice strikes only, never hit by the hero (F4). */
    private fun updatePartner(dt: Double) {
        val p = partner ?: return
        val h = hero
        p.t += dt
        if (p.kb != 0.0) { val m = p.kb * min(1.0, dt / tuning["kb_decay"]); p.x += m; p.kb -= m; if (abs(p.kb) < 2) p.kb = 0.0 }
        val side = side(p); p.face = -side
        when (p.state) {
            EnemyState.REST -> if (p.t >= tuning["enemy_rest"]) {
                p.x = h.x + side * (tuning["enemy_reach"] - tuning["stand_gap"]) // steps back in front of the hero
                p.state = EnemyState.WINDUP; p.t = 0.0; tut.windupSeen = true
            }
            EnemyState.WINDUP -> if (p.t >= tuning["telegraph"]) {
                p.state = EnemyState.STRIKE; p.t = 0.0
                if (resolveStrike(p, side, abs(p.x - h.x))) { blocksDone++; if (blocksDone >= blockCount(beat)) advanceTraining() }
            }
            EnemyState.STRIKE -> if (p.t >= tuning["strike_time"]) { p.state = EnemyState.REST; p.t = 0.0 }
            else -> { p.state = EnemyState.REST; p.t = 0.0 }
        }
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
        if (phase == Phase.PLAY && beatType == BeatType.TRAINING && trainingStep == TrainingStep.DUMMIES) {
            for (d in dummies) {
                if (d.down) continue
                val dx = d.x - h.x
                if ((dx.sign.toInt() == h.face && abs(dx) <= tuning["attack_range"]) || abs(dx) < tuning["attack_close_range"]) {
                    d.down = true; tut.hit = true; stall = 0.0; sfx(Sfx.DRUM); burst(d.x, ground - 160, 8, Palette.GLOW)
                }
            }
            if (dummies.all { it.down }) advanceTraining()
        }
    }

    /** The buttons the HUD shows now (mission-flow rule 4): the beat's buttons in play, move while walking. */
    fun visibleButtons(): Set<String> = when (phase) {
        Phase.WALK -> setOf("move")
        Phase.PLAY, Phase.END -> currentBeat.buttons.toSet()
        else -> emptySet()
    }

    private fun allowed(a: Action, vis: Set<String>) = when (a) {
        Action.LEFT, Action.RIGHT -> "move" in vis
        Action.ATTACK -> "attack" in vis
        Action.DEFEND -> "defend" in vis
        Action.SPECIAL -> "special" in vis
    }

    /** One fixed step of the play screen (the agreed frame order). */
    fun update(dt: Double, input: InputFrame) {
        val h = hero
        val vis = visibleButtons()
        val held = input.held.filter { allowed(it, vis) }.toSet()
        val tapped = input.tapped.filter { allowed(it, vis) }.toSet()
        val canAct = phase == Phase.WALK || phase == Phase.PLAY || phase == Phase.END
        t += dt
        h.def = canAct && Action.DEFEND in held
        h.cool = maxOf(0.0, h.cool - dt); h.hurt = maxOf(0.0, h.hurt - dt)
        if (h.atk >= 0) {
            h.atk += dt / tuning["attack_time"]
            if (h.atk >= tuning["attack_hit_at"] && !h.hitDone) { heroAttack(); h.hitDone = true }
            if (h.atk >= 1) { h.atk = -1.0; h.cool = tuning["attack_cooldown"] }
        }
        if (canAct && !h.def && h.atk < 0 && h.cool <= 0 && Action.ATTACK in tapped) { h.atk = 0.0; h.hitDone = false }
        var mv = 0
        if (canAct && !h.def) { if (Action.LEFT in held) mv -= 1; if (Action.RIGHT in held) mv += 1 }
        h.walk = mv != 0
        if (mv != 0) {
            h.face = mv; h.x += mv * tuning["hero_speed"] * dt * (if (h.atk >= 0) tuning["attack_move_mul"] else 1.0)
            if (mv > 0) tut.moved = true; idle = 0.0
        } else idle += dt
        // Camera: locked during a fight or encounter (and the fight's caption), else it follows right.
        val edge = tuning["hero_edge_margin"]
        val lock = lockX
        if (lock != null) { h.x = h.x.coerceIn(lock + edge, lock + WORLD_W - edge); cam = lock }
        else { h.x = maxOf(cam + edge, h.x); cam = maxOf(cam, h.x - tuning["camera_follow_offset"]) }
        if (phase == Phase.WALK && beat < beats.size && h.x >= beatX(beat)) arriveAtBeat(beat)
        if (phase == Phase.PLAY) playStep(dt, held, tapped)
        else if (phase == Phase.END) {
            updateEnemies(dt)
            endT += dt
            if (endT >= tuning["end_pause"]) endBeat()
        } else updateEnemies(dt)
        for (p in parts) { p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 900 * dt; p.life -= dt; p.rot += dt * 6 }
        parts.removeAll { it.life <= 0 }
        for (p in pops) { p.y -= 60 * dt; p.life -= dt }
        pops.removeAll { it.life <= 0 }
        for (d in dropped) d.life -= dt * 0.25
        dropped.removeAll { it.life <= 0 }
        for (d in dummies) if (d.down) d.t += dt
    }

    private fun groupStep(dt: Double): Boolean {
        stall += dt; spawnT -= dt
        val active = enemies.count { it.state != EnemyState.FLEE }
        if (queue.isNotEmpty() && active < maxActive && spawnT <= 0) {
            val (k, left) = queue.removeFirst(); spawn(k, left); spawnT = tuning["spawn_gap"]
        }
        updateEnemies(dt)
        return queue.isEmpty() && enemies.isEmpty()
    }

    private fun playStep(dt: Double, held: Set<Action>, tapped: Set<Action>) {
        val goal = when (beatType) {
            BeatType.FIGHT -> groupStep(dt)
            BeatType.WALK -> { updateEnemies(dt); hero.x >= goalX }
            BeatType.HOLD -> {
                updateEnemies(dt)
                if (Action.SPECIAL in held) {
                    heldTotal = min(holdSeconds(beat), heldTotal + dt); stall = 0.0
                    if (heldTotal / holdSeconds(beat) > 0.25) tut.holdPast25 = true
                } else stall += dt
                heldTotal >= holdSeconds(beat)
            }
            BeatType.TRAINING -> {
                stall += dt
                updatePartner(dt)
                if (Action.SPECIAL in tapped) {
                    tut.specialTapped = true
                    if (trainingStep == TrainingStep.SPECIAL) { bannerRaised = true; sfx(Sfx.CHIME); advanceTraining() }
                }
                trainingStep == TrainingStep.DONE
            }
            BeatType.REACH -> {
                if (inEncounter) {
                    if (groupStep(dt)) { inEncounter = false; lockX = null; encounterNext++; stall = 0.0 }
                } else {
                    updateEnemies(dt)
                    val at = encounterAt(beat)
                    val trigger = if (encounterNext < at.size) xStart + at[encounterNext] * WORLD_W else Double.MAX_VALUE
                    if (hero.x >= trigger) { // parity note (a): lockX = trigger x − lock_offset
                        inEncounter = true
                        startGroup(trigger - tuning["lock_offset"], encounters(beat)[encounterNext].second)
                    }
                }
                !inEncounter && hero.x >= goalX
            }
        }
        if (goal) { phase = Phase.END; endT = 0.0 }
    }

    /** beat_end: a fight goes to its caption; any other beat cheers and goes on (no caption). */
    private fun endBeat() {
        if (beatType == BeatType.FIGHT) { phase = Phase.CAPTION; captionLine = 0; return }
        sfx(Sfx.CHIME); burst(hero.x, ground - 260, 10, Palette.GLOW)
        lockX = null; partner = null
        beat++
        phase = Phase.WALK
        missionDone = beat >= beats.size
    }

    /** True once the last beat has ended (the game goes to the ending). */
    var missionDone = false; private set

    /** A beat card's Next: the next box, then play. */
    fun cardNext(): Boolean {
        if (phase != Phase.CARD) return false
        idle = 0.0; stall = 0.0
        if (cardLine < cardBoxes().size - 1) { cardLine++; return true }
        startPlay(beat); return true
    }

    /** Skip the rest of the current story section (D-07): a card goes to play, a caption ends. */
    fun skipSection(): Boolean = when (phase) {
        Phase.CARD -> { startPlay(beat); idle = 0.0; stall = 0.0; true }
        Phase.CAPTION -> { captionLine = currentBeat.scene.size - 1; captionNext(); true }
        else -> false
    }

    /**
     * The caption's Next: the next scene line of this beat, else the next beat. Returns true when
     * the last beat's caption closes (the mission goes to its ending). The 5 s hints count from here.
     */
    fun captionNext(): Boolean {
        if (phase != Phase.CAPTION) return false
        idle = 0.0; stall = 0.0
        if (captionLine < currentBeat.scene.size - 1) { captionLine++; return false }
        lockX = null
        beat++
        if (beat >= beats.size) { missionDone = true; return true }
        phase = Phase.WALK
        return false
    }

    /** Resuming from pause (Hints rule 5, combat AC19): hint timers reset; a windup restarts its telegraph. */
    fun onResume() {
        stall = 0.0; idle = 0.0
        for (e in enemies) if (e.state == EnemyState.WINDUP) e.t = 0.0
        partner?.let { if (it.state == EnemyState.WINDUP) it.t = 0.0 }
    }

    fun resetHintTimers() = onResume()

    // ---- Hints (Hints & onboarding GDD; strictly > hint_delay) ----
    val stalled get() = phase == Phase.PLAY && stall > tuning["hint_delay"] && (beatType == BeatType.FIGHT || inEncounter || beatType == BeatType.TRAINING || beatType == BeatType.HOLD)
    val pulseRight get() = (!tut.moved && beat == 0 && phase == Phase.WALK) ||
        ((phase == Phase.WALK || (phase == Phase.PLAY && (beatType == BeatType.WALK || (beatType == BeatType.REACH && !inEncounter)))) && idle > tuning["hint_delay"])
    val pulseAttack get() = stalled && (beatType == BeatType.FIGHT || inEncounter || (beatType == BeatType.TRAINING && trainingStep == TrainingStep.DUMMIES))
    val pulseDefend get() = stalled && beatType == BeatType.TRAINING && trainingStep == TrainingStep.BLOCKS
    val pulseSpecial get() = stalled && ((beatType == BeatType.TRAINING && trainingStep == TrainingStep.SPECIAL) || beatType == BeatType.HOLD)
    val hand: HandHint get() = when {
        phase != Phase.WALK && phase != Phase.PLAY -> HandHint.NONE
        !tut.moved && beat == 0 && phase == Phase.WALK -> HandHint.MOVE
        phase == Phase.PLAY && (tut.enemySeen || (beatType == BeatType.TRAINING && trainingStep == TrainingStep.DUMMIES)) && !tut.hit -> HandHint.ATTACK
        tut.windupSeen && !tut.blocked && (enemies.any { it.state == EnemyState.WINDUP } || partner?.state == EnemyState.WINDUP) -> HandHint.DEFEND
        phase == Phase.PLAY && beatType == BeatType.TRAINING && trainingStep == TrainingStep.SPECIAL && !tut.specialTapped -> HandHint.SPECIAL_TAP
        phase == Phase.PLAY && beatType == BeatType.HOLD && (!tut.holdPast25 || stall > tuning["hint_delay"]) -> HandHint.SPECIAL_HOLD
        else -> HandHint.NONE
    }
    /** The stall arrow: the nearest enemy in a fight, the next dummy in training. */
    val stallTargetX: Double? get() = if (!stalled) null else when {
        beatType == BeatType.TRAINING && trainingStep == TrainingStep.DUMMIES -> dummies.firstOrNull { !it.down }?.x
        else -> enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - hero.x) }?.x
    }
    val stallTarget: Enemy? get() = if (!stalled) null else enemies.filter { it.state != EnemyState.FLEE }.minByOrNull { abs(it.x - hero.x) }

    // ---- Debug jumps (screenshots; players never see them) ----
    fun debugStartBeat(i: Int, telegraph: Boolean, caption: Boolean, card: Boolean = false) {
        beat = i.coerceIn(0, beats.size - 1)
        tut.moved = true; tut.hit = true; tut.blocked = true; tut.windupSeen = true; tut.enemySeen = true
        hero.x = beatX(beat) + 10; cam = maxOf(0.0, hero.x - tuning["camera_follow_offset"])
        if (card && typeOf(beat) != BeatType.FIGHT) { phase = Phase.CARD; cardLine = 0; return }
        startPlay(beat)
        if (telegraph && typeOf(beat) == BeatType.FIGHT) {
            tut.blocked = false
            val kinds = fightParams(beat).enemies
            if (queue.isNotEmpty()) queue.removeFirst()
            enemies += Enemy(99, kinds[0], hero.x + tuning["enemy_reach"], -1).also { it.state = EnemyState.WINDUP; it.moving = false }
            spawnT = 99.0
        }
        if (caption && typeOf(beat) == BeatType.FIGHT) { queue.clear(); phase = Phase.CAPTION; captionLine = 0 }
    }

    /** Debug: jump a training beat to its blocks or special step, or a hold to [meter] full. */
    fun debugTraining(step: String, meter: Double = 0.0) {
        tut.blocked = false; tut.specialTapped = false
        if (beatType == BeatType.HOLD) { heldTotal = holdSeconds(beat) * meter; tut.holdPast25 = meter > 0.25; return }
        if (beatType != BeatType.TRAINING) return
        dummies.forEach { it.down = true; it.t = 1.0 }
        trainingStep = TrainingStep.DUMMIES; advanceTraining()
        if (step == "special") { blocksDone = blockCount(beat); trainingStep = TrainingStep.BLOCKS; advanceTraining() }
        else partner?.let { it.state = EnemyState.WINDUP; it.t = 0.0; tut.windupSeen = true }
    }

    /** Debug: walk into reach-the-flag's first encounter. */
    fun debugEncounter() {
        if (beatType != BeatType.REACH) return
        hero.x = xStart + encounterAt(beat).first() * WORLD_W; cam = maxOf(cam, hero.x - tuning["camera_follow_offset"])
    }

    companion object {
        const val WORLD_W = 1280.0
        const val WORLD_H = 720.0
    }
}
