// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// (a) SpriteKit: draws what MorphCore computes. The glyph glows, dissolves into N stardust particles that fly to the
// silhouette, the object fades in and bobs. One reused set of nodes: a new press replaces the morph, never stacks.
import SpriteKit
import QuartzCore
import MorphCore

final class MorphScene: SKScene, Stage {
    weak var controller: SpikeController?
    let spec: MorphSpec
    private var glyphPaths: [String: String] = [:], silhouette = ""
    private var morphs: [String: Morph] = [:]
    private var current: Morph?, startTime: Double?, pendingKey: String?
    private let root = SKNode(), glyphNode = SKShapeNode(), objectNode = SKShapeNode()
    private var particles: [SKSpriteNode] = []
    private var lastTime = 0.0

    init(spec: MorphSpec) {
        self.spec = spec
        super.init(size: CGSize(width: 1194, height: 834))
        scaleMode = .resizeFill; anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.12, green: 0.15, blue: 0.30, alpha: 1) // dusk blue
        for k in ["D", "B", "3"] { glyphPaths[k] = Self.json("glyph-\(k)")["d"] as? String }
        silhouette = Self.json("silhouette-dinosaur")["d"] as! String
        addChild(root)
        glyphNode.fillColor = SKColor(red: 1, green: 0.93, blue: 0.75, alpha: 1); glyphNode.strokeColor = SKColor(red: 1, green: 0.85, blue: 0.5, alpha: 1)
        glyphNode.glowWidth = 10; glyphNode.lineWidth = 3; glyphNode.alpha = 0
        objectNode.fillColor = SKColor(red: 0.45, green: 0.78, blue: 0.52, alpha: 1); objectNode.strokeColor = SKColor(red: 0.2, green: 0.45, blue: 0.3, alpha: 1)
        objectNode.lineWidth = 4; objectNode.alpha = 0
        root.addChild(objectNode); root.addChild(glyphNode)
        let tex = SKTexture(cgImage: Self.dot())
        for _ in 0..<spec.count {
            let p = SKSpriteNode(texture: tex); p.blendMode = .add; p.size = CGSize(width: 14, height: 14); p.alpha = 0
            p.color = SKColor(red: 1, green: 0.85, blue: 0.45, alpha: 1); p.colorBlendFactor = 1
            root.addChild(p); particles.append(p)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    static func json(_ name: String) -> [String: Any] {
        let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "fixtures")!
        return try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    }

    static func dot() -> CGImage {
        let n = 32, ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 1), CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: n / 2, y: n / 2), startRadius: 0, endCenter: CGPoint(x: n / 2, y: n / 2), endRadius: CGFloat(n / 2), options: [])
        return ctx.makeImage()!
    }

    var unit: CGFloat { min(size.width, size.height) * 0.6 }
    func pt(_ p: Pt) -> CGPoint { CGPoint(x: p.x * unit, y: -p.y * unit) } // MorphCore is y down

    func cgPath(_ d: String) -> CGPath {
        let path = CGMutablePath()
        for line in (try? SVGPath.normalisedPolylines(d)) ?? [] {
            guard let f = line.first else { continue }
            path.move(to: pt(f)); for q in line.dropFirst() { path.addLine(to: pt(q)) }; path.closeSubpath()
        }
        return path
    }

    // MARK: Stage

    func start(key: String) { pendingKey = key }
    private var animating = false
    var activeMorphs: Int { animating ? 1 : 0 }

    override func update(_ currentTime: TimeInterval) {
        lastTime = currentTime
        if let k = pendingKey, let g = glyphPaths[k] {
            pendingKey = nil
            // cold path: the first press of a key samples its glyph (MorphCore) and builds its shape
            let m: Morph
            if let c = morphs[k] { m = c } else { m = try! Morph(spec: spec, glyphPath: g, silhouettePath: silhouette); morphs[k] = m }
            current = m; startTime = currentTime
            glyphNode.path = cgPath(g); objectNode.path = cgPath(silhouette)
        }
        guard let m = current, let t0 = startTime else { return }
        let s = currentTime - t0, dur = spec.duration
        animating = s < dur + 0.5
        // the glyph: glows (gentle pulse), then fades as it dissolves
        if s < spec.glow { glyphNode.alpha = 0.8 + 0.2 * CGFloat(sin(s * 9)) }
        else { glyphNode.alpha = CGFloat(max(0, 1 - (s - spec.glow) / spec.dissolve)) }
        // the stardust
        let pa: Double = s < spec.glow ? 0 : (s < spec.glow + spec.dissolve ? (s - spec.glow) / spec.dissolve : (s < dur ? 1 : max(0, 1 - (s - dur) / 0.4)))
        if pa > 0 || s < dur + 0.5 {
            for i in 0..<particles.count {
                let p = particles[i]
                p.position = pt(m.position(i, at: s))
                p.alpha = CGFloat(pa * (0.7 + 0.3 * sin(s * 8 + Double(i))))
            }
        }
        // the object fades in as the particles land, then idles
        objectNode.alpha = CGFloat(min(1, max(0, (s - dur + 0.15) / 0.5)))
        objectNode.position.y = s > dur ? CGFloat(sin((s - dur) * 2.5) * 6) : 0
        if s > dur + 0.5 { for p in particles where p.alpha != 0 { p.alpha = 0 } }
    }

    override func didFinishUpdate() {
        Metrics.shared.frame(at: CACurrentMediaTime())
        MainActor.assumeIsolated { controller?.frameTick() }
    }
}
