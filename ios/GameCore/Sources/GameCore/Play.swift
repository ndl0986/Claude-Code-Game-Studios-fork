import Foundation

/// Thumb-pad actions held or tapped this step.
public enum PadAction: String, Sendable, CaseIterable { case left, right, attack, defend }

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
    case beatStarted(Int), caption(Int), flee(FightParams.Kind), standIn(beat: Int, type: String)
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
public struct Tutorial: Sendable { public var moved = false, hit = false, blocked = false, windupSeen = false, enemySeen = false }

/// The mission's play screen: walk → fight → caption, beat after beat. A line-by-line port of the
/// prototype's updatePlay / updateEnemies / heroAttack, in the agreed frame order.
public struct PlayState: Sendable {
    public enum Phase: Sendable { case walk, fight, caption }

    public let tuning: Tuning
    public let beats: [Beat]
    public private(set) var rng: Mulberry32

    public private(set) var t = 0.0
    public var hero: Hero
    public private(set) var cam = 0.0
    public private(set) var beat = 0
    public private(set) var phase: Phase = .walk
    public private(set) var lockX = 0.0
    public internal(set) var queue: [(kind: FightParams.Kind, left: Bool)] = []
    public internal(set) var spawnT = 0.0
    public private(set) var endT = 0.0
    public var enemies: [Enemy] = []
    public private(set) var dropped: [Dropped] = []
    public private(set) var particles: [Particle] = []
    public private(set) var pops: [Pop] = []
    public private(set) var nextId = 1
    public private(set) var stall = 0.0
    public private(set) var idle = 0.0
    public var tut = Tutorial()
    /// Which line of the current beat's caption shows (one sentence per box).
    public private(set) var captionLine = 0
    /// True once the last caption closed: the flow moves to the ending.
    public private(set) var finished = false
    public private(set) var events: [PlayEvent] = []

    public init(tuning: Tuning, beats: [Beat], seed: Int) {
        self.tuning = tuning; self.beats = beats
        rng = Mulberry32(seed: seed)
        hero = Hero(x: tuning["hero_start_x"])
    }

    var ground: Double { tuning["ground_y"] }
    public func beatX(_ i: Int) -> Double { tuning["beat_start_x"] + Double(i) * tuning["beat_gap"] }
    func hp(_ k: FightParams.Kind) -> Int {
        switch k { case .spear: Int(tuning["hp_spear"]); case .shield: Int(tuning["hp_shield"]); case .leader: Int(tuning["hp_leader"]) }
    }
    func speed(_ k: FightParams.Kind) -> Double { tuning["enemy_speed"] * (k == .leader ? tuning["leader_speed_mul"] : 1) }

    /// The fight params for beat `i`; a beat type the slice doesn't build plays as a one-spear fight (P-02, debug stand-in).
    func fightParams(_ i: Int) -> FightParams {
        beats[i].fight ?? FightParams(enemies: [.spear], maxActive: 1, fromLeft: [])
    }

    /// Drains the events raised since the last call.
    public mutating func takeEvents() -> [PlayEvent] { defer { events = [] }; return events }

    // MARK: beats

    public mutating func startBeat(_ i: Int) {
        if beats[i].fight == nil {
            NSLog("[play] beat \(i + 1): type '\(beats[i].type)' is not built yet; playing it as a fight (P-02)")
            events.append(.standIn(beat: i + 1, type: beats[i].type))
        }
        let p = fightParams(i)
        phase = .fight; lockX = beatX(i) - tuning["lock_offset"]; cam = lockX
        queue = p.enemies.enumerated().map { (kind: $0.element, left: p.fromLeft.contains($0.offset)) }
        spawnT = tuning["first_spawn_delay"]; stall = 0; endT = 0
        events.append(.beatStarted(i + 1))
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

    // MARK: the fixed step (dt = 1/60)

    public mutating func update(_ dt: Double, _ input: StepInput) {
        let fight = phase == .fight, canAct = phase != .caption
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
        }
        // 5. move
        var mv = 0.0
        if canAct && !hero.def {
            if input.held.contains(.left) { mv -= 1 }
            if input.held.contains(.right) { mv += 1 }
        }
        hero.walk = mv != 0
        if mv != 0 {
            hero.face = mv
            hero.x += mv * tuning["hero_speed"] * dt * (hero.atk >= 0 ? tuning["attack_move_mul"] : 1)
            if mv > 0 { tut.moved = true }
            idle = 0
        } else { idle += dt }
        // 6. camera and bounds
        let edge = tuning["hero_edge_margin"]
        if fight || phase == .caption {
            hero.x = max(lockX + edge, min(lockX + 1280 - edge, hero.x)); cam = lockX
        } else {
            hero.x = max(cam + edge, hero.x); cam = max(cam, hero.x - tuning["camera_follow_offset"])
        }
        // 7. walk → beat start
        if phase == .walk && beat < beats.count && hero.x >= beatX(beat) { startBeat(beat) }
        // 8–11. spawn, enemies, fight end
        if phase == .fight {
            stall += dt
            spawnT -= dt
            let active = enemies.filter { $0.state != .flee }.count
            if !queue.isEmpty && active < fightParams(beat).maxActive && spawnT <= 0 {
                spawn(queue.removeFirst()); spawnT = tuning["spawn_gap"]
            }
            updateEnemies(dt)
            if queue.isEmpty && enemies.isEmpty {
                endT += dt
                if endT >= tuning["end_pause"] { phase = .caption; captionLine = 0; events.append(.caption(beat + 1)) }
            }
        } else { updateEnemies(dt) }
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
    }

