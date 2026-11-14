import Foundation

/// Thumb-pad actions held or tapped this step.
public enum PadAction: String, Sendable, CaseIterable { case left, right, attack, defend, special }

/// What the player did this fixed step: pads held, pads tapped (pressed this step), and a confirm tap.
public struct StepInput: Sendable {
    public var held: Set<PadAction> = []
    public var tapped: Set<PadAction> = []
    public var confirm = false
    public init(held: Set<PadAction> = [], tapped: Set<PadAction> = [], confirm: Bool = false) {
        self.held = held; self.tapped = tapped; self.confirm = confirm
    }
}

/// Colours the core names for pops and particles; the app maps them to the palette.
public enum FxColor: Sendable { case glow, white, indigo, red }

/// Sounds and moments the app reacts to.
public enum PlayEvent: Equatable, Sendable {
    case swoosh, drum, clang, bonk
    case beatStarted(Int), caption(Int), flee(FightParams.Kind), standIn(beat: Int, type: String), cheer
}

/// One enemy (state names and timings from the prototype, 203d73e).
public struct Enemy: Sendable {
    public enum State: String, Sendable { case enter, approach, windup, strike, rest, hurt, flee }
    public let id: Int
    public let kind: FightParams.Kind
    public var x: Double
    public var face: Double
    public var state: State = .enter
    public var t = 0.0
    public var hits = 0
    public var kb = 0.0
    public var moving = true
}

/// The hero.
public struct Hero: Sendable {
    public var x: Double
    public var face: Double = 1
    /// Swing progress 0…1, or -1 when not swinging.
    public var atk: Double = -1
    public var hitDone = false
    public var cool = 0.0
    public var hurt = 0.0
    public var def = false
    public var walk = false
}

public struct Particle: Sendable { public var x, y, vx, vy, life, r, rot: Double; public let color: FxColor }
public struct Pop: Sendable { public let key: String; public var x, y, life: Double; public let color: FxColor }
public struct Dropped: Sendable { public let x: Double; public let kind: FightParams.Kind; public let rot: Double; public var life: Double }

/// First-use flags for the hand hints.
public struct Tutorial: Sendable {
    public var moved = false, hit = false, blocked = false, windupSeen = false, enemySeen = false
    /// The flag pad's two teach flags (Hints GDD): held past 25% in hold-meter; tapped in training.
    public var holdPast25 = false, specialTapped = false
    public init(moved: Bool = false, hit: Bool = false, blocked: Bool = false, windupSeen: Bool = false, enemySeen: Bool = false) {
        self.moved = moved; self.hit = hit; self.blocked = blocked; self.windupSeen = windupSeen; self.enemySeen = enemySeen
    }
}

/// A training dummy (mission-flow: wobbles and springs back, never breaks).
public struct Dummy: Sendable { public let x: Double; public var hit = false; public var wobble = 0.0 }

/// The mission's play screen (mission-flow GDD, combat GDD, hints GDD): walk_to → beat_card
/// (non-fight) → beat_play → beat_end → caption (fight), beat after beat. The fight logic is a
/// line-by-line port of the prototype's updatePlay / updateEnemies / heroAttack, in the agreed
/// frame order; walk, hold-meter, training and reach-the-flag follow F2–F5 and the parity rules.
public struct PlayState: Sendable {
    public enum Phase: String, Sendable { case walkTo = "walk_to", beatCard = "beat_card", beatPlay = "beat_play", beatEnd = "beat_end", caption, dialogueLine = "dialogue_line" }
    public enum TrainingStage: String, Sendable { case dummies, blocks, special, done }

    public let tuning: Tuning
    public let beats: [Beat]
    public private(set) var rng: Mulberry32

