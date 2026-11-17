import SpriteKit
import GameCore

/// The hero (art bible §5: friendly, red tunic as accent, topknot and headband, rattan shield).
/// Built once; `update` sets the pose. Local coordinates are the prototype's (feet at 0, y down).
final class HeroNode: SKNode {
    private let body = SKNode(), arm = SKNode(), legL: SKNode, legR: SKNode
    private let shieldBack: SKNode, shieldFront = SKNode(), swoosh: SKShapeNode
    private let scaleS: Double
    /// The swing arc's radius in body units: it reaches `reach` world px in front (AC13), whatever the body scale.
    private let arcR: Double

    /// The figure is 261 units tall at scale 1 (topknot top). In play it is drawn at spec height
    /// (`specHeight`, HUD spec §3.3) with `reach`: the staff and swing arc keep that world length
    /// (attack_range for the hero), so a strike that lands looks like it lands. Render only.
    static let unitHeight = 261.0
    /// The hero is drawn 180 world px tall (HUD spec §3.3); the training partner at 0.62 × that (look sheet D-18).
    static let heroScale = 180 / unitHeight

    /// The figure's palette (look sheet d18). The training partner wears the follower look so a child never sees two
    /// heroes (r9 leader call, parity with Android): straw tunic, muted sash, plain topknot, no headband or tails.
    struct Look {
        var tunic, sash, skin: SKColor
        var headband: Bool
        static let hero = Look(tunic: C.red, sash: C.gold, skin: C.skin, headband: true)
        static let follower = Look(tunic: SKColor(hex: 0xD8C9A3), sash: SKColor(hex: 0xB9705C), skin: C.skin, headband: false)
    }

    init(scale s: Double = 1, reach: Double? = nil, look: Look = .hero) {
        scaleS = s
        // the shoulder is 18 units in front of the feet; the staff tip is 158 units from the shoulder
        let worldR = reach.map { $0 - 18 * s } ?? 150 * s
        arcR = worldR / s
        legL = SKNode(); legR = SKNode()
        legL.addChild(D.rr(-24, -70, 20, 68, 8, C.indigo)); legL.addChild(D.rr(-28, -10, 28, 12, 6, C.ink))
        legR.addChild(D.rr(4, -70, 20, 68, 8, C.indigo)); legR.addChild(D.rr(0, -10, 28, 12, 6, C.ink))
        shieldBack = D.ellipse(-30, -118, 14, 40, C.goldDark)
        swoosh = SKShapeNode()
        super.init()
        addChild(D.ellipse(0, 4, 60, 12, SKColor(white: 0, alpha: 0.18)))
        addChild(body)
        body.addChild(shieldBack)
        body.addChild(legL); body.addChild(legR)
        body.addChild(D.poly([(-34, -150), (34, -150), (42, -62), (0, -57), (-42, -62)], look.tunic))
        body.addChild(D.rr(-38, -96, 76, 12, 6, look.sash))
        body.addChild(D.poly([(-14, -150), (0, -126), (14, -150)], look.sash))
        arm.position = CGPoint(x: 18, y: 128)
        arm.addChild(D.rr(-6, -150, 12, 190, 6, C.wood))
        arm.addChild(D.rr(-8, -158, 16, 18, 6, C.gold))
        if reach != nil { arm.yScale = worldR / (158 * s) } // the staff keeps its world length; the hand stays body-sized
        body.addChild(arm)
        let hand = D.circle(0, 0, 12, look.skin); hand.position = arm.position; body.addChild(hand)
        swoosh.strokeColor = SKColor(white: 1, alpha: 0.8); swoosh.lineWidth = 10; swoosh.lineCap = .round
        body.addChild(swoosh)
        body.addChild(D.circle(0, -196, 44, look.skin))
        let hair = CGMutablePath()
        hair.addArc(center: CGPoint(x: -2, y: 200), radius: 46, startAngle: 0, endAngle: .pi, clockwise: false)
        body.addChild(D.shape(hair, C.hair))
        body.addChild(D.circle(-14, -246, 15, C.hair))
        if look.headband { // the hero's vermilion headband and its tails
            body.addChild(D.rr(-46, -214, 92, 12, 6, C.red))
            body.addChild(D.poly([(-44, -210), (-84, -192), (-78, -186), (-44, -200)], C.red))
        }
        for (x, r) in [(14.0, 6.0), (32, 6)] { body.addChild(D.circle(x, -190, r, C.ink)); body.addChild(D.circle(x + 2, -192, 2, .white)) }
        let smile = CGMutablePath(); smile.addArc(center: CGPoint(x: 24, y: 176), radius: 9, startAngle: -0.2, endAngle: -.pi + 0.2, clockwise: true)
        let sm = D.shape(smile, nil, C.ink, 4); sm.lineCap = .round; body.addChild(sm)
        body.addChild(D.circle(6, -178, 6, SKColor(red: 0.94, green: 0.47, blue: 0.43, alpha: 0.5)))
        shieldFront.addChild(D.circle(46, -128, 50, SKColor(hex: 0xd8a657), C.goldDark, 5))
        shieldFront.addChild(D.circle(46, -128, 36, nil, SKColor(hex: 0xb8823a), 3))
        shieldFront.addChild(D.circle(46, -128, 22, nil, SKColor(hex: 0xb8823a), 3))
        shieldFront.addChild(D.circle(46, -128, 10, C.gold, C.goldDark, 3))
        body.addChild(shieldFront)
        setScale(s)
    }
    required init?(coder: NSCoder) { fatalError() }