    /// Resume from pause restarts the stuck-hint timers (Hints GDD rule 5).
    public mutating func resetHintTimers() { stall = 0; idle = 0 }

    /// "Next" on the caption: the next sentence box, or the next beat (walk), or the ending.
    public mutating func captionNext() {
        guard phase == .caption else { return }
        let lines = max(1, beats[beat].scene.count)
        if captionLine + 1 < lines { captionLine += 1; return }
        idle = 0; stall = 0 // the 5 s hints count from the caption closing (QC O2)
        beat += 1
        if beat >= beats.count { finished = true; return }
        phase = .walk
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

    /// The swing's hit check (F5). Returns whether anything was hit.
    mutating func heroAttack() -> Bool {
        events.append(.swoosh)
        var any = false
        let h = hero
        for i in enemies.indices where enemies[i].state != .flee {
            let dx = enemies[i].x - h.x
            guard (Self.sign(dx) == h.face && abs(dx) <= tuning["attack_range"]) || abs(dx) < tuning["attack_close_range"] else { continue }
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
        return any
    }

    /// Math.sign for a non-zero value (0 maps to 0).
    static func sign(_ v: Double) -> Double { v > 0 ? 1 : (v < 0 ? -1 : 0) }

    // MARK: hints (derived, P-04 item 6)

    /// No hit for `hint_delay` while fighting: pulse attack and point at the nearest enemy.
    public var stalled: Bool { phase == .fight && stall > tuning["hint_delay"] }
    /// Pulse ▶ before the first move, and after `hint_delay` idle while walking.
    public var rightPulse: Bool { (!tut.moved && beat == 0) || (phase == .walk && idle > tuning["hint_delay"]) }
    /// The nearest non-fleeing enemy while stalled (the arrow hint).
    public var stallTarget: Enemy? {
        guard stalled else { return nil }
        return enemies.filter { $0.state != .flee }.min { abs($0.x - hero.x) < abs($1.x - hero.x) }
    }
    public enum HandHint: Sendable { case right, attack, defend }
    /// The first-use hand: ▶, then attack, then defend during a windup.
    public var hand: HandHint? {
        guard phase != .caption else { return nil }
        if !tut.moved && beat == 0 && phase == .walk { return .right }
        if tut.enemySeen && !tut.hit { return .attack }
        if tut.windupSeen && !tut.blocked && enemies.contains(where: { $0.state == .windup }) { return .defend }
        return nil
    }
    /// The "go on" arrow after a caption.
    public var goArrow: Bool { phase == .walk && beat > 0 }

    // MARK: debug screen jumps (players never see them)

    /// Starts at beat `i`'s fight with the hints already learned.
    public mutating func debugJump(beat i: Int, stage: String?) {
        beat = max(0, min(beats.count - 1, i))
        tut = Tutorial(moved: true, hit: true, blocked: true, windupSeen: true, enemySeen: true)
        hero.x = beatX(beat) + 10
        startBeat(beat)
        if stage == "telegraph" {
            tut.blocked = false
            let k = queue.removeFirst().kind
            enemies.append(Enemy(id: 99, kind: k, x: hero.x + tuning["enemy_reach"], face: -1, state: .windup, t: 0, hits: 0, kb: 0, moving: false))
            spawnT = 99
        } else if stage == "caption" {
            queue = []; phase = .caption; captionLine = 0
        }
    }
}