    public private(set) var t = 0.0
    public var hero: Hero
    public private(set) var cam = 0.0
    public private(set) var beat = 0
    public private(set) var phase: Phase = .walkTo
    /// Fight beats and reach-the-flag encounters lock the camera at lockX.
    public private(set) var locked = false
    public private(set) var lockX = 0.0
    /// Combat Rule 15b: a training beat's camera cap (beat_play start until the next beat), else nil.
    public private(set) var trainCap: Double?
    public internal(set) var queue: [(kind: FightParams.Kind, left: Bool)] = []
    public internal(set) var spawnT = 0.0
    var maxActive = 1
    public private(set) var endT = 0.0
    public var enemies: [Enemy] = []
    public private(set) var dropped: [Dropped] = []
    public private(set) var particles: [Particle] = []
    public private(set) var pops: [Pop] = []
    public private(set) var nextId = 1
    public private(set) var stall = 0.0
    public private(set) var idle = 0.0
    public var tut = Tutorial()
    /// Beat card boxes (title, scene lines, goal) and caption boxes (scene lines).
    public private(set) var cardLine = 0
    public private(set) var captionLine = 0
    /// x_start: the hero's x when beat_play starts (F2, parity item 4).
    public private(set) var xStart = 0.0
    // hold-meter
    public private(set) var heldTotal = 0.0
    // training
    public private(set) var trainingStage: TrainingStage = .done
    public private(set) var dummies: [Dummy] = []
    public private(set) var blocksDone = 0
    public var partner: Enemy?
    // reach-the-flag
    public private(set) var encounterIndex = 0
    // dialogue (schema 1.4): the 0-based line showing, and ask taps made
    public private(set) var lineIndex = 0
    public private(set) var asksDone = 0
    /// True once the last beat's end (or caption) closes: the flow moves to the ending.
    public private(set) var finished = false
    public private(set) var events: [PlayEvent] = []

    public init(tuning: Tuning, beats: [Beat], seed: Int) {
        self.tuning = tuning; self.beats = beats
        rng = Mulberry32(seed: seed)
        hero = Hero(x: tuning["hero_start_x"])
    }

    var ground: Double { tuning["ground_y"] }
    public var currentBeat: Beat? { beat < beats.count ? beats[beat] : nil }

    /// F5: beatX(0) = beat_start_x; beatX(i+1) = beatX(i) + extent(i) + beat_gap.
    public func beatX(_ i: Int) -> Double {
        var x = tuning["beat_start_x"]
        for j in 0..<min(i, beats.count) { x += extent(beats[j]) + tuning["beat_gap"] }
        if i > beats.count { x += Double(i - beats.count) * tuning["beat_gap"] }
        return x
    }
    func extent(_ b: Beat) -> Double {
        switch b.type {
        case "walk", "reach-the-flag": (b.params.lengthScreens ?? 0) * 1280
        case "training": Double((b.params.dummies ?? 0) + 1) * dummySpacing
        default: 0
        }
    }
    var dummySpacing: Double { tuning["dummy_spacing"] }
    func hp(_ k: FightParams.Kind) -> Int {
        switch k { case .spear: Int(tuning["hp_spear"]); case .shield: Int(tuning["hp_shield"]); case .leader: Int(tuning["hp_leader"]) }
    }
    func speed(_ k: FightParams.Kind) -> Double { tuning["enemy_speed"] * (k == .leader ? tuning["leader_speed_mul"] : 1) }

    /// Mission flow Rule 7c (TASK-020 W12): training shows only the pads its current step uses, so no pad
    /// on screen does nothing; derived from the step, never read from data (same sets as Android).
    static func trainingPads(_ s: TrainingStage) -> Set<String> {
        switch s {
        case .dummies: return ["move", "attack"]
        case .blocks: return ["move", "attack", "defend"]
        case .special, .done: return ["move", "attack", "defend", "special"]
        }
    }

    /// The pads shown now (parity item 3): walk_to = move only; beat_play / beat_end = the beat's buttons; story boxes = none.
    public var visiblePads: Set<PadAction> {
        switch phase {
        case .walkTo: return [.left, .right]
        case .beatCard, .caption, .dialogueLine: return []
        case .beatPlay, .beatEnd:
            var out: Set<PadAction> = []
            var buttons = Set(currentBeat?.buttons ?? [])
            if currentBeat?.type == "training" { buttons.formIntersection(Self.trainingPads(trainingStage)) }
            for b in buttons {
                switch b { case "move": out.formUnion([.left, .right]); case "attack": out.insert(.attack); case "defend": out.insert(.defend); case "special": out.insert(.special); default: break }
            }
            return out
        }
    }

    /// The beat card's boxes: the scene lines, then the goal (the title is the card's header; parity with Android).
    public var cardTexts: [Text] { guard let b = currentBeat else { return [] }; return b.scene + (b.goal.map { [$0] } ?? []) }
    /// The hold meter, 0…1 (F3).
    public var meter: Double { guard let h = currentBeat?.params.holdSeconds, h > 0 else { return 0 }; return min(1, heldTotal / h) }
    /// The flag of a reach-the-flag beat.
    public var flagX: Double? { guard phase == .beatPlay || phase == .beatEnd, currentBeat?.type == "reach-the-flag" else { return nil }; return xStart + (currentBeat?.params.lengthScreens ?? 0) * 1280 }

