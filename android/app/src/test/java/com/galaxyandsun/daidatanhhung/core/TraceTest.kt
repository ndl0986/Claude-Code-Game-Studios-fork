package com.galaxyandsun.daidatanhhung.core

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import java.io.File
import kotlin.math.abs
import kotlin.math.round

/**
 * The shared cross-app trace (content/fixtures/trace-tqt.json, format agreed with game-dev-ios):
 * a fixed input script over the real Trần Quốc Toản mission, with the expected sim state every 30
 * updates. Both apps replay it; any mismatch is a parity bug.
 *
 * Generate: `TRACE_WRITE=<path> ./gradlew :app:testDebugUnitTest --tests '*TraceTest*'` runs a bot on
 * this core and writes the fixture. Every run replays the committed fixture when it is present.
 */
class TraceTest {
    private val dt = 1.0 / 60
    private val every = 30
    private val tolerance = 1e-6
    private val content = TestContent.load()
    private val tuning = Tuning.from(content.tuning)

    private class Sim(val run: MissionRun, val rng: Mulberry32)

    private fun sim(): Sim {
        val rng = Mulberry32(tuning.seed)
        return Sim(MissionRun(content.heroes.getValue("tran-quoc-toan").mission, tuning, rng) {}, rng)
    }

    // ---- Snapshot (keys and phase names as agreed: GDD state names) ----
    private fun r6(x: Double) = JsonPrimitive(round(x * 1e6) / 1e6)
    private fun phaseName(p: Phase) = when (p) {
        Phase.WALK -> "walk_to"; Phase.CARD -> "beat_card"; Phase.PLAY -> "beat_play"
        Phase.END -> "beat_end"; Phase.CAPTION -> "caption"; Phase.DIALOGUE -> "dialogue_line"
    }

    private fun enemy(e: Enemy, id: Int) = JsonObject(mapOf(
        "id" to JsonPrimitive(id), "kind" to JsonPrimitive(e.kind), "state" to JsonPrimitive(e.state.id),
        "x" to r6(e.x), "face" to JsonPrimitive(e.face), "hits" to JsonPrimitive(e.hits),
    ))

    private fun snapshot(s: Sim, frame: Int): JsonObject {
        val r = s.run; val h = r.hero
        val inMission = r.beat < r.beats.size
        val enemies = listOfNotNull(r.partner?.let { enemy(it, 0) }) + r.enemies.sortedBy { it.id }.map { enemy(it, it.id) }
        return JsonObject(mapOf(
            "frame" to JsonPrimitive(frame),
            "phase" to JsonPrimitive(phaseName(r.phase)),
            "beat" to JsonPrimitive(r.beat),
            "beat_id" to (if (inMission) JsonPrimitive(r.beats[r.beat].id) else JsonNull),
            "hero" to JsonObject(mapOf(
                "x" to r6(h.x), "face" to JsonPrimitive(h.face),
                "attacking" to JsonPrimitive(h.atk >= 0), "defending" to JsonPrimitive(h.def),
            )),
            "lock_x" to (r.lockX?.let { r6(it) } ?: JsonNull),
            "cam" to r6(r.cam), // trace 1.1: the sim camera after the step (spawn, flee removal, Combat Rule 15b)
            "line" to JsonPrimitive(r.lineIndex),
            "asks" to JsonPrimitive(r.asksDone),
            "training_step" to (if (inMission && r.beatType == BeatType.TRAINING) JsonPrimitive(r.trainingStep.name.lowercase()) else JsonNull),
            "held_total" to r6(r.heldTotal),
            "enemies" to JsonArray(enemies),
            "rng_draws" to JsonPrimitive(s.rng.draws),
            "mission_done" to JsonPrimitive(r.missionDone),
        ))
    }

    // ---- Script entries ----
    private sealed interface Entry
    private data class Frames(val n: Int, val hold: Set<Action>, val tap: Set<Action>) : Entry
    private data class Cmd(val name: String) : Entry

    private fun cmd(r: MissionRun, name: String): Boolean = when (name) {
        "card_next" -> r.cardNext()
        "caption_next" -> { val before = r.beat to r.captionLine; r.captionNext(); (r.beat to r.captionLine) != before }
        "dialogue_next" -> r.dialogueNext()
        "dialogue_ask" -> r.dialogueAsk()
        else -> error("unknown cmd $name")
    }

    private fun step(s: Sim, hold: Set<Action>, tap: Set<Action>) =
        s.run.update(dt, InputFrame().apply { held += hold; tapped += tap })

    // ---- The bot that writes the script (a child playing sensibly) ----
    private val uiWait = 30 // frames a "child" reads a card / line before tapping

    private fun botCmd(r: MissionRun, waited: Int): String? = if (waited < uiWait) null else when (r.phase) {
        Phase.CARD -> "card_next"
        Phase.CAPTION -> "caption_next"
        Phase.DIALOGUE -> if (r.dialogueButton == "ask") "dialogue_ask" else "dialogue_next"
        else -> null
    }

