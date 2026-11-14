import SpriteKit
import GameCore

/// The one scene that draws every screen (ADR-0001). GameCore owns the rules; this class turns
/// touches into input, steps the core at a fixed 1/60 s, plays sounds and draws.
final class GameScene: SKScene {
    let game: Game
    let audio: Audio
    private var pads = TouchPads()
    private var layout = PadLayout(view: (w: 1280, h: 720), insets: (0, 0, 0, 0), padMin: 72)
    private var lastInsets = UIEdgeInsets.zero, lastSize = CGSize.zero

    private let world = SKNode(), fx = SKNode(), ui = SKNode(), worldHints = SKNode()
    /// Props under the motto bar (hud §3.3: the banner pole and pennant may pass behind the bar, never over it).
    private let props = SKNode()
    /// The world's frame: scaled by k and placed in the safe rect (Input Rule 1). Everything draws under it.
    private let root = SKNode()
    /// The world's top-left in view points, and k (points per world px), for the debug state's mapping.
    private var worldOrigin = CGPoint.zero
    /// The banner motto bar (HUD spec §3.3): above the fighters (z 4–5), under pops (fx 10), hints (12) and the HUD (100).
    private let bannerLayer = SKNode()
    private var backdropTheme = ""
    private var backdrop: SKNode?
    private var skyNode: SKNode?
    /// The hero at spec height 180 (HUD spec §3.3), the swing arc reaching attack_range (AC13); set up in didMove.
    private let hero: HeroNode
    private var enemyNodes: [Int: EnemyNode] = [:]

    private struct Button { let rect: CGRect; let id: String }
    private var buttons: [Button] = []
    private var menuTouches: [Int: String] = [:]
    /// The UITouch behind each pad hold: holds whose touch has ended are released every frame.
    private var padTouches: [Int: UITouch] = [:]
    private var uiKey = ""
    private var padNodes: [PadAction: SKNode] = [:]
    private var handNode: SKNode?
    private var cardNodes: [SKNode] = []

    private var last: TimeInterval = 0, acc = 0.0, clock = 0.0
    /// The screen and play phase last frame: a change cancels a pressed menu button (Input GDD).
    private var lastPlace = "" 
    private let step = 1.0 / 60
    /// How far (world px) backdrops and dimming run past the world on each side, to cover the outside area.
    static let bleed = 600.0
    /// The play phases drawn as story screens: no play sprites, no top stack (story-screens §5.2, hud §5; r8).
    static let storyPhases: Set<PlayState.Phase> = [.beatCard, .caption, .dialogueLine]
    /// What the last frame drew, for the debug state: play sprites, the beat dots, the placeholder still, the hints.
    private var spritesVisible = true, dotsVisible = false, shownPlaceholder: Box?
    private var placedHints: [String: Box] = [:]

    init(game: Game, audio: Audio) {
        self.game = game; self.audio = audio
        hero = HeroNode(scale: 180 / HeroNode.unitHeight, reach: game.tuning["attack_range"])
        super.init(size: CGSize(width: 1280, height: 720))
        // Input Rule 1: the 1280×720 world is fitted to the SAFE rect. The scene fills the whole view
        // (resizeFill, 1 unit = 1 pt) and `root` carries the world, scaled by k and placed in the safe rect;
        // outside it the backdrop (sky band, ground) runs on to the screen edges, never flat bars.
        scaleMode = .resizeFill
        backgroundColor = C.night
        addChild(root)
        root.addChild(world); world.addChild(hero); world.addChild(fx); world.addChild(worldHints); world.addChild(props)
        hero.zPosition = 5; fx.zPosition = 10; worldHints.zPosition = 12; props.zPosition = 3
        root.addChild(ui); ui.zPosition = 100
        root.addChild(bannerLayer); bannerLayer.zPosition = 8
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        relayout()
        #if DEBUG
        debugAttach(view)
        #endif
    }

    private func relayout() {
        guard let v = view else { return }
        let ins = v.safeAreaInsets
        guard ins != lastInsets || v.bounds.size != lastSize else { return }
        lastInsets = ins; lastSize = v.bounds.size
        let sw = v.bounds.width - ins.left - ins.right, sh = v.bounds.height - ins.top - ins.bottom
        let k = min(sw / 1280, sh / 720)
        worldOrigin = CGPoint(x: ins.left + (sw - 1280 * k) / 2, y: ins.top + (sh - 720 * k) / 2)
        root.setScale(k)
        root.position = CGPoint(x: worldOrigin.x, y: v.bounds.height - worldOrigin.y - 720 * k)
        // the world already sits in the safe rect, so the pad layout sees a 1280k × 720k view with no insets
        layout = PadLayout(view: (w: 1280 * k, h: 720 * k), insets: (0, 0, 0, 0), padMin: game.tuning["pad_min"], padGap: game.tuning["pad_gap"])
        game.quizLocksPerQuestion = QuizLayout(pad: layout).small // quiz §5.2: each question takes the lock at small k
        uiKey = ""
    }

    /// No stuck input: every held pad is released when the app loses focus or pauses.
    func appWillResignActive() { releaseAllInput(); game.backgrounded(); uiKey = "" }

    /// Input GDD Rule 11: every held pad is released on cancel, focus loss, pause, background and an
    /// audio route change or interruption.
    func releaseAllInput() { pads.clearAll(); padTouches = [:]; menuTouches = [:] }

    /// iOS-R2-03: a moved touch's end may never reach the scene; drop holds whose touch is over.
    private func reconcileTouches() {
        padTouches = padTouches.filter { $0.value.phase != .ended && $0.value.phase != .cancelled }
        pads.reconcile(live: Set(padTouches.keys))
    }

    // MARK: loop

    override func update(_ currentTime: TimeInterval) {
        relayout()
        reconcileTouches()
        let place = "\(game.screen)|\(game.play.phase)|\(game.skipWarning)"
        // Input GDD Rule 9/11: a screen or phase change only cancels a pressed menu button; held pads
        // stay held (hidden pads are filtered by the beat's buttons in the core, not released)
        if place != lastPlace { if !lastPlace.isEmpty { menuTouches = [:] }; lastPlace = place }
        var dt = last == 0 ? 0 : min(currentTime - last, 0.25)
        #if DEBUG
        dt *= debugTimeScale // `-timeScale 0.1`: slow motion for UI-test screenshots; the same fixed steps, only slower
        #endif
        last = currentTime; acc += dt; clock += dt
        while acc >= step {
            let input = pads.take()
            #if DEBUG
            debugHeld = input.held
            #endif
            game.step(step, input)
            acc -= step
        }
        #if DEBUG
        debugPublish()
        #endif
        playSounds()
        let key = uiKeyNow()
        if key != uiKey { uiKey = key; buildUI() }
        drawWorld()
        animateUI()
    }

    private func playSounds() {
        for e in game.takePlayEvents() {
            switch e {
            case .swoosh: audio.play(.swoosh)
            case .drum: audio.play(.drum)
            case .clang: audio.play(.clang)
            case .bonk: audio.play(.bonk)
            case .cheer: audio.play(.chime)
            case .quietEnd: audio.play(.soft) // the page-turn placeholder until sfx_ui_next exists (Android: SOFT)
            default: break
            }
        }
        for s in game.takeUiSounds() {
            switch s { case .tap: audio.play(.tap); case .chime: audio.play(.chime); case .soft: audio.play(.soft) }
        }
    }

    private func uiKeyNow() -> String {
        let p = game.play, q = game.quiz
        return [game.screen.rawValue, game.lang.rawValue, "\(game.storyLine)", "\(p.phase)", "\(p.captionLine)", "\(p.beat)",
                "\(q?.index ?? -1)", "\(q?.okIndex ?? -1)", "\(q?.wrong.sorted() ?? [])", "\(game.muted)", "\(game.stars)", "\(layout.scale)",
                "\(p.cardLine)", "\(p.trainingStage)", "\(p.lineIndex)", "\(p.askShowing)", "\(p.askHint)", "\(p.visiblePads.map(\.rawValue).sorted())", "\(game.skipWarning)", "\(p.goArrow)", "\(game.quizCanAdvance)", "\(game.pausedFrom)"].joined(separator: "|")
    }

    // MARK: touches

    private func ydown(_ t: UITouch) -> CGPoint { let p = t.location(in: root); return CGPoint(x: p.x, y: 720 - p.y) }
    private func tid(_ t: UITouch) -> Int { ObjectIdentifier(t).hashValue }
    private var padsLive: Bool { game.screen == .play && !game.skipWarning && !game.play.visiblePads.isEmpty }