    public mutating func takeEvents() -> [PlayEvent] { defer { events = [] }; return events }

    // MARK: beats

    /// beat_play starts: x_start is the hero's x now.
    public mutating func startPlay(_ i: Int) {
        let b = beats[i]
        phase = .beatPlay; xStart = hero.x; stall = 0; endT = 0
        switch b.type {
        case "fight":
            let p = b.fight ?? FightParams(enemies: [.spear], maxActive: 1, fromLeft: [])
            lock(at: beatX(i), p.enemies, p.maxActive, p.fromLeft)
        case "hold-meter": heldTotal = 0
        case "training":
            dummies = (0..<(b.params.dummies ?? 0)).map { Dummy(x: xStart + Double($0 + 1) * dummySpacing) }
            blocksDone = 0; partner = nil
            trainCap = max(cam, xStart - tuning["hero_edge_margin"]) // Rule 15b: fixed here; the camera stops following at it
            trainingStage = dummies.isEmpty ? nextTrainingStage(after: .dummies) : .dummies
            if trainingStage == .blocks { spawnPartner() }
            tut.enemySeen = tut.enemySeen || !dummies.isEmpty
        case "reach-the-flag": encounterIndex = 0
        default: break
        }
        events.append(.beatStarted(i + 1))
    }

    mutating func lock(at x: Double, _ kinds: [FightParams.Kind], _ max: Int, _ fromLeft: [Int]) {
        locked = true; lockX = x - tuning["lock_offset"]; cam = lockX
        queue = kinds.enumerated().map { (kind: $0.element, left: fromLeft.contains($0.offset)) }
        maxActive = max
        spawnT = tuning["first_spawn_delay"]; stall = 0; endT = 0
    }

    func nextTrainingStage(after s: TrainingStage) -> TrainingStage {
        let p = currentBeat?.params
        switch s {
        case .dummies: return (p?.blocks ?? 0) > 0 ? .blocks : (p?.finishSpecial == true ? .special : .done)
        case .blocks: return p?.finishSpecial == true ? .special : .done
        default: return .done
        }
    }

    mutating func advanceTraining() {
        trainingStage = nextTrainingStage(after: trainingStage)
        stall = 0
        if trainingStage == .blocks { spawnPartner() } else { partner = nil }
    }

    /// The friendly practice partner stands in front of the hero, facing him (parity item 4).
    mutating func spawnPartner() {
        let x = hero.x + hero.face * (tuning["enemy_reach"] - tuning["stand_gap"])
        // starts resting so its first windup comes approach_min_time later (parity with Android)
        partner = Enemy(id: -1, kind: .spear, x: x, face: -hero.face, state: .rest, t: tuning["enemy_rest"] - tuning["approach_min_time"], hits: 0, kb: 0, moving: false)
    }

    mutating func spawn(_ q: (kind: FightParams.Kind, left: Bool)) {
        let x = q.left ? lockX - tuning["spawn_offset"] : lockX + 1280 + tuning["spawn_offset"]
        enemies.append(Enemy(id: nextId, kind: q.kind, x: x, face: q.left ? 1 : -1))
        nextId += 1
        tut.enemySeen = true
    }

    mutating func pop(_ key: String, _ x: Double, _ y: Double, _ c: FxColor) {
        pops.append(Pop(key: key, x: max(cam + 90, min(cam + 1280 - 90, x)), y: y, life: 0.9, color: c))
    }

    mutating func burst(_ x: Double, _ y: Double, _ n: Int, _ c: FxColor) {
        for _ in 0..<n {
            let a = rng.next() * .pi * 2, v = 160 + rng.next() * 260
            let life = 0.5 + rng.next() * 0.4, r = 8 + rng.next() * 8, rot = rng.next() * 6
            particles.append(Particle(x: x, y: y, vx: cos(a) * v, vy: sin(a) * v - 120, life: life, r: r, rot: rot, color: c))
        }
    }

    /// Story boxes, beat_end's cheer, then the next beat (or the end of the mission).
    mutating func nextBeat() {
        locked = false; partner = nil; dummies = []; trainCap = nil
        idle = 0; stall = 0
        beat += 1
        phase = .walkTo // after the last beat too: beat = count, phase walk_to (agreed with Android in the shared trace)
        if beat >= beats.count { finished = true }
    }

    // MARK: the fixed step (dt = 1/60)