    private fun canSwing(h: Hero) = h.atk < 0 && h.cool <= 0

    /** Trace 1.1: frames of ▶ already held at the start of training (the softlock case, Combat Rule 15b). */
    private var overshoot = 0

    private fun botInput(r: MissionRun): Pair<Set<Action>, Set<Action>> {
        val h = r.hero
        val right = setOf(Action.RIGHT); val none = emptySet<Action>()
        if (r.phase == Phase.WALK) return right to none
        if (r.phase != Phase.PLAY) return none to none
        val fight = { list: List<Enemy> ->
            val live = list.filter { it.state != EnemyState.FLEE }
            when {
                live.any { it.state == EnemyState.WINDUP } -> setOf(Action.DEFEND) to none
                live.isEmpty() -> none to none
                else -> {
                    val near = live.minBy { abs(it.x - h.x) }
                    val d = abs(near.x - h.x)
                    if (d <= tuning["attack_range"] - 10) none to (if (canSwing(h)) setOf(Action.ATTACK) else none)
                    else (if (near.x > h.x) right else setOf(Action.LEFT)) to none
                }
            }
        }
        return when (r.beatType) {
            BeatType.WALK -> right to none
            BeatType.HOLD -> setOf(Action.SPECIAL) to none
            BeatType.TRAINING -> when (r.trainingStep) {
                TrainingStep.DUMMIES -> {
                    // First hold ▶ for 4 s (1 s pressed on the limit), into the cap and the hero's right limit; then walk back for each dummy.
                    if (overshoot < 240) { overshoot++; return right to none }
                    val d = r.dummies.filter { !it.down }.minByOrNull { abs(it.x - h.x) } ?: return none to none
                    val dx = d.x - h.x; val toward = if (dx > 0) right else setOf(Action.LEFT)
                    when {
                        abs(dx) > tuning["attack_range"] - 10 -> toward to none
                        (if (dx > 0) 1 else -1) != h.face -> toward to none
                        else -> none to (if (canSwing(h)) setOf(Action.ATTACK) else none)
                    }
                }
                TrainingStep.BLOCKS -> (if (r.partner?.state == EnemyState.WINDUP) setOf(Action.DEFEND) else none) to none
                TrainingStep.SPECIAL -> none to setOf(Action.SPECIAL)
                TrainingStep.DONE -> none to none
            }
            BeatType.REACH -> if (r.inEncounter) fight(r.enemies) else right to none
            BeatType.FIGHT -> fight(r.enemies)
            BeatType.DIALOGUE -> none to none
        }
    }

    /** Runs the bot to the end of the mission; returns the compressed script. */
    private fun generateScript(): List<Entry> {
        val s = sim(); val r = s.run; overshoot = 0
        val out = mutableListOf<Entry>()
        var waited = 0; var frames = 0
        while (!r.missionDone) {
            check(frames < 60 * 600) { "bot did not finish the mission (phase ${r.phase}, beat ${r.beat})" }
            botCmd(r, waited)?.let { c -> check(cmd(r, c)) { "bot cmd $c refused at frame $frames" }; out += Cmd(c); waited = 0 }
            val (hold, tap) = botInput(r)
            step(s, hold, tap); frames++; waited++
            val last = out.lastOrNull()
            if (tap.isEmpty() && last is Frames && last.tap.isEmpty() && last.hold == hold) out[out.size - 1] = last.copy(n = last.n + 1)
            else out += Frames(1, hold, tap)
        }
        return out
    }

    private class Replay(val expected: List<JsonObject>, val final: JsonObject, val refused: List<String>)

    private fun replay(script: List<Entry>): Replay {
        val s = sim(); var frame = 0
        val snaps = mutableListOf<JsonObject>(); val refused = mutableListOf<String>()
        for (e in script) when (e) {
            is Cmd -> if (!cmd(s.run, e.name)) refused += "${e.name} before frame ${frame + 1}"
            is Frames -> repeat(e.n) { k ->
                step(s, e.hold, if (k == 0) e.tap else emptySet()); frame++
                if (frame % every == 0) snaps += snapshot(s, frame)
            }
        }
        return Replay(snaps, snapshot(s, frame), refused)
    }

    // ---- Fixture JSON ----
    private fun actions(a: Set<Action>) = JsonArray(a.sortedBy { it.ordinal }.map { JsonPrimitive(it.name.lowercase()) })

    private fun scriptJson(script: List<Entry>) = JsonArray(script.map { e ->
        when (e) {
            is Cmd -> JsonObject(mapOf("cmd" to JsonPrimitive(e.name)))
            is Frames -> JsonObject(buildMap {
                put("frames", JsonPrimitive(e.n)); put("hold", actions(e.hold))
                if (e.tap.isNotEmpty()) put("tap", actions(e.tap))
            })
        }
    })

