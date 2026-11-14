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
    private var backdropTheme = ""
    private var backdrop: SKNode?
    private var skyNode: SKNode?
    private let hero = HeroNode()
    private var enemyNodes: [Int: EnemyNode] = [:]

    private struct Button { let rect: CGRect; let id: String }
    private var buttons: [Button] = []
    private var menuTouches: [Int: String] = [:]
    private var uiKey = ""
    private var padNodes: [PadAction: SKNode] = [:]
    private var handNode: SKNode?
    private var cardNodes: [SKNode] = []

    private var last: TimeInterval = 0, acc = 0.0, clock = 0.0
    private let step = 1.0 / 60

    init(game: Game, audio: Audio) {
        self.game = game; self.audio = audio
        super.init(size: CGSize(width: 1280, height: 720))
        scaleMode = .aspectFit
        backgroundColor = C.night
        addChild(world); world.addChild(hero); world.addChild(fx); world.addChild(worldHints)
        hero.zPosition = 5; fx.zPosition = 10; worldHints.zPosition = 12
        addChild(ui); ui.zPosition = 100
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        relayout()
    }

    private func relayout() {
        guard let v = view else { return }
        let ins = v.safeAreaInsets
        guard ins != lastInsets || v.bounds.size != lastSize else { return }
        lastInsets = ins; lastSize = v.bounds.size
        layout = PadLayout(view: (w: v.bounds.width, h: v.bounds.height), insets: (ins.top, ins.left, ins.bottom, ins.right), padMin: game.tuning["pad_min"])
        uiKey = ""
    }

    /// No stuck input: every held pad is released when the app loses focus or pauses.
    func appWillResignActive() { pads.clearAll(); menuTouches = [:]; game.backgrounded(); uiKey = "" }

    // MARK: loop

    override func update(_ currentTime: TimeInterval) {
        relayout()
        let dt = last == 0 ? 0 : min(currentTime - last, 0.25)
        last = currentTime; acc += dt; clock += dt
        while acc >= step {
            game.step(step, pads.take())
            acc -= step
        }
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
                "\(p.cardLine)", "\(p.trainingStage)", "\(p.visiblePads.map(\.rawValue).sorted())", "\(game.skipWarning)", "\(p.goArrow)"].joined(separator: "|")
    }

    // MARK: touches

    private func ydown(_ t: UITouch) -> CGPoint { let p = t.location(in: self); return CGPoint(x: p.x, y: 720 - p.y) }
    private func tid(_ t: UITouch) -> Int { ObjectIdentifier(t).hashValue }
    private var padsLive: Bool { game.screen == .play && !game.skipWarning && !game.play.visiblePads.isEmpty }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = ydown(t)
            if padsLive, let a = layout.action(at: p.x, p.y, visible: game.play.visiblePads) { pads.down(tid(t), a); continue } // pads fire on touch-down
            if let b = buttons.last(where: { $0.rect.contains(p) }) { menuTouches[tid(t)] = b.id }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { let p = ydown(t); pads.moved(tid(t), layout.action(at: p.x, p.y, visible: game.play.visiblePads)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        var fired = false // two fingers: the first release in a frame wins (P-05)
        for t in touches {
            pads.up(tid(t))
            guard let id = menuTouches.removeValue(forKey: tid(t)) else { continue }
            let p = ydown(t)
            if !fired, buttons.contains(where: { $0.id == id && $0.rect.contains(p) }) { fire(id); fired = true } // menus fire on touch-up inside
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { pads.up(tid(t)); menuTouches[tid(t)] = nil }
    }

    private func fire(_ id: String) {
        audio.volume = Float(game.tuning["volume"])
        switch id {
        case "start": game.start()
        case "next": game.next()
        case "lang": game.toggleLang()
        case "mute": game.toggleMute(); audio.muted = game.muted
        case "pause": pads.clearAll(); game.pause()
        case "resume": game.resume()
        case "home", "toMap": game.home()
        case "replay": game.replay()
        case "skip": game.skip()
        case "skipAnyway": game.skipAnyway()
        case "keepReading": game.keepReading()
        default: if id.hasPrefix("card"), let j = Int(id.dropFirst(4)) { game.answer(j) }
        }
        uiKey = ""
    }

    // MARK: world (play)

    private func drawWorld() {
        let showWorld = game.screen == .play || game.screen == .pause
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
            let sk = Backdrop.skyNode(theme, width: 1280, height: game.tuning["ground_y"])
            sk.position = CGPoint(x: 0, y: 720); sk.zPosition = -20
            addChild(sk); skyNode = sk
        }
        world.position.x = -p.cam
        let t = p.t
        hero.position = D.p(p.hero.x, ground)
        hero.update(face: p.hero.face, walk: p.hero.walk, defend: p.hero.def, attack: p.hero.atk >= 0 ? p.hero.atk : nil, hurt: p.hero.hurt > 0, t: t)
        var seen = Set<Int>()
        for e in p.enemies {
            seen.insert(e.id)
            let n = enemyNodes[e.id] ?? { let n = EnemyNode(kind: e.kind); n.zPosition = 4; world.addChild(n); enemyNodes[e.id] = n; return n }()
            n.position = D.p(e.x, ground); n.update(e, t: t)
        }
        for (id, n) in enemyNodes where !seen.contains(id) { n.removeFromParent(); enemyNodes[id] = nil }
        fx.removeAllChildren()
        // training: straw dummies wobble and spring back (never break); the friendly partner in the hero's colours
        for d in p.dummies {
            let n = SKNode(); n.position = D.p(d.x, ground); n.zRotation = -sin(t * 20) * 0.25 * d.wobble
            n.addChild(D.rr(-6, -170, 12, 170, 6, C.wood))
            n.addChild(D.ellipse(0, -110, 34, 56, d.hit ? SKColor(hex: 0xe8cf7a) : SKColor(hex: 0xd9b26a)))
            n.addChild(D.circle(0, -180, 26, SKColor(hex: 0xe8cf7a)))
            n.addChild(D.rr(-40, -130, 80, 10, 5, SKColor(hex: 0xb8902f)))
            fx.addChild(n)
        }
        if let pt = p.partner {
            let n = HeroNode(scale: 0.95)
            n.update(face: pt.face, walk: false, defend: false, attack: pt.state == .strike ? 0.6 : (pt.state == .windup ? 0.05 : nil), hurt: false, t: t)
            n.position = D.p(pt.x, ground); fx.addChild(n)
            if pt.state == .windup {
                let b = SKNode(); b.addChild(D.circle(0, 0, 30, C.glow, C.goldDark, 4)); b.addChild(D.rr(-5, -18, 10, 24, 5, C.ink)); b.addChild(D.circle(0, 14, 5.5, C.ink))
                b.position = D.p(pt.x, ground - 300); fx.addChild(b)
            }
        }
        if let fxX = p.flagX {
            let f = SKNode(); f.position = D.p(fxX, ground)
            f.addChild(D.rr(-5, -300, 10, 300, 5, SKColor(hex: 0x6a4a2a)))
            f.addChild(D.poly([(5, -295), (120, -270), (5, -220)], C.gold))
            fx.addChild(f)
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
            // keep pops below the HUD row (pause, sound, beat dots): Ối! never covers the pause button
            let l = Font.label(game.ui(q.key), 40, color(q.color)); l.position = D.p(q.x, max(q.y, 200)); l.alpha = min(1, q.life * 2); fx.addChild(l)
        }
        worldHints.removeAllChildren()
        if let e = p.stallTarget { let a = arrowDown(); a.position = D.p(e.x, ground - 330 + sin(t * 8) * 10); worldHints.addChild(a) }
        if let dx = p.stallDummyX { let a = arrowDown(); a.position = D.p(dx, ground - 260 + sin(t * 8) * 10); worldHints.addChild(a) }
        if p.flagArrow, let fx = p.flagX { let a = arrowDown(); a.position = D.p(fx, ground - 360 + sin(t * 8) * 10); worldHints.addChild(a) }
    }

    private func color(_ c: FxColor) -> SKColor {
        switch c { case .glow: C.glow; case .white: .white; case .indigo: C.indigo; case .red: C.red }
    }

    private func arrowDown() -> SKNode {
        D.poly([(-14, -40), (14, -40), (14, -10), (30, -10), (0, 22), (-30, -10), (-14, -10)], C.glow, C.ink, 4)
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
        let vi = Font.label("VI", 32, game.lang == .vi ? C.red : SKColor(hex: 0x9a8f86)); vi.position = CGPoint(x: 44, y: -l.h / 2)
        let bar = Font.label("|", 30, SKColor(hex: 0x9a8f86)); bar.position = CGPoint(x: 80, y: -l.h / 2)
        let en = Font.label("EN", 32, game.lang == .en ? C.red : SKColor(hex: 0x9a8f86)); en.position = CGPoint(x: 116, y: -l.h / 2)
        [vi, bar, en].forEach(n.addChild)
        add(n, l.x, l.y)
        buttons.append(Button(rect: CGRect(x: l.x, y: l.y, width: l.w, height: l.h), id: "lang"))
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
        add(Font.label(t.text(game.lang), size, c, width: w), x, y)
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
    private func skipButton() {
        guard game.canSkip else { return }
        button(game.ui("ui.story.skip"), 1280 - 230, 640, 190, 70, "skip", fill: C.cream, size: 26)
    }
    private func skipWarningOverlay() {
        guard game.skipWarning else { return }
        buttons = []
        add(D.rr(0, 0, 1280, 720, 0, SKColor(red: 42 / 255, green: 36 / 255, blue: 64 / 255, alpha: 0.75)), 0, 0)
        add(D.rr(-420, -170, 840, 340, 36, C.cream, C.gold, 6), 640, 330)
        add(D.drum(50, SKColor(hex: 0xc98a12, alpha: 0.5)), 640, 210)
        add(Font.label(game.ui("ui.story.skip_warning"), 37, C.ink, width: 720), 640, 300)
        button(game.ui("ui.story.keep_reading"), 250 + 70, 400, 300, 100, "keepReading", pulse: true)
        button(game.ui("ui.story.skip_confirm"), 660, 400, 300, 100, "skipAnyway", fill: C.cream)
    }

    private func buildUI() {
        ui.removeAllChildren(); buttons = []; padNodes = [:]; handNode = nil; cardNodes = []; uiZ = 0; unsignedIds = []
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
        add(Backdrop.skyNode("village", width: 1280, height: game.tuning["ground_y"]), 0, 0)
        let b = Backdrop.world(theme: "village", from: -100, to: 1400, ground: game.tuning["ground_y"]); b.position = CGPoint(x: 0, y: 720); uiZ += 1; b.zPosition = uiZ; ui.addChild(b)
        add(D.rr(-490, -105, 980, 210, 40, C.panel, C.gold, 6), 640, 165)
        for x in [240.0, 1040] { add(D.drum(70, SKColor(hex: 0xf2b632, alpha: 0.8)), x, 165) }
        // the title fits between the two drum emblems in every language (iOS-R2-01)
        let title = Font.label(game.ui("ui.app.title"), 76, C.gold)
        if title.frame.width > 600 { title.setScale(600 / title.frame.width) }
        add(title, 640, 140)
        if game.isDebug { add(Font.label(game.ui("ui.debug.subtitle"), 36, .white), 640, 220) }
        let h = HeroNode(scale: 0.8); h.update(face: 1, walk: false, defend: false, attack: nil, hurt: false, t: 0); add(h, 260, game.tuning["ground_y"])
        if game.isPlayable { button(game.ui("ui.btn.start"), 640 - 190, 330, 380, 130, "start", pulse: true, size: 44) }
        add(D.rr(-490, -75, 980, 150, 24, SKColor(hex: 0xfff6e3, alpha: 0.92)), 640, 595)
        for (i, (k, icon)) in [("ui.pad.move", "move"), ("ui.pad.attack", "attack"), ("ui.pad.defend", "defend")].enumerated() {
            let x = 300.0 + Double(i) * 340
            let c = SKNode(); c.addChild(D.circle(0, 0, 38, .white, C.gold, 4)); c.addChild(padIcon(icon, 38)); add(c, x - 60, 595)
            add(Font.label(game.ui(k), 32, C.ink, align: .left), x - 10, 595)
        }
        langButton()
    }

    private func storyPicture(ending: Bool) {
        let crop = SKCropNode()
        crop.maskNode = D.rr(0, 0, 800, 360, 30, .white)
        let inner = SKNode()
        if ending, Pictures.files[game.hero.mission.ending.pictureId] != nil {
            let pic = Pictures.node(game.hero.mission.ending.pictureId, size: 500); pic.position = CGPoint(x: 400, y: -180); inner.addChild(pic)
        } else {
            inner.addChild(Backdrop.skyNode(ending ? "river" : "village", width: 800, height: 360))
            let b = Backdrop.world(theme: ending ? "river" : "village", from: -240, to: 1100, ground: 360); b.position = CGPoint(x: -240, y: 0); inner.addChild(b)
            if ending { inner.addChild(D.rr(0, 0, 800, 360, 0, SKColor(red: 1, green: 0.59, blue: 0.35, alpha: 0.3))) }
            let h = HeroNode(scale: 0.9); h.update(face: 1, walk: false, defend: false, attack: nil, hurt: false, t: 0); h.position = CGPoint(x: ending ? 400 : 320, y: -340); inner.addChild(h)
        }
        crop.addChild(inner)
        add(crop, 240, 110)
        add(D.rr(0, 0, 800, 360, 30, nil, C.gold, 8), 240, 110)
    }

    private func buildStory(_ lines: [Text], ending: Bool) {
        backgroundColor = C.night
        storyPicture(ending: ending)
        let line = lines[min(game.storyLine, lines.count - 1)]
        textBox(line, 640, 530, 1000, 38, .white)
        button(game.ui("ui.btn.next"), 640 - 150, 590, 300, 110, "next", pulse: true)
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

    private func buildPlayHUD() {
        let p = game.play
        roundIcon(layout.pause, "pause", pauseIcon(layout.pause.r))
        roundIcon(layout.mute, "mute", speakerIcon(layout.mute.r))
        let n = p.beats.count
        for i in 0..<n {
            let x = 640 - Double(n - 1) * 45 + Double(i) * 90
            let done = i < p.beat || (i == p.beat && p.phase == .caption)
            add(D.circle(0, 0, 30, done ? C.gold : SKColor(white: 1, alpha: 0.75), C.goldDark, 4), x, 60)
            add(D.drum(22, done ? C.ink : SKColor(red: 58 / 255, green: 42 / 255, blue: 31 / 255, alpha: 0.35)), x, 60)
        }
        if p.phase == .beatCard {
            let texts = p.cardTexts
            add(D.rr(-480, -150, 960, 300, 36, C.panel, C.gold, 6), 640, 290)
            for x in [230.0, 1050] { add(D.drum(44, SKColor(hex: 0xf2b632, alpha: 0.8)), x, 210) }
            add(Font.label("\(game.ui("ui.play.beat")) \(p.beat + 1) · \(p.beats[p.beat].title.text(game.lang))", 30, C.gold, width: 760), 640, 190)
            textBox(texts[min(p.cardLine, texts.count - 1)], 640, 285, 760, 40, .white)
            button(game.ui("ui.btn.next"), 640 - 150, 470, 300, 110, "next", pulse: true)
            return
        }
        if p.phase == .caption {
            let beat = p.beats[p.beat]
            add(D.rr(-480, -150, 960, 300, 36, C.panel, C.gold, 6), 640, 290)
            for x in [230.0, 1050] { add(D.drum(44, SKColor(hex: 0xf2b632, alpha: 0.8)), x, 210) }
            add(Font.label("\(game.ui("ui.play.beat")) \(p.beat + 1)", 30, C.gold), 640, 190)
            if !beat.scene.isEmpty { textBox(beat.scene[min(p.captionLine, beat.scene.count - 1)], 640, 285, 760, 40, .white) }
            button(game.ui("ui.btn.next"), 640 - 150, 470, 300, 110, "next", pulse: true)
            return
        }
        if p.phase == .beatPlay || p.phase == .beatEnd, p.beat < p.beats.count {
            let goal = p.beats[p.beat].goal
            add(Font.label(goal.text(game.lang), 37, C.ink, width: 760), 640, 125)
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

    private func buildPause() {
        add(D.rr(0, 0, 1280, 720, 0, SKColor(red: 42 / 255, green: 36 / 255, blue: 64 / 255, alpha: 0.7)), 0, 0)
        add(Font.label(game.ui("ui.pause.title"), 64, .white), 640, 200)
        button(game.ui("ui.btn.resume"), 440, 290, 400, 120, "resume", pulse: true)
        button(game.ui("ui.btn.home"), 440, 450, 400, 110, "home", fill: C.cream)
        roundIcon(layout.mute, "mute", speakerIcon(layout.mute.r))
        langButton()
    }

    private func buildQuiz() {
        backgroundColor = C.night
        guard let q = game.quiz, !q.isFinished else { return }
        let cur = q.current, n = q.questions.count
        for i in 0..<n {
            let lit = i < q.index || (i == q.index && q.okIndex != nil)
            add(D.circle(0, 0, 16, lit ? C.gold : SKColor(white: 1, alpha: 0.3), C.goldDark, 3), 640 - Double(n - 1) * 30 + Double(i) * 60, 50)
        }
        add(Font.label("\(game.ui("ui.quiz.question")) \(q.index + 1)/\(n)", 28, C.gold, align: .left), layout.pause.cx + layout.pause.r + 24, layout.pause.cy)
        roundIcon(layout.pause, "pause", pauseIcon(layout.pause.r))
        textBox(cur.prompt, 640, 175, 900, 40, .white)
        let cw = 360.0, ch = 320.0, gap = 40.0, x0 = (1280 - 3 * cw - 2 * gap) / 2, y0 = 230.0
        for slot in 0..<3 {
            let j = q.order[slot], choice = cur.choices[j]
            let wrong = q.wrong.contains(j), ok = q.okIndex == j
            let card = SKNode()
            card.addChild(D.rr(0, 8, cw, ch, 30, SKColor(white: 0, alpha: 0.3)))
            card.addChild(D.rr(0, 0, cw, ch, 30, ok ? SKColor(hex: 0xc9f0b0) : wrong ? SKColor(hex: 0xd9d4cf) : C.cream,
                               ok ? C.leafDark : wrong ? C.wrong : C.gold, ok ? 10 : 5))
            let pic = Pictures.node(choice.pictureId, size: 110); pic.position = CGPoint(x: cw / 2, y: -115); pic.alpha = wrong ? 0.45 : 1; card.addChild(pic)
            if wrong { // the "try again" mark: a circular arrow, never a red cross (TASK-004 art fix)
                let p = CGMutablePath(); p.addArc(center: CGPoint(x: cw - 40, y: -40), radius: 18, startAngle: 0.3, endAngle: 5.6, clockwise: false)
                card.addChild(D.shape(p, nil, C.wrong, 6))
            }
            let l = Font.label(choice.text.text(game.lang), 37, wrong ? SKColor(hex: 0x8a8078) : C.ink, width: cw - 40); l.position = CGPoint(x: cw / 2, y: -258); card.addChild(l)
            card.position = D.p(x0 + Double(slot) * (cw + gap), y0); card.name = "\(j)"
            uiZ += 1; card.zPosition = uiZ
            ui.addChild(card); cardNodes.append(card)
            if q.okIndex == nil && !wrong { buttons.append(Button(rect: CGRect(x: x0 + Double(slot) * (cw + gap), y: y0, width: cw, height: ch), id: "card\(slot)")) }
        }
        if q.okIndex != nil {
            // the why strip sits below the cards (cards end at y 580)
            // the why strip below the cards (they end at y 550): 3 lines at 37 with 1.35 line height
            add(D.rr(-620, -80, 1240, 160, 24, C.panel), 640, 635)
            add(Font.label(game.ui("ui.quiz.correct"), 30, C.glow, width: 200), 145, 635)
            add(Font.label(cur.why.text(game.lang), 37, .white, width: 780), 650, 635)
            button(game.ui("ui.btn.next"), 1060, 593, 190, 84, "next", pulse: true)
            badge(cur.why, 0, 0)
        } else if !q.wrong.isEmpty {
            add(Font.label(game.ui("ui.quiz.retry"), 37, SKColor(hex: 0xffd0c8)), 640, 620)
        }
    }

    private func buildResults() {
        backgroundColor = C.night
        add(D.drum(260, SKColor(hex: 0xf2b632, alpha: 0.15)), 640, 300)
        add(Font.label(game.ui("ui.results.done"), 64, C.gold), 640, 110)
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
        for (x, lit) in [(300.0, true), (980, true)] {
            add(D.circle(0, 0, 120, lit ? C.gold : SKColor(hex: 0x5a5370), .white, 6), x, 300)
            add(D.circle(0, 0, 110, C.cream), x, 300)
            add(D.drum(104, SKColor(hex: 0xc98a12, alpha: 0.5)), x, 300)
        }
        let h = HeroNode(scale: 0.6); h.update(face: 1, walk: false, defend: false, attack: nil, hurt: false, t: 0); add(h, 300, 380)
        add(Font.label(game.hero.mission.hero.name.text(game.lang), 30, .white), 300, 450)
        add(Font.label("?", 110, C.goldDark), 980, 300)
        if let next = game.unlockedHero { add(Font.label(next.mission.hero.name.text(game.lang), 30, .white), 980, 450) }
        add(Font.label(game.ui("ui.unlock.title"), 52, C.gold, width: 1100), 640, 100)
        add(Font.label(game.ui("ui.unlock.map_stub"), 28, SKColor(white: 1, alpha: 0.7)), 640, 530)
        button(game.ui("ui.btn.replay"), 260, 580, 340, 110, "replay", fill: C.cream)
        button(game.ui("ui.btn.to_map"), 680, 580, 340, 110, "toMap", pulse: true)
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
            let x0 = (1280 - 3 * 360.0 - 2 * 40) / 2
            for (slot, card) in cardNodes.enumerated() {
                var x = x0 + Double(slot) * 400
                if let s = q.shakeIndex, Int(card.name ?? "") == s, q.shakeTime > 0 { x += sin(q.shakeTime * 60) * 14 * q.shakeTime * 2 }
                card.position.x = x
            }
        }
    }
}