    public mutating func update(_ dt: Double, _ rawInput: StepInput) {
        // only the pads shown can act (hidden, not greyed)
        let vis = visiblePads
        let input = StepInput(held: rawInput.held.intersection(vis), tapped: rawInput.tapped.intersection(vis), confirm: rawInput.confirm)
        let canAct = phase == .walkTo || phase == .beatPlay || phase == .beatEnd
        t += dt
        // 1–2. defend, timers
        hero.def = canAct && input.held.contains(.defend)
        hero.cool = max(0, hero.cool - dt); hero.hurt = max(0, hero.hurt - dt)
        // 3. an ongoing swing: hit check at attack_hit_at, end at 1
        if hero.atk >= 0 {
            hero.atk += dt / tuning["attack_time"]
            if hero.atk >= tuning["attack_hit_at"] && !hero.hitDone { _ = heroAttack(); hero.hitDone = true }
            if hero.atk >= 1 { hero.atk = -1; hero.cool = tuning["attack_cooldown"] }
        }
        // 4. a new swing (a tap that can't start one is dropped)
        if canAct && !hero.def && hero.atk < 0 && hero.cool <= 0 && input.tapped.contains(.attack) {
            hero.atk = 0; hero.hitDone = false
            // G2 rule 2: a swing faces the nearest non-fleeing enemy (a tie keeps the facing)
            let live = enemies.filter { $0.state != .flee }.sorted { abs($0.x - hero.x) < abs($1.x - hero.x) }
            if let n = live.first, live.count < 2 || abs(live[1].x - hero.x) != abs(n.x - hero.x), n.x != hero.x {
                hero.face = Self.sign(n.x - hero.x)
            }
        }
        // 5. move
        var mv = 0.0
        if canAct && !hero.def {
            if input.held.contains(.left) { mv -= 1 }
            if input.held.contains(.right) { mv += 1 }
        }
        hero.walk = mv != 0
        if mv != 0 {
            if hero.atk < 0 { hero.face = mv } // G2 rule 2b: moving doesn't turn the hero mid-swing
            hero.x += mv * tuning["hero_speed"] * dt * (hero.atk >= 0 ? tuning["attack_move_mul"] : 1)
            if mv > 0 { tut.moved = true }
            idle = 0
        } else { idle += dt }
        // 6. camera and bounds
        let edge = tuning["hero_edge_margin"]
        if locked {
            // G2 rule 1: in a locked fight the hero keeps enemy_reach from each edge, so enemies can stand in view
            let inner = tuning["enemy_reach"] + edge
            hero.x = max(lockX + inner, min(lockX + 1280 - inner, hero.x)); cam = lockX
        } else {
            // Rule 15b in training: the hero is stopped (never moved) at cap + W − enemy_reach − edge, and the
            // camera follows right but never past the cap and never left. Same order as Android (trace parity).
            if let tc = trainCap { hero.x = min(hero.x, tc + 1280 - tuning["enemy_reach"] - edge) }
            hero.x = max(cam + edge, hero.x)
            let follow = hero.x - tuning["camera_follow_offset"]
            cam = max(cam, trainCap.map { min(follow, $0) } ?? follow)
        }
        // 7. walk_to → beat
        if phase == .walkTo && beat < beats.count && hero.x >= beatX(beat) {
            if beats[beat].type == "fight" { startPlay(beat) }
            else if beats[beat].type == "dialogue" { phase = .dialogueLine; lineIndex = 0; asksDone = 0; stall = 0; hero.walk = false; events.append(.beatStarted(beat + 1)) }
            else { phase = .beatCard; cardLine = 0; hero.walk = false }
        }
        // 8–11. the beat
        if phase == .beatPlay, let b = currentBeat {
            switch b.type {
            case "fight":
                fightStep(dt)
                if queue.isEmpty && enemies.isEmpty { phase = .beatEnd; endT = 0 }
            case "walk":
                if hero.x >= xStart + (b.params.lengthScreens ?? 0) * 1280 { phase = .beatEnd; endT = 0 }
                updateEnemies(dt)
            case "hold-meter":
                stall += dt
                if input.held.contains(.special) {
                    let before = heldTotal
                    heldTotal = min(b.params.holdSeconds ?? 0, heldTotal + dt)
                    if heldTotal > before { stall = 0 }
                    if meter > 0.25 { tut.holdPast25 = true }
                }
                if heldTotal >= (b.params.holdSeconds ?? 0) { phase = .beatEnd; endT = 0 }
            case "training":
                stall += dt
                if input.tapped.contains(.special) { tut.specialTapped = true }
                trainingStep(dt, input)
                if trainingStage == .done { phase = .beatEnd; endT = 0 }
            case "reach-the-flag":
                if !locked, let enc = b.params.encounters, encounterIndex < enc.count,
                   hero.x >= xStart + enc[encounterIndex].atScreen * 1280 {
                    let e = enc[encounterIndex]
                    lock(at: xStart + e.atScreen * 1280, e.enemies, e.maxActive, e.fromLeft) // trigger x − lock_offset exactly
                }
                if locked {
                    fightStep(dt)
                    if queue.isEmpty && enemies.isEmpty { locked = false; encounterIndex += 1; idle = 0 }
                } else {
                    updateEnemies(dt)
                    if let f = flagX, hero.x >= f { phase = .beatEnd; endT = 0 }
                }
            default: // P-02 stand-in: a type the app doesn't build ends at once (validation fails it in release)
                events.append(.standIn(beat: beat + 1, type: b.type)); phase = .beatEnd; endT = 0
            }
        } else if phase == .beatEnd, let b = currentBeat {
            updateEnemies(dt)
            endT += dt
            if endT >= tuning["end_pause"] {
                if b.type == "fight" { phase = .caption; captionLine = 0; events.append(.caption(beat + 1)) }
                else { events.append(.cheer); nextBeat() }
            }
        } else {
            if phase == .dialogueLine { stall += dt } // the stuck hint points at the ask button
            updateEnemies(dt)
        }
        if phase == .caption && input.confirm { captionNext() }
        // 12. effects
        for i in particles.indices {
            particles[i].x += particles[i].vx * dt; particles[i].y += particles[i].vy * dt
            particles[i].vy += 900 * dt; particles[i].life -= dt; particles[i].rot += dt * 6
        }
        particles.removeAll { $0.life <= 0 }
        for i in pops.indices { pops[i].y -= 60 * dt; pops[i].life -= dt }
        pops.removeAll { $0.life <= 0 }
        for i in dropped.indices { dropped[i].life -= dt * 0.25 }
        dropped.removeAll { $0.life <= 0 }
        for i in dummies.indices { dummies[i].wobble = max(0, dummies[i].wobble - dt * 2) }
    }