    private fun parseScript(a: JsonArray): List<Entry> = a.map { el ->
        val o = el.jsonObject
        o["cmd"]?.let { Cmd(it.jsonPrimitive.content) } ?: Frames(
            o.getValue("frames").jsonPrimitive.int,
            o["hold"]?.jsonArray?.map { Action.valueOf(it.jsonPrimitive.content.uppercase()) }?.toSet() ?: emptySet(),
            o["tap"]?.jsonArray?.map { Action.valueOf(it.jsonPrimitive.content.uppercase()) }?.toSet() ?: emptySet(),
        )
    }

    /** Equal within [tolerance] for numbers, exactly otherwise; returns the first difference's path. */
    private fun diff(a: JsonElement, b: JsonElement, path: String): String? = when {
        a is JsonObject && b is JsonObject ->
            if (a.keys != b.keys) "$path keys ${a.keys} vs ${b.keys}" else a.keys.firstNotNullOfOrNull { diff(a.getValue(it), b.getValue(it), "$path.$it") }
        a is JsonArray && b is JsonArray ->
            if (a.size != b.size) "$path size ${a.size} vs ${b.size}" else a.indices.firstNotNullOfOrNull { diff(a[it], b[it], "$path[$it]") }
        a is JsonPrimitive && b is JsonPrimitive && !a.isString && !b.isString && a.booleanOrNull == null && a.doubleOrNull != null && b.doubleOrNull != null ->
            if (abs(a.doubleOrNull!! - b.doubleOrNull!!) <= tolerance) null else "$path $a vs $b"
        else -> if (a == b) null else "$path $a vs $b"
    }

    @Test fun generateWhenAsked() {
        val out = System.getenv("TRACE_WRITE") ?: return
        val script = generateScript()
        val rp = replay(script)
        assertTrue("generated script refused: ${rp.refused}", rp.refused.isEmpty())
        assertTrue("mission not finished", rp.final["mission_done"]!!.jsonPrimitive.booleanOrNull == true)
        val fixture = JsonObject(mapOf(
            "schema_version" to JsonPrimitive("1.2"),
            "rule" to JsonPrimitive("cross-app sim parity: replay `script` over `mission` with `tuning`, Mulberry32(`seed`) and a fixed dt; " +
                "{frames,hold,tap} runs `frames` updates holding `hold`, with `tap` newly pressed on the first only; {cmd} runs between frames and must succeed " +
                "(card_next, caption_next, dialogue_next, dialogue_ask); after every update whose 1-based count is a multiple of `snapshot_every`, the state must equal " +
                "`expected` (numbers within `tolerance`, the rest exactly); `final` is the state after the last entry. Phases use the mission-flow GDD state names; " +
                "enemies are sorted by id (spawn order from 1 across the mission; the training partner is 0); training_step is null outside a training beat; " +
                "beat_id is null after the last beat; cam (1.1) is the sim camera after the step; 1.2: the training finish holds `finish_hold` (Mission flow Rule 7c) and the partner (id 0) re-enters from 1.2 × enemy_reach on the side away from the nearer screen edge to 110 beside the hero over the 0.67 s raise (quadratic ease-out), facing him. Generated by a bot on the Android core (TraceTest)."),
            "mission" to JsonPrimitive("data/heroes/tran-quoc-toan/mission.json"),
            "tuning" to JsonPrimitive("data/tuning.json"),
            "seed" to JsonPrimitive(tuning.seed),
            "dt" to JsonPrimitive(dt),
            "snapshot_every" to JsonPrimitive(every),
            "tolerance" to JsonPrimitive(tolerance),
            "script" to scriptJson(script),
            "expected" to JsonArray(rp.expected),
            "final" to rp.final,
        ))
        File(out).writeText(Json { prettyPrint = true }.encodeToString(JsonObject.serializer(), fixture) + "\n")
        println("trace: ${script.size} entries, ${rp.final["frame"]} frames, ${rp.expected.size} snapshots -> $out")
    }

    @Test fun replaysTheSharedTrace() {
        val file = File(TestContent.root, "fixtures/trace-tqt.json")
        assumeTrue("trace-tqt.json not on this branch yet", file.isFile)
        val f = TestContent.fixture("trace-tqt.json")
        assertEquals(tuning.seed, f.getValue("seed").jsonPrimitive.long)
        assertEquals(every, f.getValue("snapshot_every").jsonPrimitive.int)
        val rp = replay(parseScript(f.getValue("script").jsonArray))
        assertTrue("refused cmds: ${rp.refused}", rp.refused.isEmpty())
        val exp = f.getValue("expected").jsonArray
        assertEquals("snapshot count", exp.size, rp.expected.size)
        exp.indices.forEach { i -> diff(exp[i], rp.expected[i], "expected[$i]")?.let { throw AssertionError("trace mismatch at frame ${exp[i].jsonObject["frame"]}: $it") } }
        diff(f.getValue("final"), rp.final, "final")?.let { throw AssertionError("trace mismatch: $it") }
    }
}