    /// The ids of every touch still live in this event (iOS-R2-03/R3: the map is reconciled against it on
    /// every callback, so an up delivered under another UITouch, or lost, can't leave a pad held).
    private func live(_ event: UIEvent?, ending: Set<UITouch> = []) -> Set<Int> {
        Set((event?.allTouches ?? []).filter { $0.phase != .ended && $0.phase != .cancelled && !ending.contains($0) }.map(tid))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lv = live(event)
        for t in touches {
            let p = ydown(t)
            if padsLive, let a = layout.action(at: p.x, p.y, visible: game.play.visiblePads) { pads.apply(.began, id: tid(t), action: a, live: lv); padTouches[tid(t)] = t; continue } // pads fire on touch-down
            if let b = buttons.last(where: { $0.rect.contains(p) }) { menuTouches[tid(t)] = b.id }
        }
        pads.reconcile(live: lv)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lv = live(event)
        for t in touches { let p = ydown(t); pads.apply(.moved, id: tid(t), action: layout.action(at: p.x, p.y, visible: game.play.visiblePads), live: lv) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        var fired = false // two fingers: the first release in a frame wins (P-05)
        let lv = live(event, ending: touches)
        for t in touches {
            pads.apply(.ended, id: tid(t), action: nil, live: lv); padTouches[tid(t)] = nil
            guard let id = menuTouches.removeValue(forKey: tid(t)) else { continue }
            let p = ydown(t)
            if !fired, buttons.contains(where: { $0.id == id && $0.rect.contains(p) }) { fire(id, at: t.timestamp); fired = true } // menus fire on touch-up inside
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lv = live(event, ending: touches)
        for t in touches { pads.apply(.ended, id: tid(t), action: nil, live: lv); padTouches[tid(t)] = nil; menuTouches[tid(t)] = nil }
    }

    /// `press` is the activating touch's own time (Input GDD Rule 12): the advance debounce compares it,
    /// not the frame clock, which jumps when loading the next box stalls a frame.
    private func fire(_ id: String, at press: TimeInterval) {
        #if DEBUG
        debugLog.append(("fire:\(id)", press)); debugLog = Array(debugLog.suffix(120))
        debugFires.append((id, press, game.isLocked(at: press))); debugFires = Array(debugFires.suffix(16))
        #endif
        audio.volume = Float(game.tuning["volume"])
        switch id {
        case "start": game.start()
        case "next":
            #if DEBUG
            let before = debugPlace()
            game.next(at: press)
            debugPresses.append((press, debugPlace() != before)); debugPresses = Array(debugPresses.suffix(8))
            #else
            game.next(at: press)
            #endif
        case "lang": game.toggleLang()
        case "mute": game.toggleMute(); audio.muted = game.muted
        case "pause": releaseAllInput(); game.pause()
        case "resume": game.resume()
        case "home": game.home()
        case "toMap": game.toMap(at: press) // the entry lock applies (Input Rule 13); pause's Home is exempt
        case "replay": game.replay()
        case "ask": game.ask(at: press)
        case "skip": game.skip(at: press)
        case "skipAnyway": game.skipAnyway()
        case "keepReading": game.keepReading()
        default: if id.hasPrefix("card"), let j = Int(id.dropFirst(4)) { game.answer(j, at: press) }
        }
        uiKey = ""
    }

    // MARK: world (play)

    private func drawWorld() {
        let showWorld = game.screen == .play || (game.screen == .pause && game.pausedFrom == .play)
        world.isHidden = !showWorld
        skyNode?.isHidden = !showWorld
        guard showWorld else { return }
        let p = game.play, ground = game.tuning["ground_y"]
        let beatIdx = min(p.beat, max(0, p.beats.count - 1))
        let theme = p.beats.isEmpty ? "village" : p.beats[beatIdx].theme
        if theme != backdropTheme {
            backdropTheme = theme
            backdrop?.removeFromParent()
            let end = p.beatX(p.beats.count) + 2000
            let b = Backdrop.world(theme: theme, from: -400, to: end, ground: ground)
            b.position = CGPoint(x: 0, y: 720); b.zPosition = -10
            world.addChild(b); backdrop = b
            backgroundColor = Backdrop.sky(theme)
            skyNode?.removeFromParent()
            // the sky band runs past the world's sides and top to the screen edges (Rule 1 outside area)
            let sk = Backdrop.skyNode(theme, width: Self.bleed * 2 + 1280, height: game.tuning["ground_y"] + Self.bleed)
            sk.position = CGPoint(x: -Self.bleed, y: 720 + Self.bleed); sk.zPosition = -20
            root.addChild(sk); skyNode = sk
        }
        world.position.x = -p.cam
        // story-screens §5.2 (r8, r8b): beat cards, captions and dialogue show the background only, no play sprites
        // (hero, enemies, partner, dummies, the flag, pops, hints); the stills and portraits carry the characters
        spritesVisible = !Self.storyPhases.contains(p.phase)
        hero.isHidden = !spritesVisible
        for n in enemyNodes.values { n.isHidden = !spritesVisible }
        guard spritesVisible else { fx.removeAllChildren(); props.removeAllChildren(); worldHints.removeAllChildren(); placedHints = [:]; return }
        placedHints = [:]
        let t = p.t
        // Combat V/A strike contact (QC r5, render-only; parity with Android): the sim pushes the hero back
        // hero_pushback in the step a strike lands, so for the strike's first 0.05 s (≈ 3 frames) the hero is
        // drawn where he was hit, the padded tip on his chest, then slides to the sim position
        var contact = 0.0
        if p.hero.hurt > game.tuning["hurt_time"] - 0.06 {
            for e in p.enemies + (p.partner.map { [$0] } ?? []) where e.state == .strike && e.t < 0.05 {
                let side: Double = e.x >= p.hero.x ? 1 : -1
                contact = side * game.tuning["hero_pushback"] * max(0, 1 - e.t / 0.05)
            }
        }
        hero.position = D.p(p.hero.x + contact, ground)
        hero.update(face: p.hero.face, walk: p.hero.walk, defend: p.hero.def, attack: p.hero.atk >= 0 ? p.hero.atk : nil, hurt: p.hero.hurt > 0, t: t)
        var seen = Set<Int>()
        for e in p.enemies {
            seen.insert(e.id)
            let n = enemyNodes[e.id] ?? { let n = EnemyNode(kind: e.kind); n.zPosition = 4; world.addChild(n); enemyNodes[e.id] = n; return n }()
            n.position = D.p(e.x, ground); n.update(e, t: t)
            if e.state == .windup { // hud §3.3 (r8): the "!" never straddles the motto bar
                let b = HintPlacement.bang(.init(x: e.x, top: ground - 170, headY: ground - 142, headHalfWidth: 30), heroX: p.hero.x, cam: p.cam, banner: bannerShown)
                n.placeBubble(dx: b.x - e.x, dy: b.y - ground, side: b.side); placedHints["bang\(e.id)"] = b.rect
            }
        }
        for (id, n) in enemyNodes where !seen.contains(id) { n.removeFromParent(); enemyNodes[id] = nil }
        fx.removeAllChildren(); props.removeAllChildren()
        // training: straw dummies wobble and spring back (never break); the friendly partner in the hero's colours
        for d in p.dummies {
            let n = SKNode(); n.position = D.p(d.x, ground); n.zRotation = -sin(t * 20) * 0.25 * d.wobble
            n.setScale(130 / 206) // §3.3: the dummy is a body, drawn at spec height ≈ 130 (206 at scale 1)
            n.addChild(D.rr(-6, -170, 12, 170, 6, C.wood))
            n.addChild(D.ellipse(0, -110, 34, 56, d.hit ? SKColor(hex: 0xe8cf7a) : SKColor(hex: 0xd9b26a)))
            n.addChild(D.circle(0, -180, 26, SKColor(hex: 0xe8cf7a)))
            n.addChild(D.rr(-40, -130, 80, 10, 5, SKColor(hex: 0xb8902f)))
            fx.addChild(n)
        }
        if let pt = p.partner {
            let n = HeroNode(scale: 160 / HeroNode.unitHeight, reach: game.tuning["enemy_reach"] - game.tuning["stand_gap"]) // §3.3: partner ≤ 180
            n.update(face: pt.face, walk: false, defend: false, attack: pt.state == .strike ? 0.6 : (pt.state == .windup ? 0.05 : nil), hurt: false, t: t)
            n.position = D.p(pt.x, ground); fx.addChild(n)
            if pt.state == .windup {
                // the partner's "!" follows the same rule as an enemy's (hud §3.3, r8): above the head (160) or beside it
                let pl = HintPlacement.bang(.init(x: pt.x, top: ground - 160, headY: ground - 134, headHalfWidth: 28), heroX: p.hero.x, cam: p.cam, banner: bannerShown)
                let b = Art.bangBubble(side: pl.side); b.position = D.p(pl.x, pl.y); fx.addChild(b); placedHints["bang_partner"] = pl.rect
            }
        }
        if let fxX = p.flagX {
            // r8 leader call (parity with Android): on a banner beat the whole goal flag sits fully below the bar
            // (top ≥ bar bottom + 8 = 276), foot on the ground; under the bar's layer as well
            // leader call (parity with Android): a 180 pole (top y 290), the cloth sized on its own, 92 × 60 at the pole
            // top (y 295–355; ≈ 37 × 24 pt at k 0.40), not shrunk with the pole
            let h = flagHeight, (cw, ch) = h < 300 ? (Self.flagCloth.w, Self.flagCloth.h) : (115.0, 75.0)
            let f = SKNode(); f.position = D.p(fxX, ground)
            f.addChild(D.rr(-5, -h, 10, h, 5, SKColor(hex: 0x6a4a2a)))
            f.addChild(D.poly([(5, -h + 5), (5 + cw, -h + 5 + ch / 3), (5, -h + 5 + ch)], C.gold))
            props.addChild(f)
            placedHints["flag"] = Box(fxX - 5, ground - h, 10 + cw, h)
        }
        for d in p.dropped {
            let n = SKNode(); n.position = D.p(d.x, ground - 8); n.zRotation = -d.rot; n.alpha = min(1, d.life)
            switch d.kind {
            case .spear: n.addChild(D.rr(-75, -5, 150, 10, 5, SKColor(hex: 0x7a5530))); n.addChild(D.circle(80, 0, 15, C.padded))
            case .shield: n.addChild(D.rr(-60, -16, 120, 32, 8, C.teal))
            case .leader: n.addChild(D.rr(-60, -6, 120, 12, 6, SKColor(hex: 0x7a5530))); n.addChild(D.ellipse(70, 0, 30, 24, C.padded))
            }
            fx.addChild(n)
        }
        for q in p.particles {
            let s = D.star(q.r, color(q.color), C.goldDark); s.position = D.p(q.x, q.y); s.zRotation = -q.rot; fx.addChild(s)
        }
        for q in p.pops {
            // Ối! / Đỡ được! are the hero's pops: beside the head on the side away from the striker (the hero faces
            // it), at head height, so they never sit on the head (iOS QC r4 N1) and stay under the goal plate and
            // the HUD row. Render only: the core's pop position (shared with Android, not in the trace) is unchanged.
            // hud §3.3 pop contrast: an outline ≥ 3 px, ink on light skies, cream on the camp's dark sky
            let l = Font.outlined(game.ui(q.key), 40, color(q.color), outline: popOutline == .cream ? C.cream : C.ink)
            let sx = max(p.cam + 120, min(p.cam + 1280 - 120, q.x - p.hero.face * 150))
            l.position = D.p(sx, ground - 135); l.alpha = min(1, q.life * 2); fx.addChild(l)
        }
        worldHints.removeAllChildren()
        // the stuck arrow (hints Rule 4, hud §3.3, r8): star gold with an ink outline, never red; on a banner beat it is
        // fully below the bar, above its target only when it fits there, else from the side (HintPlacement)
        var arrows: [(String, HintPlacement.Target, Double?)] = []
        if let e = p.stallTarget { arrows.append(("arrow_enemy", .init(x: e.x, top: ground - 170, halfWidth: 40, bottom: ground), p.hero.x)) }
        if let dx = p.stallDummyX { arrows.append(("arrow_dummy", .init(x: dx, top: ground - 130, halfWidth: 24, bottom: ground), p.hero.x)) }
        if p.flagArrow, let fx = p.flagX { let cw = flagHeight < 300 ? Self.flagCloth.w : 115 // the pole + cloth box: x −5 … 5 + cw
            arrows.append(("arrow_flag", .init(x: fx + cw / 2, top: ground - flagHeight, halfWidth: cw / 2 + 5, bottom: ground), nil)) }
        let bounce = (0.5 + 0.5 * sin(t * 8)) * HintPlacement.arrowBounce
        for (id, target, heroX) in arrows {
            let pl = HintPlacement.arrow(target: target, heroX: heroX, cam: p.cam, banner: bannerShown)
            let a = arrowDown(); a.zRotation = -pl.angle // SpriteKit turns counter-clockwise: on the right it points left
            a.position = pl.side == 0 ? D.p(pl.x, pl.y - bounce) : D.p(pl.x + Double(pl.side) * bounce, pl.y)
            worldHints.addChild(a); placedHints[id] = pl.rect
        }
    }

    /// The banner-beat goal flag's cloth (r8): 92 × 60 at the pole top.
    static let flagCloth = (w: 92.0, h: 60.0)
    /// The goal flag's height: 180 on a banner beat (pole top y 290, fully below the bar; r8), else the full 300.
    private var flagHeight: Double {
        let p = game.play
        return p.beat < p.beats.count && p.beats[p.beat].usesBanner == true ? 180 : 300
    }

    /// The motto bar shows (Mission flow Rule 6): a banner beat while it plays.
    private var bannerShown: Bool {
        let p = game.play
        return (p.phase == .beatPlay || p.phase == .beatEnd) && p.beat < p.beats.count && p.beats[p.beat].usesBanner == true && game.hero.mission.banner != nil
    }

    /// hud §3.3 pop outline (QC r5 N1): chosen by the current sky band's own colours (SkyContrast), never by the
    /// theme's name: ink on light skies, cream on dark ones.
    private var popOutline: SkyContrast.Outline {
        guard let t = game.content.themes?.themes[backdropTheme] else { return .ink }
        return SkyContrast.popOutline(skyTop: t.skyBand.top, skyBottom: t.skyBand.bottom)
    }

    private func color(_ c: FxColor) -> SKColor {
        switch c { case .glow: C.glow; case .white: .white; case .indigo: C.indigo; case .red: C.red }
    }

    private func arrowDown() -> SKNode {
        // ASSET-034 placeholder: 64 tall, 60 wide, centred; star gold #FFC531 with an ink #3A2A20 outline ≥ 3 px (r8)
        D.poly([(-14, -32), (14, -32), (14, 2), (30, 2), (0, 32), (-30, 2), (-14, 2)], SKColor(hex: 0xFFC531), SKColor(hex: 0x3A2A20), 4)
    }

    private func handHint() -> SKNode {
        let n = SKNode()
        n.addChild(D.rr(-8, -10, 16, 44, 8, .white, C.ink, 4))
        n.addChild(D.rr(-26, -48, 52, 48, 18, .white, C.ink, 4))
        n.addChild(D.rr(-30, -42, 14, 30, 7, .white, C.ink, 4))
        n.addChild(D.rr(-22, -66, 44, 20, 8, C.red))
        return n
    }

    // MARK: UI (rebuilt when the screen, language or state key changes)

    /// SpriteView runs with ignoresSiblingOrder, so siblings draw by zPosition only: every UI node gets
    /// a z one above the last, so later nodes (dialogs) always draw over earlier ones (iOS-R1-01).
    private var uiZ: CGFloat = 0
    private func add(_ n: SKNode, _ x: Double, _ y: Double) { n.position = D.p(x, y); uiZ += 1; n.zPosition = uiZ; ui.addChild(n) }

    private func button(_ label: String, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ id: String, pulse: Bool = false, fill: SKColor = C.gold, size: Double = 34) {
        let n = SKNode()
        n.addChild(D.rr(-w / 2, -h / 2 + 6, w, h, h / 2.6, fill == C.gold ? C.goldDark : SKColor(hex: 0xc8b89a)))
        n.addChild(D.rr(-w / 2, -h / 2, w, h, h / 2.6, fill, .white, 4))
        n.addChild(Font.label(label, size, C.ink, width: w - 30))
        add(n, x + w / 2, y + h / 2)
        if pulse { n.run(.repeatForever(.sequence([.scale(to: 1.04, duration: 0.26), .scale(to: 1, duration: 0.26)]))) }
        buttons.append(Button(rect: CGRect(x: x, y: y, width: w, height: h), id: id))
    }

    private func langButton() {
        let l = layout.lang
        let n = SKNode()
        n.addChild(D.rr(0, 0, l.w, l.h, 30, SKColor(white: 1, alpha: 0.9), C.gold, 4))
        // the chip is ≥ pad_min (title.md §5.2), so the labels sit by proportion, not at fixed offsets
        let vi = Font.label("VI", 32, game.lang == .vi ? C.red : SKColor(hex: 0x9a8f86)); vi.position = CGPoint(x: l.w * 0.28, y: -l.h / 2)
        let bar = Font.label("|", 30, SKColor(hex: 0x9a8f86)); bar.position = CGPoint(x: l.w * 0.5, y: -l.h / 2)
        let en = Font.label("EN", 32, game.lang == .en ? C.red : SKColor(hex: 0x9a8f86)); en.position = CGPoint(x: l.w * 0.72, y: -l.h / 2)
        [vi, bar, en].forEach(n.addChild)
        add(n, l.x, l.y)
        buttons.append(Button(rect: CGRect(x: l.x, y: l.y, width: l.w, height: l.h), id: "lang"))
    }

    /// Input Rule 3 / W7: pause and sound top-left on every screen that has them; the title has sound only,
    /// in the pause slot (clear of the title panel).
    private func topLeftButtons(pause: Bool = true) {
        if pause { roundIcon(layout.pause, "pause", pauseIcon(layout.pause.r)); roundIcon(layout.mute, "mute", speakerIcon(layout.mute.r)) }
        else { roundIcon(layout.pause, "mute", speakerIcon(layout.pause.r)) }
    }

    private func roundIcon(_ c: Circle, _ id: String, _ draw: SKNode) {
        let n = SKNode()
        n.addChild(D.circle(0, 0, c.r, SKColor(white: 1, alpha: 0.85), C.gold, 4)); n.addChild(draw)
        add(n, c.cx, c.cy)
        buttons.append(Button(rect: CGRect(x: c.cx - c.r, y: c.cy - c.r, width: 2 * c.r, height: 2 * c.r), id: id))
    }

    private func pauseIcon(_ r: Double) -> SKNode {
        let n = SKNode(); n.addChild(D.rr(-r * 0.35, -r * 0.4, r * 0.24, r * 0.8, 4, C.ink)); n.addChild(D.rr(r * 0.11, -r * 0.4, r * 0.24, r * 0.8, 4, C.ink)); return n
    }
    private func speakerIcon(_ r: Double) -> SKNode {
        let n = SKNode()
        n.addChild(D.poly([(-r * 0.45, -r * 0.18), (-r * 0.2, -r * 0.18), (r * 0.12, -r * 0.45), (r * 0.12, r * 0.45), (-r * 0.2, r * 0.18), (-r * 0.45, r * 0.18)], C.ink))
        if game.muted { n.addChild(D.poly([(r * 0.25, -r * 0.22), (r * 0.3, -r * 0.27), (r * 0.6, r * 0.17), (r * 0.55, r * 0.22)], C.ink)); n.addChild(D.poly([(r * 0.55, -r * 0.22), (r * 0.6, -r * 0.17), (r * 0.3, r * 0.27), (r * 0.25, r * 0.22)], C.ink)) }
        else { for rad in [0.3, 0.5] { let p = CGMutablePath(); p.addArc(center: CGPoint(x: r * 0.15, y: 0), radius: r * rad, startAngle: -0.8, endAngle: 0.8, clockwise: false); n.addChild(D.shape(p, nil, C.ink, 4)) } }
        return n
    }

    /// A text box for a Text line; in a debug build a pending claim adds an `UNSIGNED Cxx` badge.
    private func textBox(_ t: Text, _ x: Double, _ y: Double, _ w: Double, _ size: Double, _ c: SKColor) {
        add(Font.label(t.text(game.lang), size, c, width: w, weight: 600), x, y) // body reading text: weight 600
        badge(t, 640, 16) // debug only, a strip at the top edge: never over the text (Android QC r1)
    }
    /// Debug only: pending claims of the Texts on screen, shown once in a strip at the top edge (iOS-R1-03).
    private var unsignedIds: [String] = []
    private func badge(_ t: Text, _ x: Double, _ y: Double) {
        guard game.isDebug else { return }
        for id in ClaimGate.unsigned(t, in: game.hero) where !unsignedIds.contains(id) { unsignedIds.append(id) }
    }
    private func badgeStrip() {
        guard game.isDebug, !unsignedIds.isEmpty else { return }
        let n = SKNode()
        let l = Font.label("UNSIGNED " + unsignedIds.sorted().joined(separator: " "), 16, .white)
        n.addChild(D.rr(-l.frame.width / 2 - 10, -12, l.frame.width + 20, 24, 10, SKColor(hex: 0xb4541e)))
        n.addChild(l)
        add(n, 640, 14)
    }

    /// D-07: the Skip button on story screens, and the kind warning over everything.
    /// "Bỏ qua": bottom-left on Tiếp's row, as tall as Tiếp (≥ pad_min, Input Rule 4); smaller only in width
    /// and weight (story-screens §5.2, QC r5 AC10).
    private func skipButton() {
        guard game.canSkip else { return }
        let b = StoryLayout(pad: layout).skip
        button(game.ui("ui.story.skip"), b.x, b.y, b.w, b.h, "skip", fill: C.cream, size: 30)
    }

    /// "Tiếp" (or the ask button in its slot): bottom-right, ≥ pad_min tall (story-screens §5.2).
    private func nextButton(_ sl: StoryLayout, label: String? = nil, id: String = "next") {
        button(label ?? game.ui("ui.btn.next"), sl.next.x, sl.next.y, sl.next.w, sl.next.h, id, pulse: true, size: 34)
    }
    private func skipWarningOverlay() {
        guard game.skipWarning else { return }
        buttons = []
        add(D.rr(-Self.bleed, -Self.bleed, 1280 + 2 * Self.bleed, 720 + 2 * Self.bleed, 0, SKColor(red: 42 / 255, green: 36 / 255, blue: 64 / 255, alpha: 0.75)), 0, 0)
        add(D.rr(-420, -170, 840, 340, 36, C.cream, C.gold, 6), 640, 330)
        add(D.drum(50, SKColor(hex: 0xc98a12, alpha: 0.5)), 640, 210)
        add(Font.label(game.ui("ui.story.skip_warning"), 37, C.ink, width: 780, weight: 600), 640, 300)
        button(game.ui("ui.story.keep_reading"), 250 + 70, 400, 300, 100, "keepReading", pulse: true)
        button(game.ui("ui.story.skip_confirm"), 660, 400, 300, 100, "skipAnyway", fill: C.cream)
    }

    private func buildUI() {
        ui.removeAllChildren(); bannerLayer.removeAllChildren(); buttons = []; padNodes = [:]; handNode = nil; cardNodes = []; uiZ = 0; unsignedIds = []
        switch game.screen {
        case .title: buildTitle()
        case .intro: buildStory(game.hero.mission.intro, ending: false)
        case .ending: buildStory(game.hero.mission.ending.lines, ending: true)
        case .play: buildPlayHUD()
        case .pause: buildPause()
        case .quiz: buildQuiz()
        case .results: buildResults()
        case .unlock: buildUnlock()
        }
        skipButton()
        badgeStrip()
        skipWarningOverlay()
    }

    private func buildTitle() {
        backgroundColor = Backdrop.sky("village")
        add(Backdrop.skyNode("village", width: 1280 + 2 * Self.bleed, height: game.tuning["ground_y"] + Self.bleed), -Self.bleed, -Self.bleed)
        let b = Backdrop.world(theme: "village", from: -Self.bleed, to: 1280 + Self.bleed, ground: game.tuning["ground_y"]); b.position = CGPoint(x: 0, y: 720); uiZ += 1; b.zPosition = uiZ; ui.addChild(b)
        // title.md §5.2 (D-27, D-27b): every box from GameCore's TitleLayout; no drum emblems, no standing hero
        let tl = TitleLayout(pad: layout, debug: game.isDebug)
        let row = tl.titleRow
        add(D.rr(0, 0, row.w, row.h, 36, C.panel, C.gold, 5), row.x, row.y) // the panel stays inside the row
        let title = Font.label(game.ui("ui.app.title"), 56, C.gold) // 1-line heading, 56/800
        if title.frame.width > row.w - 40 { title.setScale((row.w - 40) / title.frame.width) }
        add(title, row.midX, row.midY)
        topLeftButtons(pause: false)
        if let card = game.titleCard { heroCard(card, tl.card) }
        if game.isPlayable { button(game.ui("ui.btn.start"), tl.start.x, tl.start.y, tl.start.w, tl.start.h, "start", pulse: true, size: 34) }
        // the map-stub line and (debug only) the test-build line, under Start or beside it on a small-k phone
        for (b, key) in [(tl.mapStub, "ui.unlock.map_stub")] + (tl.debugLine.map { [($0, "ui.debug.subtitle")] } ?? []) {
            add(D.rr(0, 0, b.w, b.h, b.h / 2, SKColor(hex: 0xfff6e3, alpha: 0.92)), b.x, b.y)
            add(Font.label(game.ui(key), 28, C.ink, width: b.w - 20), b.midX, b.midY)
        }
        langButton()
    }

    /// The hero card (D-27 A, title.md §5.5): a cream plate with a drum-ring border, the portrait in a round
    /// drum-ring frame, the name, the saved best stars (filled vs outline) and the medal (gold vs outline).
    /// Display only: no button, no tone, no motion.
    private func heroCard(_ c: Game.HeroCard, _ b: Box) {
        add(D.rr(0, 0, b.w, b.h, 30, SKColor(hex: 0xfff6e3), C.ink, 3), b.x, b.y)
        add(D.rr(6, 6, b.w - 12, b.h - 12, 26, nil, C.goldDark, 3), b.x, b.y) // the thin drum-ring border
        let id = c.hero.mission.hero.id, px = b.x + 20 + 70, py = b.midY
        let crop = SKCropNode(); crop.maskNode = D.circle(0, 0, 70, .white)
        let pic = Pictures.node("pic.portrait_\(id)_hero_determined", size: 140 / 1.6); crop.addChild(pic)
        add(crop, px, py)
        add(D.circle(0, 0, 74, nil, C.goldDark, 8), px, py); add(D.circle(0, 0, 79, nil, C.ink, 3), px, py)
        let nx = b.x + 20 + 140 + 20 // the name box: 560 wide, 44 heading, 1 line
        let name = Font.label(c.hero.mission.hero.name.text(game.lang), 44, C.ink, width: 560, align: .left)
        add(name, nx, b.y + 60)
        for i in 0..<3 { // best stars at 48: filled up to the saved best, outline for the rest
            let got = i < c.stars
            add(D.star(24, got ? C.gold : SKColor(hex: 0xfff6e3), got ? C.goldDark : SKColor(hex: 0xb8a37a)), nx + 24 + Double(i) * 60, b.y + 125)
        }
        let medal = SKNode() // 56 px, right of the stars: gold if ever earned, else outline
        medal.addChild(D.circle(0, 0, 28, c.medal ? C.gold : SKColor(hex: 0xfff6e3), c.medal ? C.goldDark : SKColor(hex: 0xb8a37a), 4))
        medal.addChild(D.drum(19, c.medal ? C.goldDark : SKColor(hex: 0xb8a37a)))
        add(medal, nx + 3 * 60 + 40, b.y + 125)
    }

    /// The view's area outside the world, in world px on each side (Input Rule 1: the world sits in the safe rect).
    private func outsideMargins() -> (left: Double, top: Double, right: Double, bottom: Double) {
        guard let v = view else { return (0, 0, 0, 0) }
        let k = root.xScale
        guard k > 0 else { return (0, 0, 0, 0) }
        return (worldOrigin.x / k, worldOrigin.y / k,
                (v.bounds.width - worldOrigin.x) / k - 1280, (v.bounds.height - worldOrigin.y) / k - 720)
    }

    private func storyPicture(ending: Bool) {
        let crop = SKCropNode()
        let ph = 320.0
        crop.maskNode = D.rr(0, 0, 800, ph, 30, .white)
        let inner = SKNode()
        // SKView ignores sibling order: every layer gets an explicit z, sky at the back (iOS-R3-06)
        func layer(_ n: SKNode, _ z: CGFloat) { n.zPosition = z; inner.addChild(n) }
        if ending, Pictures.files[game.hero.mission.ending.pictureId] != nil {
            let pic = Pictures.node(game.hero.mission.ending.pictureId, size: 480); pic.position = CGPoint(x: 400, y: -ph / 2); layer(pic, 1)
        } else {
            // full-bleed (×2.25): the picture's ground sits at y 175 of 320, just above the text panel on screen
            let gy = 175.0
            layer(Backdrop.skyNode(ending ? "river" : "village", width: 800, height: ph), -1)
            let b = Backdrop.world(theme: ending ? "river" : "village", from: -240, to: 1100, ground: gy); b.position = CGPoint(x: -240, y: 0); layer(b, 1)
            if ending { layer(D.rr(0, 0, 800, ph, 0, SKColor(red: 1, green: 0.59, blue: 0.35, alpha: 0.3)), 2) }
            // r8 (story-screens §5.2): no play sprite behind the panel; the intro's placeholder still carries the hero
        }
        crop.addChild(inner)
        // P-06 / story-screens §5.2: full-bleed, the 800:320 picture scaled to cover the screen (and the outside
        // area of Input Rule 1), so there is no frame corner under the pause/sound block
        crop.maskNode = D.rr(0, 0, 800, ph, 0, .white)
        // iOS-R6-01: it covers the outside area too (the home-indicator band and the Dynamic Island sides),
        // from the real margins between the view and the world fitted to the safe rect (Input Rule 1)
        let m = outsideMargins()
        let cw = 1280 + m.left + m.right, ch = 720 + m.top + m.bottom
        let f = max(cw / 800, ch / ph)
        let pic = SKNode(); pic.addChild(crop); pic.setScale(f)
        add(pic, -m.left + cw / 2 - 400 * f, -m.top + ch / 2 - ph / 2 * f)
    }

    private func buildStory(_ lines: [Text], ending: Bool) {
        backgroundColor = C.night
        storyPicture(ending: ending)
        shownPlaceholder = nil
        if !ending { placeholderStill(.story) } // the ending keeps its own still (ASSET-016), no placeholder
        // story-screens §5.2 (QC r5): the picture is full-bleed behind everything (P-06); the text sits on a
        // panel (box 1000, H 167) bottom-anchored above Tiếp
        let sl = StoryLayout(pad: layout), pb = sl.panel(box: 1000, height: StoryLayout.storyHeight)
        add(D.rr(0, 0, pb.w, pb.h, 36, SKColor(red: 42 / 255, green: 36 / 255, blue: 64 / 255, alpha: 0.82), C.gold, 5), pb.x, pb.y)
        let line = lines[min(game.storyLine, lines.count - 1)]
        textBox(line, 640, pb.midY, 1000, 38, .white)
        nextButton(sl)
        topLeftButtons()
    }

    private func padIcon(_ kind: String, _ r: Double) -> SKNode {
        let n = SKNode()
        switch kind {
        case "left", "right":
            let d: Double = kind == "left" ? -1 : 1
            n.addChild(D.poly([(d * r * 0.45, 0), (-d * r * 0.25, -r * 0.4), (-d * r * 0.25, r * 0.4)], C.ink))
        case "move":
            for d in [-1.0, 1] { n.addChild(D.poly([(d * 12 + d * r * 0.3, 0), (d * 12 - d * r * 0.18, -r * 0.28), (d * 12 - d * r * 0.18, r * 0.28)], C.ink)) }
        case "defend":
            n.addChild(D.circle(0, -4, r * 0.55, SKColor(hex: 0xd8a657), C.goldDark, 4)); n.addChild(D.circle(0, -4, r * 0.14, C.gold, C.goldDark, 3))
        case "special": // the banner: plain cloth on a pole, never text (art bible §3)
            n.addChild(D.rr(-r * 0.35, -r * 0.55, 6, r * 1.1, 3, SKColor(hex: 0x6a4a2a)))
            n.addChild(D.poly([(-r * 0.3, -r * 0.5), (r * 0.45, -r * 0.4), (r * 0.45, r * 0.05), (-r * 0.3, -r * 0.05)], C.red))
        default: // attack: a staff and a swoosh, tangerine accent (TASK-004 art fix: not a pickaxe)
            let s = D.rr(-6, -r * 0.6, 12, r * 1.1, 6, C.wood); s.zRotation = 0.8; n.addChild(s)
            let p = CGMutablePath(); p.addArc(center: .zero, radius: r * 0.5, startAngle: 1.2, endAngle: 2.6, clockwise: false)
            n.addChild(D.shape(p, nil, SKColor(hex: 0xf28c28), 6))
        }
        return n
    }

    /// "Phần n / Part n" (story-screens §5.2, r8b): `ui.play.beat` + the 1-based beat index, on beat cards and captions;
    /// Nunito 800 28 px, star gold #FFC531 with an ink #3A2A20 outline ≥ 2 px, centred at max(minTop + 16, panel top − 24).
    private func partLabel(_ sl: StoryLayout, _ pb: Box) {
        let l = Font.outlined("\(game.ui("ui.play.beat")) \(game.play.beat + 1)", 28, SKColor(hex: 0xFFC531), outline: SKColor(hex: 0x3A2A20), px: 2.5)
        add(l, 640, max(sl.minTop + 16, pb.y - 24))
    }

    /// The placeholder still (story-screens §5.2, r8; AC12 "never only background"): the hero's determined portrait in
    /// a round drum-ring frame, in the box GameCore gives (intro/caption 256, beat card 208), or nothing when dropped.
    private func placeholderStill(_ kind: StoryLayout.Placeholder) {
        guard let b = StoryLayout.placeholder(kind) else { shownPlaceholder = nil; return }
        let r = b.w / 2, ring = r - 6, face = r - 11
        let still = SKNode()
        still.addChild(D.circle(0, 0, face, C.cream))
        let crop = SKCropNode(); crop.maskNode = D.circle(0, 0, face, .white)
        crop.addChild(Pictures.node("pic.portrait_\(game.heroId)_hero_determined", size: 2 * face / 1.6)); still.addChild(crop)
        still.addChild(D.circle(0, 0, ring, nil, C.goldDark, 9)); still.addChild(D.circle(0, 0, r - 1.5, nil, SKColor(hex: 0x3A2A20), 3))
        for (z, c) in still.children.enumerated() { c.zPosition = CGFloat(z) }
        add(still, b.midX, b.midY); shownPlaceholder = b
    }

    private func buildPlayHUD() {
        let p = game.play
        roundIcon(layout.pause, "pause", pauseIcon(layout.pause.r))
        roundIcon(layout.mute, "mute", speakerIcon(layout.mute.r))
        let n = p.beats.count, sx = layout.topStackCentre // 790 unless the pause/sound corner is wide
        // hud §5 / story-screens §5.2 (r8): story and dialogue screens show nothing of the top stack (no beat dots,
        // goal plate or banner bar), only the pause/sound corner
        dotsVisible = !Self.storyPhases.contains(p.phase)
        shownPlaceholder = nil
        for i in 0..<n where dotsVisible {
            let x = sx - Double(n - 1) * 45 + Double(i) * 90 // the top stack, centred at layout.topStackCentre (§3.3)
            let done = i < p.beat || (i == p.beat && p.phase == .caption)
            add(D.circle(0, 0, 30, done ? C.gold : SKColor(white: 1, alpha: 0.75), C.goldDark, 4), x, 60)
            add(D.drum(22, done ? C.ink : SKColor(red: 58 / 255, green: 42 / 255, blue: 31 / 255, alpha: 0.35)), x, 60)
        }
        if p.phase == .dialogueLine { buildDialogue(p); return }
        let sl = StoryLayout(pad: layout)
        if p.phase == .beatCard {
            // story-screens §5.2 (QC r5): the card panel (box 880, H 235) bottom-anchored above Tiếp, below the
            // pause/sound corner; the title row (60 + 8) inside its top, then 2 body lines
            let texts = p.cardTexts, pb = sl.panel(box: 880, height: StoryLayout.cardHeight)
            placeholderStill(.card)
            add(D.rr(0, 0, pb.w, pb.h, 36, C.panel, C.gold, 6), pb.x, pb.y)
            partLabel(sl, pb)
            add(Font.label(p.beats[p.beat].title.text(game.lang), 44, C.gold, width: 880), 640, pb.y + 32 + 30)
            let box = texts[min(p.cardLine, texts.count - 1)], by = pb.y + 32 + 68 + 103 / 2
            if p.cardLine >= texts.count - 1 { // the goal box: weight 800 like the goal line
                add(Font.label(box.text(game.lang), 38, .white, width: 880), 640, by); badge(box, 0, 0)
            } else { textBox(box, 640, by, 880, 38, .white) }
            nextButton(sl)
            return
        }
        if p.phase == .caption {
            let beat = p.beats[p.beat], pb = sl.panel(box: 880, height: StoryLayout.storyHeight)
            placeholderStill(.story)
            add(D.rr(0, 0, pb.w, pb.h, 36, C.panel, C.gold, 6), pb.x, pb.y)
            partLabel(sl, pb)
            if !beat.scene.isEmpty { textBox(beat.scene[min(p.captionLine, beat.scene.count - 1)], 640, pb.midY, 880, 38, .white) }
            nextButton(sl)
            return
        }
        if p.phase == .beatPlay || p.phase == .beatEnd, p.beat < p.beats.count, let goal = p.beats[p.beat].goal {
            // HUD spec §3.3: the goal plate, 920 × 56 with an 880 box (rules fit.goal), top at dots bottom + 4 (96),
            // centred on x 790, at the same place on every beat (AC10); cream for every sky (iOS-R3-05)
            let pw = layout.topStackWidth // 920, narrower on a small-k phone (§3.3); text box = plate − 40
            add(D.rr(-pw / 2, -28, pw, 56, 28, SKColor(hex: 0xfff6e3, alpha: 0.9)), sx, 124)
            add(Font.label(goal.text(game.lang), 37, C.ink, width: pw - 40), sx, 124)
        }
        if p.phase == .beatPlay || p.phase == .beatEnd, p.beat < p.beats.count, p.beats[p.beat].usesBanner == true, let b = game.hero.mission.banner {
            // Mission flow Rule 6 / HUD spec §3.3 (W9): the motto on a vermilion bar in the sky band, 920 × 112 fixed
            // (2 lines of 37 at 1.35 + padding) in every language, top 156, centred on x 790; gold text 880 @ 37/800.
            // Its own layer: above the fighters, under pops, the "!" and hints, and the HUD buttons.
            let bar = SKNode(); bar.position = D.p(sx, 212)
            let bw = layout.topStackWidth
            bar.addChild(D.rr(-bw / 2, -56, bw, 112, 18, SKColor(hex: 0xD64A2E), C.ink, 4))
            // gold text with an ink outline ≥ 2 px (hud §3.3, QC r5: gold on vermilion alone is 2.72:1)
            let l = Font.outlined(b.text(game.lang), 37, SKColor(hex: 0xFFC531), outline: C.ink, px: 2.5, width: bw - 40); l.zPosition = 1; bar.addChild(l)
            bannerLayer.addChild(bar)
            badge(b, sx + bw / 2 - 60, 156)
        }
        for (a, c, kind, label) in [(PadAction.left, layout.left, "left", nil), (.right, layout.right, "right", nil),
                                    (.defend, layout.defend, "defend", "ui.pad.defend"), (.attack, layout.attack, "attack", "ui.pad.attack"),
                                    (.special, layout.special, "special", "ui.pad.special")] as [(PadAction, Circle, String, String?)] where p.visiblePads.contains(a) {
            let pad = SKNode()
            let halo = D.circle(0, 0, c.r + 14, SKColor(red: 1, green: 226 / 255, blue: 74 / 255, alpha: 0.55)); halo.name = "halo"; pad.addChild(halo)
            pad.addChild(D.circle(0, -6, c.r, SKColor(red: 58 / 255, green: 42 / 255, blue: 31 / 255, alpha: 0.35)))
            let face = D.circle(0, 0, c.r, SKColor(hex: 0xfff6e3, alpha: 0.88), C.gold, 6); face.name = "face"; pad.addChild(face)
            let ic = padIcon(kind, c.r); if label != nil { ic.position.y = c.r * 0.14 }; pad.addChild(ic)
            if let label { let l = Font.label(game.ui(label), 28, C.ink); l.position.y = -c.r * 0.6; pad.addChild(l) }
            if a == .special {
                let ring = SKShapeNode(); ring.name = "meter"; ring.strokeColor = C.gold; ring.lineWidth = 12; ring.lineCap = .round; ring.zPosition = 2
                pad.addChild(ring)
            }
            add(pad, c.cx, c.cy)
            padNodes[a] = pad
        }
        let hand = handHint(); hand.isHidden = true; uiZ += 1; hand.zPosition = uiZ + 500; ui.addChild(hand); handNode = hand
        if p.goArrow {
            let a = D.poly([(-60, -22), (10, -22), (10, -50), (64, 0), (10, 50), (10, 22), (-60, 22)], C.gold, .white, 5)
            a.name = "go"; add(a, 1060, 300)
            add(Font.label(game.ui("ui.btn.go"), 32, C.ink), 1060, 380)
        }
    }

    /// A dialogue line (mission-flow 7d): the beat title as a heading over the first line; the
    /// speaker's portrait on their side (hero left, others right) and the text box away from it;
    /// narrator lines centred with no portrait; the ask button replaces "Tiếp" while it shows.
    private func buildDialogue(_ p: PlayState) {
        let lines = p.dialogueLines
        guard !lines.isEmpty else { return }
        let line = lines[min(p.lineIndex, lines.count - 1)]
        // dialogue.md §5.2 (QC r5): the panel (speaker 286 / narrator 235) bottom-anchored above Tiếp with the
        // title row reserved inside its top on every line (the title shows on line 1); the portrait 256,
        // bottom-aligned with the panel on the speaker's side; everything below the pause/sound corner
        let sl = StoryLayout(pad: layout), d = sl.dialogue(speaker: line.speaker), pb = d.panel
        // dialogue §5.2: the background dimmed by black at 0.30, full-bleed (outside area too), under everything else
        // (r8: parity with Android); the pause/sound corner is drawn after it by topLeft order (z)
        let scrim = D.rr(-Self.bleed, -Self.bleed, 1280 + 2 * Self.bleed, 720 + 2 * Self.bleed, 0, SKColor(white: 0, alpha: 0.3))
        add(scrim, 0, 0); scrim.zPosition = 0.5
        add(D.rr(0, 0, pb.w, pb.h, 36, C.panel, C.gold, 6), pb.x, pb.y)
        if p.lineIndex == 0 { add(Font.label(p.beats[p.beat].title.text(game.lang), 44, C.gold, width: pb.w - 64), pb.midX, pb.y + 32 + 30) }
        if let pt = d.portrait {
            let pic = Pictures.node(ContentValidator.portraitId(hero: game.heroId, line), size: pt.w / 1.6); add(pic, pt.midX, pt.midY)
        }
        let bodyH = line.speaker == "narrator" ? 103.0 : 154.0
        textBox(line.text, pb.midX, pb.y + 32 + 68 + bodyH / 2, pb.w - 64, 38, .white)
        if p.askShowing, let a = p.currentBeat?.params.ask {
            nextButton(sl, label: a.button.text(game.lang), id: "ask")
            badge(a.button, 0, 0)
            if p.askHint { let h = handHint(); add(h, sl.next.right - 40, sl.next.y + 24) } // at the button's corner, off its label
        } else {
            nextButton(sl)
        }
    }

    private func buildPause() {
        if game.pausedFrom == .quiz { buildQuiz(); buttons = [] } // P-06: the quiz behind the overlay, its cards inert
        add(D.rr(-Self.bleed, -Self.bleed, 1280 + 2 * Self.bleed, 720 + 2 * Self.bleed, 0, SKColor(red: 42 / 255, green: 36 / 255, blue: 64 / 255, alpha: 0.7)), 0, 0)
        add(Font.label(game.ui("ui.pause.title"), 64, .white), 640, 200)
        button(game.ui("ui.btn.resume"), 440, 290, 400, 120, "resume", pulse: true)
        button(game.ui("ui.btn.home"), 440, 450, 400, 110, "home", fill: C.cream)
        roundIcon(layout.mute, "mute", speakerIcon(layout.mute.r))
        langButton()
    }

    /// §5.2 small-k: the question whose right pick has already played its fade-and-glide (so a rebuild
    /// draws the end state instead of replaying it).
    private var quizAnimated = -1

    private func buildQuiz() {
        backgroundColor = C.night
        guard let q = game.quiz, !q.isFinished else { return }
        let cur = q.current, n = q.questions.count, ql = QuizLayout(pad: layout)
        // dots and the "Câu n/N" counter top-centre in the free band right of the corner block (W7, §5.1)
        for i in 0..<n {
            let lit = i < q.index || (i == q.index && q.okIndex != nil)
            add(D.circle(0, 0, 16, lit ? C.gold : SKColor(white: 1, alpha: 0.3), C.goldDark, 3), ql.topCentre - Double(n - 1) * 30 + Double(i) * 60 - 60, 50)
        }
        add(Font.label("\(game.ui("ui.quiz.question")) \(q.index + 1)/\(n)", 28, C.gold, align: .left), ql.topCentre + Double(n - 1) * 30 - 20, 50)
        topLeftButtons()
        // the prompt starts at corner_bottom + 8, never beside the pause/sound block (iOS-R6-02)
        textBox(cur.prompt, ql.prompt.midX, ql.prompt.midY, ql.prompt.w, 40, .white)
        let picked = q.okIndex != nil
        let animate = picked && ql.small && quizAnimated != q.index
        for slot in 0..<3 {
            let j = q.order[slot], choice = cur.choices[j]
            let wrong = q.wrong.contains(j), ok = q.okIndex == j
            // §5.2: after the right pick on a small-k phone only the right card stays (wrong cards fade first)
            if picked && ql.small && !ok && !animate { continue }
            let b = ql.slots[slot], cw = b.w, ch = b.h
            let card = SKNode()
            card.addChild(D.rr(0, 8, cw, ch, 30, SKColor(white: 0, alpha: 0.3)))
            // right: pale green #D9F2D0, a #3FA34D border (10) and a green tick, ink label; wrong: pale lavender
            // #E6E1F0 with a #9C8FB8 border (10) and an ink-outlined circular arrow (contrast; the UX quiz spec)
            card.addChild(D.rr(0, 0, cw, ch, 30, ok ? SKColor(hex: 0xD9F2D0) : wrong ? SKColor(hex: 0xE6E1F0) : C.cream,
                               ok ? SKColor(hex: 0x3FA34D) : wrong ? C.wrong : C.gold, ok || wrong ? 10 : 5))
            if ok {
                card.addChild(D.poly([(cw - 64, 40), (cw - 52, 28), (cw - 42, 40), (cw - 22, 16), (cw - 10, 28), (cw - 42, 60)], SKColor(hex: 0x3FA34D), C.ink, 4))
            }
            let pic = Pictures.node(choice.pictureId, size: 110); pic.position = CGPoint(x: cw / 2, y: -105); pic.alpha = wrong ? 0.45 : 1; card.addChild(pic)
            if ok {
                // the "Đúng rồi!" pill on the right card, so it travels with it: centred on the card's top row (as
                // Android draws it), added after the picture so it lies over it (dev pre-freeze r7: it was under the
                // picture and cut off), deep-ink label on the saturated green (accessibility: never white, 3.2:1)
                let bar = SKNode(); bar.addChild(D.rr(0, 0, 220, 40, 20, SKColor(hex: 0x3FA34D)))
                let l = Font.label(game.ui("ui.quiz.correct"), 26, SKColor(hex: 0x1A120C)); l.position = CGPoint(x: 110, y: -20); bar.addChild(l)
                bar.position = CGPoint(x: cw / 2 - 110, y: -8); card.addChild(bar)
            }
            if wrong { // the "try again" mark: a circular arrow, never a red cross (TASK-004 art fix), ink-outlined
                let p = CGMutablePath(); p.addArc(center: CGPoint(x: cw - 40, y: -40), radius: 18, startAngle: 0.3, endAngle: 5.6, clockwise: false)
                let outline = D.shape(p, nil, C.ink, 12); outline.lineCap = .round; card.addChild(outline)
                let arc = D.shape(p, nil, C.wrong, 6); arc.lineCap = .round; card.addChild(arc)
            }
            let l = Font.label(choice.text.text(game.lang), 37, C.ink, width: cw - 30); l.position = CGPoint(x: cw / 2, y: -236); card.addChild(l) // ink on every card state
            for (z, child) in card.children.enumerated() { child.zPosition = CGFloat(z) } // shadow, fill, icons, picture, the right pill, label in that order
            let at = ok && picked && ql.small && !animate ? ql.rightCard(slot: slot) : b
            card.position = D.p(at.x, at.y); card.name = "\(j)"; card.userData = ["x": at.x]
            uiZ += 1; card.zPosition = uiZ
            ui.addChild(card); cardNodes.append(card)
            if animate {
                // §5.2: the wrong cards fade out over 0.2 s, then the right card glides to the left slot over 0.3 s,
                // all inside feedback_time (0.9 s), before Tiếp appears
                if ok { card.userData = ["x": ql.slots[0].x]; card.run(.sequence([.wait(forDuration: 0.2), .move(to: D.p(ql.slots[0].x, ql.slots[0].y), duration: 0.3)])) }
                else { card.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()])) }
            }
            if !picked && !wrong { buttons.append(Button(rect: CGRect(x: b.x, y: b.y, width: cw, height: ch), id: "card\(slot)")) }
        }
        if animate { quizAnimated = q.index }
        if picked && game.quizCanAdvance {
            let w = ql.why
            add(D.rr(0, 0, w.w, w.h, 24, C.panel), w.x, w.y)
            add(Font.label(cur.why.text(game.lang), 37, .white, width: w.w - 40, weight: 600), w.midX, w.midY)
            button(game.ui("ui.btn.next"), ql.next.x, ql.next.y, ql.next.w, ql.next.h, "next", pulse: true, size: 34)
            badge(cur.why, 0, 0)
        } else if !picked && !q.wrong.isEmpty {
            // under the cards: on a small-k phone the cards use Tiếp's row, so the line sits just below them
            add(Font.label(game.ui("ui.quiz.retry"), 37, SKColor(hex: 0xffd0c8)), 640, min(700, ql.slots[0].bottom + 32))
        }
    }

    private func buildResults() {
        backgroundColor = C.night
        add(D.drum(260, SKColor(hex: 0xf2b632, alpha: 0.15)), 640, 300)
        add(Font.label(game.ui("ui.results.done"), 64, C.gold), 640, 110)
        topLeftButtons()
        for i in 0..<3 {
            let got = i < game.stars
            let s = D.star(i == 1 ? 90 : 75, got ? C.gold : SKColor(white: 1, alpha: 0.18), got ? .white : SKColor(white: 1, alpha: 0.35))
            add(s, 640 + Double(i - 1) * 200, i == 1 ? 270 : 300)
            if got { s.setScale(0.6); s.run(.sequence([.wait(forDuration: 0.3 + Double(i) * 0.35), .scale(to: 1, duration: 0.3)])) }
        }
        // the medal: gold if ever earned; "earned" only in the run that earns it; "missing" only if never earned
        let medal = SKNode()
        medal.addChild(D.circle(0, 0, 44, game.medalEarned ? C.gold : nil, game.medalEarned ? .white : SKColor(white: 1, alpha: 0.5), 5))
        medal.addChild(D.drum(32, game.medalEarned ? C.goldDark : SKColor(white: 1, alpha: 0.4)))
        add(medal, 1060, 300)
        if game.medalNew { add(Font.label(game.ui("ui.medal.earned"), 28, C.glow, width: 300), 1060, 390) }
        else if !game.medalEarned { add(Font.label(game.ui("ui.medal.missing"), 28, SKColor(white: 1, alpha: 0.75), width: 300), 1060, 400) }
        if game.unlockedHero == nil { add(Font.label(game.ui("ui.results.more_heroes"), 37, SKColor(white: 1, alpha: 0.8), width: 900), 640, 450) }
        button(game.ui("ui.btn.next"), 490, 520, 300, 110, "next", pulse: true)
    }

    private func buildUnlock() {
        backgroundColor = C.night
        add(D.rr(300, -5, 680, 10, 5, C.gold), 0, 300)
        topLeftButtons()
        for (x, lit) in [(300.0, true), (980, true)] {
            add(D.circle(0, 0, 120, lit ? C.gold : SKColor(hex: 0x5a5370), .white, 6), x, 300)
            add(D.circle(0, 0, 110, C.cream), x, 300)
            add(D.drum(104, SKColor(hex: 0xc98a12, alpha: 0.5)), x, 300)
        }
        let h = HeroNode(scale: 0.6); h.update(face: 1, walk: false, defend: false, attack: nil, hurt: false, t: 0); add(h, 300, 380)
        add(Font.label(game.hero.mission.hero.name.text(game.lang), 44, .white, width: 560), 300, 455)
        add(Font.label("?", 110, C.goldDark), 980, 300)
        if let next = game.unlockedHero { add(Font.label(next.mission.hero.name.text(game.lang), 44, .white, width: 560), 980, 455) }
        add(Font.label(game.ui("ui.unlock.title"), 52, C.gold, width: 900), layout.topStackCentre, 100) // clear of pause/sound (W7)
        add(Font.label(game.ui("ui.unlock.map_stub"), 28, SKColor(white: 1, alpha: 0.7)), 640, 530)
        button(game.ui("ui.btn.to_map"), 640 - 170, 580, 340, 110, "toMap", pulse: true) // one button (UX unlock spec)
    }

    // MARK: per-frame UI animation (hint pulses, hands, quiz shake)

    private func animateUI() {
        let t = clock
        if game.screen == .play, !game.play.visiblePads.isEmpty {
            let p = game.play
            var pulse: [PadAction: Bool] = [.right: p.rightPulse]
            if let sp = p.stuckPad { pulse[sp] = true }
            for (a, node) in padNodes {
                let on = pads.holds.values.contains(a)
                let pl = pulse[a] ?? false
                node.childNode(withName: "halo")?.isHidden = !pl
                (node.childNode(withName: "face") as? SKShapeNode)?.fillColor = on ? C.gold : SKColor(hex: 0xfff6e3, alpha: 0.88)
                node.setScale(pl ? 1 + 0.08 * sin(t * 10) : 1)
            }
            if let hand = handNode {
                let target: Circle? = switch p.hand { case .right: layout.right; case .attack: layout.attack; case .defend: layout.defend; case .special, .holdSpecial: layout.special; case nil: nil }
                hand.isHidden = target == nil
                if let c = target { hand.position = D.p(c.cx, c.cy - 70 - sin(t * 6) * 12) }
            }
            if let go = ui.childNode(withName: "go") { go.position = D.p(1060 + sin(t * 6) * 10, 300) }
            if let ring = padNodes[.special]?.childNode(withName: "meter") as? SKShapeNode {
                let m = p.meter
                if p.currentBeat?.type == "hold-meter", m > 0 {
                    let path = CGMutablePath(); path.addArc(center: .zero, radius: layout.special.r + 10, startAngle: .pi / 2, endAngle: .pi / 2 - 2 * .pi * m, clockwise: true)
                    ring.path = path; ring.isHidden = false
                } else { ring.isHidden = true }
            }
        }
        if game.screen == .quiz, let q = game.quiz {
            for card in cardNodes where !card.hasActions() { // the wrong-pick shake around the card's own slot
                guard let base = card.userData?["x"] as? Double else { continue }
                var x = base
                if let s = q.shakeIndex, Int(card.name ?? "") == s, q.shakeTime > 0 { x += sin(q.shakeTime * 60) * 14 * q.shakeTime * 2 }
                card.position.x = x
            }
        }
    }

    // MARK: debug state for the UI tests (TASK-023 G; compiled out of Release)
    #if DEBUG
    /// A hidden accessibility element (`debugState`) whose value is a small JSON of the game state, for the
    /// XCUITest touch cases: QC's touch tests read it instead of guessing from pixels. Debug builds only.
    private var debugLabel: UILabel?
    private var debugHeld: Set<PadAction> = []
    /// "Tiếp" presses: the activating touch's UITouch.timestamp and whether the press advanced (B1).
    private var debugPresses: [(TimeInterval, Bool)] = []
    private var debugFrame = 0
    private lazy var debugTimeScale: Double = { let v = UserDefaults.standard.double(forKey: "timeScale"); return v > 0 ? v : 1 }()
    /// Context changes (screen / story line / phase / beat / line) with the press-clock time they were first drawn.
    private var debugLog: [(String, TimeInterval)] = []
    private var debugLastPlace = ""
    /// Every button press: id, press time, and whether the entry lock was closed at that time (pause/sound exempt).
    private var debugFires: [(String, TimeInterval, Bool)] = []

    private func debugAttach(_ v: SKView) {
        let l = UILabel(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        l.alpha = 0.011; l.isAccessibilityElement = true; l.accessibilityIdentifier = "debugState"; l.accessibilityTraits = .staticText
        v.addSubview(l); debugLabel = l
    }

    private func debugPlace() -> String {
        let p = game.play
        return "\(game.screen)|\(game.storyLine)|\(p.phase)|\(p.beat)|\(p.cardLine)|\(p.captionLine)|\(p.lineIndex)"
    }

    /// Scene point (y down) → normalized view coordinates (0…1), the aspect-fit mapping the scene uses.
    private func debugNorm(_ x: Double, _ y: Double) -> [Double] {
        guard let v = view else { return [0, 0] }
        let k = root.xScale // the world fitted to the safe rect (Input Rule 1)
        return [(worldOrigin.x + x * k) / v.bounds.width, (worldOrigin.y + y * k) / v.bounds.height]
    }

    private func debugPublish() {
        let place = debugPlace()
        if place != debugLastPlace { debugLastPlace = place; debugLog.append((place, ProcessInfo.processInfo.systemUptime)); debugLog = Array(debugLog.suffix(120)) }
        debugFrame += 1
        guard debugFrame % 6 == 0, let l = debugLabel else { return }
        let p = game.play
        var pads: [String: [Double]] = [:]
        for (n, c) in [("left", layout.left), ("right", layout.right), ("defend", layout.defend), ("attack", layout.attack), ("special", layout.special)] {
            pads[n] = debugNorm(c.cx, c.cy)
        }
        var btns: [String: [Double]] = [:]
        for b in buttons { btns[b.id] = debugNorm(b.rect.midX, b.rect.midY) }
        let base: [String: Any] = [
            "screen": "\(game.screen)", "story_line": game.storyLine, "phase": "\(p.phase)", "beat": p.beat,
            "card_line": p.cardLine, "caption_line": p.captionLine, "line": p.lineIndex,
            "training_step": "\(p.trainingStage)", "held": debugHeld.map(\.rawValue).sorted(),
            "visible": p.visiblePads.map(\.rawValue).sorted(), "hero_x": p.hero.x, "cam": p.cam,
            "train_cap": p.trainCap ?? NSNull(), "x_start": p.xStart,
            "presses": debugPresses.map { ["t": $0.0, "advanced": $0.1] },
            "pads": pads, "buttons": btns,
            "skip_warning": game.skipWarning, "stars": game.stars, "medal_earned": game.medalEarned,
            "hero_hurt": p.hero.hurt > 0, "strike": p.enemies.contains { $0.state == .strike },
            "entered_at": game.enteredAt ?? NSNull(), "now": ProcessInfo.processInfo.systemUptime,
            "log": debugLog.map { ["place": $0.0, "t": $0.1] },
        ]
        var extra: [String: Any] = [:]
        if let q = game.quiz, !q.isFinished {
            extra["quiz"] = ["index": q.index, "correct_slot": q.order.firstIndex(of: q.current.correctIndex) ?? -1,
                             "picked": q.okIndex != nil, "can_advance": game.quizCanAdvance]
        }
        if game.screen == .title {
            let tl = TitleLayout(pad: layout, debug: game.isDebug)
            extra["title_card_box"] = debugNorm(tl.card.midX, tl.card.midY)
            if let c = game.titleCard { extra["title_card"] = ["stars": c.stars, "medal": c.medal] }
        }
        extra["sprites_visible"] = spritesVisible; extra["dots_visible"] = dotsVisible
        extra["placeholder"] = shownPlaceholder.map { [$0.x, $0.y, $0.w, $0.h] } ?? NSNull()
        extra["hints"] = placedHints.mapValues { [$0.x, $0.y, $0.w, $0.h] } // world px (y down), relative to the world
        extra["lock_context"] = game.lockContextForDebug ?? NSNull()
        extra["fires"] = debugFires.map { ["id": $0.0, "t": $0.1, "locked": $0.2] }
        extra["muted"] = game.muted
        let state = base.merging(extra) { a, _ in a }
        if let d = try? JSONSerialization.data(withJSONObject: state, options: [.sortedKeys]) { l.accessibilityValue = String(data: d, encoding: .utf8) }
    }
    #endif

}