    /// Steps 8–10 of a locked fight: stall, spawn, enemies.
    mutating func fightStep(_ dt: Double) {
        stall += dt
        spawnT -= dt
        let active = enemies.filter { $0.state != .flee }.count
        if !queue.isEmpty && active < maxActive && spawnT <= 0 { spawn(queue.removeFirst()); spawnT = tuning["spawn_gap"] }
        updateEnemies(dt)
    }

    mutating func trainingStep(_ dt: Double, _ input: StepInput) {
        switch trainingStage {
        case .dummies:
            if dummies.allSatisfy(\.hit) { advanceTraining() }
        case .blocks:
            guard var p = partner else { spawnPartner(); return }
            p.t += dt
            if p.kb != 0 { let m = p.kb * min(1, dt / tuning["kb_decay"]); p.x += m; p.kb -= m; if abs(p.kb) < 2 { p.kb = 0 } }
            let pside = Self.sign(p.x - hero.x) == 0 ? 1 : Self.sign(p.x - hero.x)
            p.face = -pside
            switch p.state {
            case .rest:
                if p.t >= tuning["enemy_rest"] {
                    // it steps back in front of the hero at each windup start
                    p.x = hero.x + pside * (tuning["enemy_reach"] - tuning["stand_gap"])
                    p.state = .windup; p.t = 0; tut.windupSeen = true
                }
            case .windup:
                if p.t >= tuning["telegraph"] { // no leader multiplier
                    p.state = .strike; p.t = 0
                    let side = Self.sign(p.x - hero.x) == 0 ? 1 : Self.sign(p.x - hero.x)
                    if abs(p.x - hero.x) <= tuning["enemy_reach"] + tuning["strike_reach_extra"] {
                        if hero.def { // AC21: a block counts only if defend is held at strike resolve
                            blocksDone += 1; stall = 0; tut.blocked = true
                            p.kb = side * tuning["block_knock"]
                            events.append(.clang)
                            burst((p.x + hero.x) / 2, ground - 140, 6, .white)
                            pop("ui.play.blocked", hero.x, ground - 300, .indigo)
                        } else {
                            hero.x -= side * tuning["hero_pushback"]; hero.hurt = tuning["hurt_time"]
                            events.append(.bonk)
                            pop("ui.play.oof", hero.x, ground - 300, .red)
                        }
                    }
                }
            case .strike: if p.t >= tuning["strike_time"] { p.state = .rest; p.t = 0 }
            default: p.state = .rest; p.t = 0
            }
            partner = p
            if blocksDone >= (currentBeat?.params.blocks ?? 0) { advanceTraining() }
        case .special:
            if input.tapped.contains(.special) { advanceTraining() }
        case .done: break
        }
    }