    /// `staffUp`: the staff held upright (−0.05 rad), the slice's stand-in for the follower's raised fist (Rule 7c).
    func update(face: Double, walk: Bool, defend: Bool, attack: Double?, hurt: Bool, t: Double, staffUp: Bool = false) {
        xScale = face * scaleS; yScale = scaleS
        let w = walk ? sin(t * 14) : 0
        body.position.y = walk ? abs(sin(t * 14)) * 4 : 0
        legL.position.x = w * 8; legR.position.x = -w * 8
        shieldBack.isHidden = defend; shieldFront.isHidden = !defend
        let swing = attack ?? -1
        let ang = swing >= 0 ? -1.9 + swing * 2.6 : (defend ? 0.9 : (staffUp ? -0.05 : -0.6))
        arm.zRotation = -ang
        if swing >= 0.2 && swing <= 0.85 {
            let p = CGMutablePath()
            p.addArc(center: CGPoint(x: 18, y: 128), radius: arcR, startAngle: 1.6, endAngle: CGFloat(1.9 - swing * 2.6 + 0.3), clockwise: true)
            swoosh.path = p; swoosh.isHidden = false
        } else { swoosh.isHidden = true }
        alpha = hurt && Int(t * 20) % 2 == 1 ? 0.25 : 1
    }
}

/// An enemy (art bible §3, §5): soft purple-grey, grumpy-cartoon never scary, dome helmets,
/// padded weapon tips, the leader wider but never taller than the hero. No injury, no lying down.
final class EnemyNode: SKNode {
    let kind: FightParams.Kind
    private let lean = SKNode(), weapon = SKNode(), handsUp = SKNode(), glow: SKShapeNode, bubble = SKNode(), dizzy = SKNode()
    private let legL = SKNode(), legR = SKNode(), eyes = SKNode(), swirl = SKNode()
    private let topY: Double
    /// Body height at scale 1 (helmet top), by kind: drawn at ≤ 170 in play (HUD spec §3.3). The weapon keeps
    /// its world length (the padded tip 140 px in front, enemy_reach − stand_gap) and the "!" and dizzy stars
    /// their world size. Render only: the sim has no y.
    static func unitHeight(_ k: FightParams.Kind) -> Double { k == .spear ? 259 : k == .shield ? 230 : 252 }