    /// "Next" on a beat card: the next box, then beat_play.
    public mutating func cardNext() {
        guard phase == .beatCard else { return }
        if cardLine + 1 < cardTexts.count { cardLine += 1; return }
        idle = 0; stall = 0
        startPlay(beat)
    }

    /// "Next" on the caption: the next sentence box, then the next beat (or the ending).
    public mutating func captionNext() {
        guard phase == .caption else { return }
        let lines = max(1, beats[beat].scene.count)
        if captionLine + 1 < lines { captionLine += 1; return }
        nextBeat()
    }

    // MARK: dialogue (mission-flow 7d)

    public var dialogueLines: [BeatParams.DialogueLine] { currentBeat?.params.lines ?? [] }
    /// Whether the ask button replaces "Tiếp" on the line showing: at_line ≤ L < at_line + taps (L 1-based).
    public var askShowing: Bool {
        guard phase == .dialogueLine, let a = currentBeat?.params.ask else { return false }
        let l = lineIndex + 1
        return l >= a.atLine && l < a.atLine + a.taps
    }
    /// "Tiếp" on a dialogue line (ignored while the ask button shows): the next line, or the beat's end.
    public mutating func dialogueNext() {
        guard phase == .dialogueLine, !askShowing else { return }
        advanceDialogue()
    }
    /// The ask button: counts the tap and shows the next line.
    public mutating func dialogueAsk() {
        guard askShowing else { return }
        asksDone += 1; stall = 0
        advanceDialogue()
    }
    mutating func advanceDialogue() {
        if lineIndex + 1 < dialogueLines.count { lineIndex += 1 } else { phase = .beatEnd; endT = 0 }
    }
    /// Stuck on the ask button for hint_delay: the hint hand points at it.
    public var askHint: Bool { askShowing && stall > tuning["hint_delay"] }

    /// D-07 "Skip anyway": ends only the current story section (a beat card or a caption).
    public mutating func skipSection() {
        switch phase {
        case .dialogueLine: phase = .beatEnd; endT = 0
        case .beatCard: idle = 0; stall = 0; startPlay(beat)
        case .caption: nextBeat()
        default: break
        }
    }

    /// Resume from pause: the stuck-hint timers restart, and any windup restarts from 0 (AC19).
    public mutating func resetHintTimers() {
        stall = 0; idle = 0
        for i in enemies.indices where enemies[i].state == .windup { enemies[i].t = 0 }
        if partner?.state == .windup { partner!.t = 0 }
    }

    mutating func updateEnemies(_ dt: Double) {
        let reach = tuning["enemy_reach"], switchDist = tuning["enter_to_approach_dist"]
        for i in enemies.indices {
            var e = enemies[i]
            e.t += dt
            if e.kb != 0 {
                let m = e.kb * min(1, dt / tuning["kb_decay"])
                e.x += m; e.kb -= m
                if abs(e.kb) < 2 { e.kb = 0 }
            }
            enemies[i] = e // the prototype mutates in place: ranking below sees this frame's position
            let sx = e.x - hero.x
            let side: Double = sx > 0 ? 1 : (sx < 0 ? -1 : 1)
            let dist = abs(sx)
            if e.state != .flee { e.face = -side }
            // only the nearest enemy on each side may strike; the others queue further back
            let sameSide = enemies.enumerated()
                .filter { $0.element.state != .flee && Self.sign($0.element.x - hero.x) == side }
                .sorted { abs($0.element.x - hero.x) < abs($1.element.x - hero.x) }
            let rank = sameSide.firstIndex { $0.offset == i } ?? -1
            let stand = reach - tuning["stand_gap"] + Double(max(0, rank)) * tuning["queue_spacing"]
            switch e.state {
            case .enter, .approach:
                let dx = hero.x + side * stand - e.x
                e.moving = abs(dx) > 6
                if e.moving {
                    let v = (e.state == .enter || abs(dx) > switchDist) ? tuning["enter_speed"] : speed(e.kind)
                    e.x += Self.sign(dx) * min(abs(dx), v * dt)
                }
                if e.state == .enter && abs(dx) < switchDist { e.state = .approach; e.t = 0 }
                let busy = enemies.enumerated().contains { $0.offset != i && ($0.element.state == .windup || $0.element.state == .strike) }
                if e.state == .approach && rank == 0 && dist <= reach + tuning["windup_reach_extra"]
                    && e.t > tuning["approach_min_time"] && !busy {
                    e.state = .windup; e.t = 0; tut.windupSeen = true
                }
            case .windup:
                if e.t >= tuning["telegraph"] * (e.kind == .leader ? tuning["leader_telegraph_mul"] : 1) {
                    e.state = .strike; e.t = 0
                    if dist <= reach + tuning["strike_reach_extra"] {
                        if hero.def {
                            e.kb = side * tuning["block_knock"]
                            events.append(.clang)
                            burst((e.x + hero.x) / 2, ground - 140, 6, .white)
                            pop("ui.play.blocked", hero.x, ground - 300, .indigo)
                            tut.blocked = true
                        } else {
                            hero.x -= side * tuning["hero_pushback"]; hero.hurt = tuning["hurt_time"]
                            events.append(.bonk)
                            pop("ui.play.oof", hero.x, ground - 300, .red)
                        }
                    }
                }
            case .strike:
                if e.t >= tuning["strike_time"] { e.state = .rest; e.t = 0 }
            case .rest:
                let dx = hero.x + side * stand - e.x
                if abs(dx) > 6 { e.x += Self.sign(dx) * min(abs(dx), speed(e.kind) * tuning["rest_speed_mul"] * dt) }
                if e.t >= tuning["enemy_rest"] { e.state = .approach; e.t = tuning["approach_min_time"] }
            case .hurt:
                if e.t >= tuning["hurt_recover"] { e.state = .approach; e.t = 0 }
            case .flee:
                e.x += e.face * tuning["flee_speed"] * dt
            }
            enemies[i] = e
        }
        let m = tuning["flee_remove_margin"]
        enemies.removeAll { $0.state == .flee && ($0.x < lockX - m || $0.x > lockX + 1280 + m) }
    }

    /// The swing's hit check (F5), on enemies and, in training, on the dummies.
    mutating func heroAttack() -> Bool {
        events.append(.swoosh)
        var any = false
        let h = hero
        func inReach(_ x: Double) -> Bool {
            let dx = x - h.x
            return (Self.sign(dx) == h.face && abs(dx) <= tuning["attack_range"]) || abs(dx) < tuning["attack_close_range"]
        }
        for i in enemies.indices where enemies[i].state != .flee {
            let dx = enemies[i].x - h.x
            guard inReach(enemies[i].x) else { continue }
            any = true
            enemies[i].hits += 1
            let knock = tuning["knockback"] * (enemies[i].kind == .leader ? tuning["leader_knock_mul"] : 1)
            let dir = dx != 0 ? Self.sign(dx) : h.face
            enemies[i].kb = dir * knock
            burst(enemies[i].x - (dx != 0 ? Self.sign(dx) : 1) * 30, ground - 160, 8, .glow)
            events.append(.drum)
            stall = 0; tut.hit = true
            if enemies[i].hits >= hp(enemies[i].kind) {
                enemies[i].state = .flee; enemies[i].face = dir; enemies[i].t = 0
                dropped.append(Dropped(x: enemies[i].x, kind: enemies[i].kind, rot: (rng.next() - 0.5) * 0.3, life: 4))
                events.append(.flee(enemies[i].kind))
            } else { enemies[i].state = .hurt; enemies[i].t = 0 }
        }
        if trainingStage == .dummies && phase == .beatPlay {
            for i in dummies.indices where !dummies[i].hit && inReach(dummies[i].x) {
                dummies[i].hit = true; dummies[i].wobble = 1; any = true
                burst(dummies[i].x, ground - 160, 8, .glow); events.append(.drum)
                stall = 0; tut.hit = true
            }
            // the last dummy moves training on in the same frame as the hit (parity with Android)
            if dummies.allSatisfy(\.hit) { advanceTraining() }
        }
        return any
    }

    /// Math.sign for a non-zero value (0 maps to 0).
    static func sign(_ v: Double) -> Double { v > 0 ? 1 : (v < 0 ? -1 : 0) }

    // MARK: hints (hints GDD; derived)