    init(kind: FightParams.Kind) {
        self.kind = kind
        topY = kind == .leader ? 280 : kind == .shield ? 240 : 272
        glow = D.ellipse(0, -130, kind == .leader ? 110 : 80, 160, C.glow)
        super.init()
        addChild(glow)
        let figure = SKNode()
        addChild(figure)
        figure.addChild(D.ellipse(0, 4, kind == .leader ? 80 : kind == .shield ? 66 : 50, 12, SKColor(white: 0, alpha: 0.18)))
        figure.addChild(legL); figure.addChild(legR); figure.addChild(lean)
        func face(_ fx: Double, _ fy: Double, _ r: Double) {
            lean.addChild(D.circle(fx - 6, fy, r, C.skin))
            eyes.addChild(D.circle(fx - r * 0.3, fy, r * 0.11, C.ink)); eyes.addChild(D.circle(fx + r * 0.25, fy, r * 0.11, C.ink))
            eyes.addChild(D.poly([(fx - r * 0.48, fy - r * 0.28), (fx - r * 0.12, fy - r * 0.16), (fx - r * 0.12, fy - r * 0.1), (fx - r * 0.48, fy - r * 0.22)], C.ink))
            eyes.addChild(D.poly([(fx + r * 0.42, fy - r * 0.28), (fx + r * 0.08, fy - r * 0.16), (fx + r * 0.08, fy - r * 0.1), (fx + r * 0.42, fy - r * 0.22)], C.ink))
            for ex in [fx - r * 0.3, fx + r * 0.25] { swirl.addChild(D.circle(ex, fy, r * 0.14, nil, C.ink, 3)) }
            lean.addChild(eyes); lean.addChild(swirl)
        }
        func dome(_ x: Double, _ y: Double, _ r: Double) {
            let p = CGMutablePath(); p.addArc(center: CGPoint(x: x, y: -y), radius: r, startAngle: 0, endAngle: .pi, clockwise: false); p.closeSubpath()
            lean.addChild(D.shape(p, C.steel))
        }
        switch kind {
        case .spear:
            legL.addChild(D.rr(-18, -80, 16, 78, 7, C.enemyDark)); legR.addChild(D.rr(2, -80, 16, 78, 7, C.enemyDark))
            lean.addChild(D.rr(-26, -176, 52, 104, 18, C.enemy)); lean.addChild(D.rr(-28, -122, 56, 10, 5, C.steel))
            face(14, -206, 32); dome(4, -214, 36); lean.addChild(D.rr(-36, -218, 80, 10, 5, C.steel)); lean.addChild(D.circle(4, -252, 7, C.steel))
            weapon.addChild(D.rr(-40, -140, 150, 10, 5, SKColor(hex: 0x7a5530)))
            weapon.addChild(D.circle(118, -135, 17, C.padded, SKColor(hex: 0xb8ab90), 3))
            weapon.addChild(D.ellipse(86, -150, 14, 9, SKColor(hex: 0x9b8fc0)))
            handsUp.addChild(D.circle(-30, -190, 10, C.skin)); handsUp.addChild(D.circle(36, -194, 10, C.skin))
        case .shield:
            legL.addChild(D.rr(-34, -64, 26, 62, 9, C.enemyDark)); legR.addChild(D.rr(8, -64, 26, 62, 9, C.enemyDark))
            lean.addChild(D.ellipse(0, -112, 58, 56, C.enemy))
            face(10, -182, 34); dome(0, -192, 38)
            lean.addChild(D.rr(-40, -196, 14, 34, 6, C.steel)); lean.addChild(D.rr(26, -196, 14, 34, 6, C.steel))
            weapon.addChild(D.rr(34, -168, 46, 120, 10, C.teal, SKColor(hex: 0x2b4f4f), 5))
            for ry in [-150.0, -108, -66] { weapon.addChild(D.circle(57, ry, 5, SKColor(hex: 0xc8d3d3))) }
            handsUp.addChild(D.circle(-40, -160, 12, C.skin)); handsUp.addChild(D.circle(44, -164, 12, C.skin))
        case .leader:
            legL.addChild(D.rr(-50, -66, 36, 64, 12, C.enemyDark)); legR.addChild(D.rr(14, -66, 36, 64, 12, C.enemyDark))
            lean.addChild(D.poly([(-60, -170), (-100, -64), (-30, -70)], SKColor(hex: 0x3b3a6b)))
            lean.addChild(D.rr(-78, -174, 156, 116, 44, C.enemy)); lean.addChild(D.rr(-54, -156, 108, 56, 16, C.steel))
            lean.addChild(D.circle(0, -128, 10, C.gold))
            face(18, -198, 38); dome(6, -208, 42); lean.addChild(D.rr(-40, -212, 92, 10, 5, C.steel))
            lean.addChild(D.poly([(2, -246), (-40, -252), (-8, -242)], SKColor(hex: 0xc0733a)))
            let club = SKNode(); club.position = CGPoint(x: 60, y: 130)
            club.addChild(D.rr(-7, -16, 14, 100, 7, SKColor(hex: 0x7a5530)))
            club.addChild(D.ellipse(0, 96, 28, 32, C.padded))
            weapon.addChild(club)
            handsUp.addChild(D.circle(-80, -170, 14, C.skin)); handsUp.addChild(D.circle(90, -174, 14, C.skin))
        }
        lean.addChild(weapon); lean.addChild(handsUp)
        // telegraph: a drawn "!" bubble, gold, never red (combat GDD visuals)
        bubble.addChild(Art.bangBubble(side: 0))
        bubble.position = CGPoint(x: 0, y: topY + 20)
        addChild(bubble)
        for i in 0..<3 { let s = D.star(9, C.glow, C.goldDark); s.name = "\(i)"; dizzy.addChild(s) }
        dizzy.position = CGPoint(x: 0, y: topY - 20)
        addChild(dizzy)
        let s = min(1, 170 / Self.unitHeight(kind))
        setScale(s); weapon.xScale = 1 / s
        // z-order (§3.3): the "!" and the hurt swirl draw over the banner bar (scene z 8)
        for n in [bubble, dizzy] { n.setScale(1 / s); n.zPosition = 10 }
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(_ e: Enemy, t: Double) {
        let walking = e.state == .enter || e.state == .flee || (e.state == .approach && e.moving)
        let lw = walking ? sin(t * (e.state == .flee ? 24 : 12) + Double(e.id)) : 0
        legL.position.x = lw * 8; legR.position.x = -lw * 8
        xScaleFace(e.face == 0 ? 1 : e.face)
        lean.zRotation = -(e.state == .windup ? -0.12 : e.state == .strike ? 0.15 : 0) + (e.state == .hurt ? 0.12 : 0)
        weapon.isHidden = e.state == .flee; handsUp.isHidden = e.state != .flee
        let isDizzy = e.state == .flee || e.state == .hurt
        eyes.isHidden = isDizzy; swirl.isHidden = !isDizzy; dizzy.isHidden = !isDizzy
        for (i, s) in dizzy.children.enumerated() { let a = t * 5 + Double(i) * 2.1; s.position = CGPoint(x: cos(a) * 34, y: sin(a) * 10); s.zRotation = a }
        let reach: Double = e.state == .strike ? 40 : e.state == .windup ? -30 : 0
        weapon.position.x = kind == .leader ? 0 : reach * (kind == .shield ? 0.85 : 1)
        if kind == .leader, let club = weapon.children.first { club.zRotation = -(e.state == .windup ? -1.2 : e.state == .strike ? 0.6 : -0.4) }
        glow.isHidden = e.state != .windup; bubble.isHidden = e.state != .windup
        if e.state == .windup { let p = 0.5 + 0.5 * sin(t * 16); glow.alpha = 0.3 + 0.25 * p }
    }
    /// hud §3.3 (r8): the scene places the "!" (HintPlacement.bang) at a world offset from the feet (y down), with its
    /// tail towards the head: above it (side 0) or beside it (±1).
    func placeBubble(dx: Double, dy: Double, side: Int) {
        let s = xScale == 0 ? 1 : abs(xScale)
        bubble.position = CGPoint(x: dx / s, y: -dy / s)
        bubble.removeAllChildren(); bubble.addChild(Art.bangBubble(side: side))
    }
    private func xScaleFace(_ f: Double) { for c in [legL, legR, lean] { c.xScale = f } ; glow.xScale = 1 }
}

/// Quiz and story pictures. A picture id resolves through data/assets.json to a PNG; the debug
/// sample's `pic.icon.<name>` ids are drawn in code from the prototype's icon list (P-04 item 5).
/// Small shared drawings.
enum Art {
    /// The telegraph "!" bubble (ASSET-208 placeholder): gold #FFD54F-ish glow disc, ink-brown outline, a drawn "!"
    /// (bar over dot, not a glyph) and a short tail pointing at the head: down when above it (side 0), sideways when
    /// beside it (side +1: right of the head, tail pointing left). 64 × 64 plus the tail.
    static func bangBubble(side: Int) -> SKNode {
        let b = SKNode()
        let tail = D.poly([(-11, 22), (11, 22), (0, 40)], C.glow, C.goldDark, 4); tail.zRotation = -Double(side) * .pi / 2
        b.addChild(tail)
        b.addChild(D.circle(0, 0, 30, C.glow, C.goldDark, 4))
        b.addChild(D.rr(-5, -18, 10, 24, 5, C.ink)); b.addChild(D.circle(0, 14, 5.5, C.ink))
        for (z, c) in b.children.enumerated() { c.zPosition = CGFloat(z) }
        return b
    }
}

enum Pictures {
    static var files: [String: URL] = [:]

    static func node(_ id: String, size s: Double) -> SKNode {
        if let url = files[id], let img = UIImage(contentsOfFile: url.path) {
            let sp = SKSpriteNode(texture: SKTexture(image: img))
            let k = s * 1.6 / max(img.size.width, img.size.height)
            sp.size = CGSize(width: img.size.width * k, height: img.size.height * k)
            return sp
        }
        if id.hasPrefix("pic.icon.") { return icon(String(id.dropFirst("pic.icon.".count)), s) }
        let n = SKNode(); n.addChild(D.rr(-s * 0.6, -s * 0.6, s * 1.2, s * 1.2, 16, SKColor(white: 0.85, alpha: 1)))
        return n
    }

    /// The prototype's ICONS, generic objects with no history claim.
    static func icon(_ name: String, _ s: Double) -> SKNode {
        let n = SKNode()
        func flag(_ col: SKColor) {
            n.addChild(D.rr(-s * 0.5, -s * 0.7, 8, s * 1.4, 4, SKColor(hex: 0x6a4a2a)))
            n.addChild(D.poly([(-s * 0.45, -s * 0.68), (s * 0.1, -s * 0.8), (s * 0.7, -s * 0.6), (s * 0.7, -s * 0.05), (s * 0.1, -s * 0.2), (-s * 0.45, -s * 0.1)], col))
        }
        func helmet(_ v: Int) {
            switch v {
            case 0:
                let p = CGMutablePath(); p.addArc(center: CGPoint(x: 0, y: -s * 0.1), radius: s * 0.5, startAngle: 0, endAngle: .pi, clockwise: false); p.closeSubpath()
                n.addChild(D.shape(p, C.steel)); n.addChild(D.rr(-s * 0.6, s * 0.05, s * 1.2, s * 0.14, 6, SKColor(hex: 0x6f758a)))
                n.addChild(D.poly([(0, -s * 0.4), (-s * 0.45, -s * 0.75), (-s * 0.06, -s * 0.38)], SKColor(hex: 0xc0733a)))
            case 1: n.addChild(D.poly([(-s * 0.7, s * 0.2), (s * 0.7, s * 0.2), (0, -s * 0.6)], C.steel))
            default:
                n.addChild(D.rr(-s * 0.45, -s * 0.45, s * 0.9, s * 0.65, 14, C.steel))
                n.addChild(D.rr(-s * 0.55, s * 0.1, s * 0.22, s * 0.4, 6, SKColor(hex: 0x6f758a)))
                n.addChild(D.rr(s * 0.33, s * 0.1, s * 0.22, s * 0.4, 6, SKColor(hex: 0x6f758a)))
            }
        }
        switch name {
        case "flag": flag(C.red)
        case "flag2": flag(C.gold)
        case "flag3": flag(SKColor(hex: 0x3f9a8a))
        case "child":
            n.addChild(D.rr(-s * 0.2, s * 0.05, s * 0.16, s * 0.45, 6, C.indigo)); n.addChild(D.rr(s * 0.04, s * 0.05, s * 0.16, s * 0.45, 6, C.indigo))
            n.addChild(D.rr(-s * 0.3, -s * 0.4, s * 0.6, s * 0.55, 14, C.red)); n.addChild(D.circle(0, -s * 0.62, s * 0.3, C.skin))
            n.addChild(D.circle(-s * 0.1, -s * 0.6, 4, C.ink)); n.addChild(D.circle(s * 0.1, -s * 0.6, 4, C.ink))
        case "hourglass":
            n.addChild(D.rr(-s * 0.5, -s * 0.75, s, s * 0.12, 6, C.wood)); n.addChild(D.rr(-s * 0.5, s * 0.55, s, s * 0.12, 6, C.wood))
            n.addChild(D.poly([(-s * 0.38, -s * 0.63), (s * 0.38, -s * 0.63), (s * 0.06, -s * 0.04), (s * 0.38, s * 0.55), (-s * 0.38, s * 0.55), (-s * 0.06, -s * 0.04)], SKColor(hex: 0xd7eef5), C.wood, 4))
            n.addChild(D.poly([(-s * 0.3, s * 0.55), (s * 0.3, s * 0.55), (0, s * 0.22)], C.gold))
        case "bed":
            n.addChild(D.rr(-s * 0.8, -s * 0.35, s * 0.14, s * 0.8, 5, C.wood)); n.addChild(D.rr(s * 0.66, -s * 0.05, s * 0.14, s * 0.5, 5, C.wood))
            n.addChild(D.rr(-s * 0.8, s * 0.05, s * 1.6, s * 0.18, 6, SKColor(hex: 0xa8794a))); n.addChild(D.rr(-s * 0.62, -s * 0.12, s * 0.38, s * 0.2, 10, .white))
            n.addChild(D.rr(-s * 0.3, -s * 0.16, s * 0.96, s * 0.24, 10, SKColor(hex: 0x7aa8d8)))
        case "orange":
            n.addChild(D.circle(0, 0, s * 0.5, SKColor(hex: 0xf39a1e), SKColor(hex: 0xc97010), 4))
            n.addChild(D.ellipse(s * 0.14, -s * 0.56, s * 0.2, s * 0.08, C.leafDark))
        case "banana":
            n.addChild(D.poly([(-s * 0.6, -s * 0.3), (-s * 0.3, s * 0.2), (s * 0.1, s * 0.25), (s * 0.6, -s * 0.15), (0, s * 0.05), (-s * 0.35, -s * 0.1)], SKColor(hex: 0xf5d33a), SKColor(hex: 0xb8960f), 4))
        case "coconut":
            n.addChild(D.circle(0, 0, s * 0.5, SKColor(hex: 0x7a5032), SKColor(hex: 0x5a3820), 4))
            for (x, y) in [(-0.12, -0.12), (0.1, -0.12), (0, 0.06)] { n.addChild(D.circle(s * x, s * y, s * 0.06, SKColor(hex: 0x3e2614))) }
        case "helmet": helmet(0)
        case "helmet2": helmet(1)
        case "helmet3": helmet(2)
        default: n.addChild(D.circle(0, 0, s * 0.4, SKColor(white: 0.85, alpha: 1)))
        }
        return n
    }
}

/// A beat theme's backdrop: stand-in places (no history claim), drawn along the whole mission.
enum Backdrop {
    /// Sky colours per theme from content/data/themes.json (ADR-0002); set at boot. No colour is hard-coded.
    static var bands: [String: (top: SKColor, bottom: SKColor)] = [:]