    var isFightingNow: Bool { phase == .beatPlay && locked }
    /// No progress for `hint_delay` (strictly >) in a fight, encounter, hold-meter or training.
    public var stalled: Bool {
        guard phase == .beatPlay, let b = currentBeat else { return false }
        let active = locked || b.type == "hold-meter" || b.type == "training"
        return active && stall > tuning["hint_delay"]
    }
    /// The pad the stuck hint pulses.
    public var stuckPad: PadAction? {
        guard stalled, let b = currentBeat else { return nil }
        if locked { return .attack }
        if b.type == "hold-meter" { return .special }
        switch trainingStage { case .dummies: return .attack; case .blocks: return .defend; case .special: return .special; case .done: return nil }
    }
    var walking: Bool {
        phase == .walkTo || (phase == .beatPlay && !locked && (currentBeat?.type == "walk" || currentBeat?.type == "reach-the-flag"))
    }
    /// Pulse ▶ before the first move, and after `hint_delay` idle while walking (any movement resets).
    public var rightPulse: Bool { (!tut.moved && beat == 0 && phase == .walkTo) || (walking && idle > tuning["hint_delay"]) }
    /// The arrow target: the nearest enemy in a stalled fight, or the flag when stuck on a clear path.
    public var stallTarget: Enemy? {
        guard stalled, locked else { return nil }
        return enemies.filter { $0.state != .flee }.min { abs($0.x - hero.x) < abs($1.x - hero.x) }
    }
    /// Training stuck on the dummies: an arrow over the next one (parity with Android).
    public var stallDummyX: Double? { stalled && trainingStage == .dummies ? dummies.first { !$0.hit }?.x : nil }
    public var flagArrow: Bool { flagX != nil && !locked && idle > tuning["hint_delay"] && (flagX! - cam) < 1280 }
    public enum HandHint: Sendable { case right, attack, defend, special, holdSpecial }
    /// One teach hand at a time: move > attack > defend > special (hold hand until the meter passes 25%).
    public var hand: HandHint? {
        guard phase == .walkTo || phase == .beatPlay else { return nil }
        if !tut.moved && beat == 0 && phase == .walkTo { return .right }
        if tut.enemySeen && !tut.hit && phase == .beatPlay && (locked || trainingStage == .dummies) { return .attack }
        let windup = enemies.contains { $0.state == .windup } || partner?.state == .windup
        if tut.windupSeen && !tut.blocked && windup { return .defend }
        if phase == .beatPlay, currentBeat?.type == "hold-meter", !tut.holdPast25 || stalled { return .holdSpecial } // and again when stuck
        if phase == .beatPlay, trainingStage == .special, !tut.specialTapped { return .special }
        return nil
    }
    /// The "go on" arrow after a caption or a beat's end.
    public var goArrow: Bool { phase == .walkTo && beat > 0 }

    // MARK: debug screen jumps (players never see them)

    /// Starts at beat `i` (`stage`: telegraph, caption, card) with the hints already learned.
    public mutating func debugJump(beat i: Int, stage: String?) {
        beat = max(0, min(beats.count - 1, i))
        tut = Tutorial(moved: true, hit: true, blocked: true, windupSeen: true, enemySeen: true)
        hero.x = beatX(beat) + 10
        cam = hero.x - tuning["camera_follow_offset"]
        if beats[beat].type == "dialogue" { phase = .dialogueLine; lineIndex = 0; asksDone = 0; if stage == "ask", let a = beats[beat].params.ask { lineIndex = a.atLine - 1 }; return }
        if stage == "card" && beats[beat].type != "fight" { phase = .beatCard; cardLine = 0; return }
        startPlay(beat)
        // the telegraph jump also works on a reach-the-flag encounter (iOS-R1 note: TQT has no fight beat)
        if stage == "telegraph", !locked, let e = beats[beat].params.encounters?.first {
            hero.x = xStart + e.atScreen * 1280
            lock(at: hero.x, e.enemies, e.maxActive, e.fromLeft)
        }
        if stage == "telegraph" && locked {
            tut.blocked = false
            let k = queue.isEmpty ? FightParams.Kind.spear : queue.removeFirst().kind
            enemies.append(Enemy(id: 99, kind: k, x: hero.x + tuning["enemy_reach"], face: -1, state: .windup, t: 0, hits: 0, kb: 0, moving: false))
            spawnT = 99
        } else if stage == "blocks" && beats[beat].type == "training" {
            for i in dummies.indices { dummies[i].hit = true }
            tut.windupSeen = false; tut.blocked = false
            advanceTraining()
        } else if stage == "encounter", let e = beats[beat].params.encounters?.first {
            hero.x = xStart + e.atScreen * 1280
        } else if stage == "caption" && beats[beat].type == "fight" {
            queue = []; phase = .caption; captionLine = 0
        }
    }
}