    static func hex(_ s: String) -> SKColor { SKColor(hex: UInt32(s.dropFirst(), radix: 16) ?? 0) }

    /// The flat fallback (the band's bottom colour) behind everything.
    static func sky(_ theme: String) -> SKColor { bands[theme]?.bottom ?? .black }

    /// A vertical gradient from the band's top colour to its bottom colour (ADR-0002 sky band), cached per theme.
    private static var gradients: [String: SKTexture] = [:]
    static func skyNode(_ theme: String, width: Double, height: Double) -> SKNode {
        let tex = gradients[theme] ?? {
            let band = bands[theme] ?? (top: .black, bottom: .black)
            let size = CGSize(width: 4, height: 256)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [band.top.cgColor, band.bottom.cgColor] as CFArray, locations: [0, 1])!
                ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            let t = SKTexture(image: img); gradients[theme] = t; return t
        }()
        let n = SKSpriteNode(texture: tex, size: CGSize(width: width, height: height))
        n.anchorPoint = CGPoint(x: 0, y: 1)
        return n
    }

    /// World-space props from x0 to x1 (prototype ground_y).
    static func world(theme: String, from x0: Double, to x1: Double, ground: Double) -> SKNode {
        let n = SKNode()
        n.addChild(D.rr(x0, ground - 4, x1 - x0, 720 - ground + 4 + 600, 0, C.earth)) // runs below the world (Rule 1 outside area)
        n.addChild(D.rr(x0, ground - 4, x1 - x0, 14, 0, C.earthDark))
        var x = x0
        var i = 0
        while x < x1 {
            switch theme {
            case "bamboo":
                for (dx, h) in [(0.0, 300.0), (40, 360), (80, 260)] {
                    n.addChild(D.rr(x + dx, ground - h, 18, h, 8, C.leaf))
                    for j in 1..<4 { n.addChild(D.rr(x + dx - 1, ground - h * Double(j) / 4, 20, 5, 2, C.leafDark)) }
                }
            case "river":
                n.addChild(D.rr(x, ground - 70, 300, 40, 18, C.river))
                if i % 2 == 0 { n.addChild(D.poly([(x + 60, ground - 90), (x + 200, ground - 90), (x + 170, ground - 60), (x + 90, ground - 60)], SKColor(hex: 0x9a6a3a))) }
            case "camp":
                n.addChild(D.poly([(x + 20, ground), (x + 120, ground - 170), (x + 220, ground)], SKColor(hex: 0xd9b26a)))
                n.addChild(D.rr(x + 100, ground - 200, 6, 40, 3, SKColor(hex: 0x6a4a2a)))
            default:
                n.addChild(D.rr(x + 30, ground - 120, 180, 120, 6, SKColor(hex: 0xa8794a)))
                n.addChild(D.poly([(x, ground - 110), (x + 120, ground - 220), (x + 240, ground - 110)], SKColor(hex: 0xd9b26a)))
            }
            n.addChild(D.ellipse(x + 260, ground - 30, 40, 26, C.leafDark))
            x += 420; i += 1
        }
        return n
    }
}
