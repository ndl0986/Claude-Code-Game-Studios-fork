// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0009; P-2, P-3, P-11, P-13, M-10, M-12, M-13)
// The full stage under ADR-0006: a stage root with the F1 transform and the y flip, fixed layers z0…z80, the
// Scene's worst case (Night, snow 60 + windy, 3 clouds, 50 stars), a current and a leaving creature, the glyph and
// 240 specks from MorphCore, and a parade of 6. Creatures are drawn by option A (one SKShapeNode per SVG shape) or
// option B (each part rasterised once into a texture). Frame times go to FrameStats; a debug frame dump writes PNGs.
import SpriteKit
import ImageIO
import SpikeKit
import MorphCore
#if os(iOS)
import UIKit
#else
import AppKit
#endif

enum RenderOption: String, CaseIterable, Identifiable {
    case a = "A: per element", aCandidate = "A: candidate (ADR-0009 D3)", b = "B: per-part textures"
    var id: String { rawValue }
}

final class FrameStats: @unchecked Sendable {
    private var last = 0.0
    private(set) var deltas: [Double] = []
    func tick(_ t: Double) { if last > 0 { deltas.append((t - last) * 1000); if deltas.count > 1200 { deltas.removeFirst(deltas.count - 1200) } }; last = t }
    func reset() { deltas = []; last = 0 }
    func percentile(_ p: Double) -> Double {
        guard !deltas.isEmpty else { return 0 }
        let s = deltas.sorted(); return s[min(s.count - 1, Int(Double(s.count - 1) * p))]
    }
}

final class RenderScene: SKScene {
    var option: RenderOption = .a { didSet { if oldValue != option { rebuildCreatures() } } }
    var pxPerPt: CGFloat = 2
    let stats = FrameStats()
    var dumpRemaining = 0, dumpIndex = 0
    var onLog: (String) -> Void = { _ in }
    private let root = SKNode()
    private var layers: [Int: SKNode] = [:]
    private var art: [Part] = []
    private var current: SKNode?, leaving: SKNode?, walkers: [SKNode] = []
    private var flakes: [SKSpriteNode] = [], stars: [SKSpriteNode] = [], clouds: [SKShapeNode] = []
    private var specks: [SKSpriteNode] = []
    private let glyph = SKShapeNode()
    private var morph: Morph?, morphT0 = 0.0
    private(set) var fit = StageFit(windowPxW: 2560, windowPxH: 1440)
    private var built = false
    private var loadMs: [String: Double] = [:]

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill; anchorPoint = .zero
        backgroundColor = SKColor(red: 0.07, green: 0.09, blue: 0.20, alpha: 1)
        addChild(root)
        for z in [0, 10, 20, 30, 35, 40, 50, 60, 70, 80] { let n = SKNode(); n.zPosition = CGFloat(z); layers[z] = n; root.addChild(n) }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didChangeSize(_ oldSize: CGSize) { layout() }

    func layout() {
        guard !layers.isEmpty else { return }          // SKScene(size:) calls didChangeSize before our layers exist
        fit = StageFit(windowPxW: Double(size.width * pxPerPt), windowPxH: Double(size.height * pxPerPt))
        let s = CGFloat(fit.scale) / pxPerPt
        root.xScale = s; root.yScale = -s                                  // KidCore y-down → SpriteKit y-up
        root.position = CGPoint(x: CGFloat(fit.offsetX) / pxPerPt, y: size.height - CGFloat(fit.offsetY) / pxPerPt)
        if !built && size.width > 10 { build(); built = true }
    }

    // MARK: building
    func build() {
        art = Self.loadArt()
        onLog("art: \(art.isEmpty ? "none (TASK-077 not merged): using the TASK-033 silhouette" : art.map(\.id).joined(separator: ","))")
        buildScene(); buildGlyph(); rebuildCreatures()
    }

    static func loadArt() -> [Part] {
        guard let dir = Bundle.main.url(forResource: "art", withExtension: nil),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return files.filter { $0.pathExtension == "svg" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? SVGArt.parse(Data(contentsOf: $0)) }
    }

    static func color(_ rgb: UInt32?, _ a: Double) -> SKColor {
        guard let v = rgb else { return .clear }
        return SKColor(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: CGFloat(a))
    }

    static func cgPath(_ ops: [PathOp], dx: Double = 0, dy: Double = 0) -> CGPath {
        let p = CGMutablePath()
        for o in ops {
            switch o {
            case .move(let x, let y): p.move(to: CGPoint(x: x - dx, y: y - dy))
            case .line(let x, let y): p.addLine(to: CGPoint(x: x - dx, y: y - dy))
            case .quad(let a, let b, let x, let y): p.addQuadCurve(to: CGPoint(x: x - dx, y: y - dy), control: CGPoint(x: a - dx, y: b - dy))
            case .cubic(let a, let b, let c, let d, let x, let y):
                p.addCurve(to: CGPoint(x: x - dx, y: y - dy), control1: CGPoint(x: a - dx, y: b - dy), control2: CGPoint(x: c - dx, y: d - dy))
            case .close: p.closeSubpath()
            }
        }
        return p
    }

    /// A part as a node positioned at its pivot (relative to its parent part's pivot), so idles rotate about pivots.
    func node(for part: Part, parentPivot: (Double, Double), name: String) -> SKNode {
        let n = SKNode(); n.name = part.id
        n.position = CGPoint(x: part.pivot.0 - parentPivot.0, y: part.pivot.1 - parentPivot.1)
        var own: [Shape] = []
        for item in part.items {
            switch item {
            case .layer(let l):
                if option == .aCandidate { n.addChild(candidate(l, pivot: part.pivot)) } else { own.append(contentsOf: l.shapes) }
            case .part(let child):
                if !own.isEmpty { n.addChild(content(own, pivot: part.pivot)); own = [] }
                n.addChild(node(for: child, parentPivot: part.pivot, name: name))
            }
        }
        if !own.isEmpty { n.addChild(content(own, pivot: part.pivot)) }
        return n
    }

    /// ADR-0009 D3's candidate A (game-dev-ios review): the outline layer of a part is ONE merged path stroked by ONE
    /// node at the layer's opacity (group-opacity look); body and detail fills stay one node per element, because
    /// merging fills under nonzero winding can cut holes where shapes overlap with opposite winding.
    func candidate(_ l: Layer, pivot: (Double, Double)) -> SKNode {
        if l.name == "outline", let first = l.shapes.first {
            let merged = CGMutablePath()
            for sh in l.shapes { merged.addPath(Self.cgPath(sh.ops, dx: pivot.0, dy: pivot.1)) }
            let s = SKShapeNode(path: merged)
            s.fillColor = .clear
            s.strokeColor = Self.color(first.style.stroke, first.style.opacity)
            s.lineWidth = CGFloat(first.style.strokeWidth)
            s.lineJoin = .round; s.lineCap = .round; s.isAntialiased = true
            return s
        }
        let g = SKNode()
        for sh in l.shapes {
            let s = SKShapeNode(path: Self.cgPath(sh.ops, dx: pivot.0, dy: pivot.1))
            s.fillColor = Self.color(sh.style.fill, sh.style.fillOpacity * sh.style.opacity)
            s.strokeColor = Self.color(sh.style.stroke, sh.style.opacity)
            s.lineWidth = sh.style.stroke == nil ? 0 : CGFloat(sh.style.strokeWidth)
            s.lineJoin = .round; s.lineCap = .round; s.isAntialiased = true
            g.addChild(s)
        }
        return g
    }

    /// ADR-0009 H-2 on the device: does ONE SKShapeNode's self-overlapping stroke darken (blend twice) at alpha 0.8?
    /// Renders an X (two crossing strokes in one path) white over black, two ways, samples the crossing and an arm, logs.
    func overlapCheck() {
        guard let view else { onLog("overlap check: no view"); return }
        func sample(_ node: SKNode) -> (cross: Double, arm: Double)? {
            let bg = SKSpriteNode(color: .black, size: CGSize(width: 200, height: 200)); bg.addChild(node)
            guard let img = view.texture(from: bg)?.cgImage(), let data = img.dataProvider?.data, let b = CFDataGetBytePtr(data) else { return nil }
            let bpr = img.bytesPerRow, bpp = img.bitsPerPixel / 8
            func lum(_ x: Int, _ y: Int) -> Double { let o = y * bpr + x * bpp; return (Double(b[o]) + Double(b[o + 1]) + Double(b[o + 2])) / (3 * 255) }
            let cx = img.width / 2, cy = img.height / 2
            return (lum(cx, cy), lum(cx + img.width / 5, cy + img.height / 5))   // the crossing, and a point on one arm
        }
        let x = CGMutablePath(); x.move(to: CGPoint(x: -70, y: -70)); x.addLine(to: CGPoint(x: 70, y: 70))
        x.move(to: CGPoint(x: -70, y: 70)); x.addLine(to: CGPoint(x: 70, y: -70))
        let v1 = SKShapeNode(path: x); v1.strokeColor = SKColor(white: 1, alpha: 0.8); v1.lineWidth = 12; v1.lineCap = .round
        let v2 = SKShapeNode(path: x); v2.strokeColor = .white; v2.lineWidth = 12; v2.lineCap = .round; v2.alpha = 0.8
        for (name, n) in [("stroke alpha 0.8", v1), ("node alpha 0.8", v2)] {
            if let r = sample(n) {
                let darkens = r.cross > r.arm + 0.02                       // over black, a double blend reads brighter (0.96 vs 0.8)
                onLog(String(format: "overlap check (%@): crossing %.3f, arm %.3f → %@", name, r.cross, r.arm,
                              darkens ? "BLENDS TWICE (the outline needs an effect node or a texture)" : "blends once (group look holds)"))
            } else { onLog("overlap check (\(name)): no image") }
        }
    }

    /// Option A: one SKShapeNode per shape. Option B: the shapes rasterised once into one sprite.
    func content(_ shapes: [Shape], pivot: (Double, Double)) -> SKNode {
        switch option {
        case .a, .aCandidate:
            let g = SKNode()
            for sh in shapes {
                let s = SKShapeNode(path: Self.cgPath(sh.ops, dx: pivot.0, dy: pivot.1))
                s.fillColor = Self.color(sh.style.fill, sh.style.fillOpacity * sh.style.opacity)
                s.strokeColor = Self.color(sh.style.stroke, sh.style.opacity)
                s.lineWidth = sh.style.stroke == nil ? 0 : CGFloat(sh.style.strokeWidth)
                s.lineJoin = .round; s.lineCap = .round; s.isAntialiased = true
                g.addChild(s)
            }
            return g
        case .b:
            let scale: CGFloat = 2.5                                           // ≈ the stage tier for a 13" iPad
            var box = CGRect.null
            for sh in shapes { box = box.union(Self.cgPath(sh.ops).boundingBoxOfPath.insetBy(dx: -CGFloat(sh.style.strokeWidth), dy: -CGFloat(sh.style.strokeWidth))) }
            let w = max(1, Int(box.width * scale)), h = max(1, Int(box.height * scale))
            guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return SKNode() }
            ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: scale, y: -scale); ctx.translateBy(x: -box.minX, y: -box.minY)
            for sh in shapes {
                let p = Self.cgPath(sh.ops)
                if let f = sh.style.fill { ctx.addPath(p); ctx.setFillColor(Self.color(f, sh.style.fillOpacity * sh.style.opacity).cgColor); ctx.fillPath() }
                if let st = sh.style.stroke {
                    ctx.addPath(p); ctx.setStrokeColor(Self.color(st, sh.style.opacity).cgColor); ctx.setLineWidth(CGFloat(sh.style.strokeWidth))
                    ctx.setLineJoin(.round); ctx.setLineCap(.round); ctx.strokePath()
                }
            }
            let sprite = SKSpriteNode(texture: SKTexture(cgImage: ctx.makeImage()!))
            sprite.size = box.size; sprite.yScale = -1                         // the root flips y; textures are drawn upright
            sprite.position = CGPoint(x: box.midX - pivot.0, y: box.midY - pivot.1)
            return sprite
        }
    }

    func creature(_ i: Int, scale: CGFloat) -> SKNode {
        let t0 = ProcessInfo.processInfo.systemUptime
        let wrap = SKNode()
        if art.isEmpty {
            let s = SKShapeNode(path: Self.silhouette()); s.fillColor = SKColor(red: 0.45, green: 0.78, blue: 0.52, alpha: 1)
            s.strokeColor = SKColor(red: 0.16, green: 0.14, blue: 0.25, alpha: 0.8); s.lineWidth = 6; wrap.addChild(s)
        } else {
            let p = art[i % art.count]
            let n = node(for: p, parentPivot: p.pivot, name: p.id); n.position = .zero; wrap.addChild(n)
        }
        wrap.setScale(scale)
        loadMs["\(option == .a ? "A" : "B")#\(i)"] = (ProcessInfo.processInfo.systemUptime - t0) * 1000
        return wrap
    }

    static func silhouette() -> CGPath {
        guard let url = Bundle.main.url(forResource: "silhouette-dinosaur", withExtension: "json", subdirectory: "fixtures"),
              let obj = try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any], let d = obj["d"] as? String,
              let ops = try? SVGArt.pathOps(d, .translate(-320, -560)) else { return CGPath(rect: CGRect(x: -100, y: -200, width: 200, height: 200), transform: nil) }
        return cgPath(ops)
    }

    func rebuildCreatures() {
        current?.removeFromParent(); leaving?.removeFromParent(); walkers.forEach { $0.removeFromParent() }; walkers = []
        current = creature(0, scale: 0.8); current!.position = CGPoint(x: 640, y: 600); layers[30]!.addChild(current!)
        leaving = creature(1, scale: 0.8); leaving!.position = CGPoint(x: 300, y: 600); leaving!.alpha = 0.5; layers[20]!.addChild(leaving!)
        for i in 0..<6 { let w = creature(i, scale: 0.2); w.position = CGPoint(x: -100 - Double(i) * 150, y: 558); layers[10]!.addChild(w); walkers.append(w) }
        onLog("creatures built with option \(option == .a ? "A" : "B"): " + loadMs.sorted { $0.key < $1.key }.map { "\($0.key)=\(String(format: "%.1f", $0.value)) ms" }.joined(separator: " "))
        loadMs = [:]; stats.reset()
    }

    func buildScene() {
        let sky = SKSpriteNode(color: SKColor(red: 0.07, green: 0.09, blue: 0.20, alpha: 1), size: CGSize(width: 4000, height: 1200))
        sky.position = CGPoint(x: 640, y: 200); layers[0]!.addChild(sky)
        let hills = SKShapeNode(path: CGPath(ellipseIn: CGRect(x: -600, y: 470, width: 2500, height: 400), transform: nil))
        hills.fillColor = SKColor(red: 0.18, green: 0.23, blue: 0.39, alpha: 1); hills.strokeColor = .clear; layers[0]!.addChild(hills)
        let ground = SKSpriteNode(color: SKColor(red: 0.66, green: 0.62, blue: 0.53, alpha: 1), size: CGSize(width: 4000, height: 600))
        ground.position = CGPoint(x: 640, y: 858); layers[0]!.addChild(ground)
        let dot = SKTexture(cgImage: Self.dot())
        for i in 0..<50 { let s = SKSpriteNode(texture: dot); s.size = CGSize(width: 6, height: 6); s.position = CGPoint(x: Double((i * 97) % 1280), y: Double((i * 53) % 300) + 10); layers[0]!.addChild(s); stars.append(s) }
        for i in 0..<3 { let c = SKShapeNode(ellipseOf: CGSize(width: 220, height: 70)); c.fillColor = SKColor(white: 0.85, alpha: 0.35); c.strokeColor = .clear; c.position = CGPoint(x: 200 + i * 420, y: 120 + (i % 2) * 60); layers[0]!.addChild(c); clouds.append(c) }
        for i in 0..<60 { let f = SKSpriteNode(texture: dot); f.size = CGSize(width: 9, height: 9); f.color = SKColor(red: 0.81, green: 0.84, blue: 0.89, alpha: 1); f.colorBlendFactor = 1; f.position = CGPoint(x: Double((i * 211) % 1400) - 60, y: Double((i * 37) % 700)); layers[0]!.addChild(f); flakes.append(f) }
    }

    func buildGlyph() {
        guard let url = Bundle.main.url(forResource: "glyph-D", withExtension: "json", subdirectory: "fixtures"),
              let obj = try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any], let d = obj["d"] as? String,
              let sil = (try? JSONSerialization.jsonObject(with: Data(contentsOf: Bundle.main.url(forResource: "silhouette-dinosaur", withExtension: "json", subdirectory: "fixtures")!))) as? [String: Any],
              let sd = sil["d"] as? String else { return }
        let spec = MorphSpec(count: 240, seed: 2026, glow: 0.8, dissolve: 0.4, travel: 1.25, spread: 0.35, drift: 0.06, swirl: 0.35, hold: 3)
        morph = try? Morph(spec: spec, glyphPath: d, silhouettePath: sd)
        if let lines = try? SVGPath.normalisedPolylines(d) {
            let gp = CGMutablePath()
            for l in lines { guard let f = l.first else { continue }; gp.move(to: CGPoint(x: 640 + f.x * 330, y: 360 + f.y * 330)); for q in l.dropFirst() { gp.addLine(to: CGPoint(x: 640 + q.x * 330, y: 360 + q.y * 330)) }; gp.closeSubpath() }
            glyph.path = gp; glyph.fillColor = SKColor(red: 1, green: 0.83, blue: 0.43, alpha: 1); glyph.strokeColor = SKColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1)
            glyph.lineWidth = 6; glyph.glowWidth = 8; layers[40]!.addChild(glyph)
        }
        let dot = SKTexture(cgImage: Self.dot())
        for _ in 0..<240 { let p = SKSpriteNode(texture: dot); p.blendMode = .add; p.size = CGSize(width: 10, height: 10); p.color = SKColor(red: 1, green: 0.82, blue: 0.48, alpha: 1); p.colorBlendFactor = 1; layers[40]!.addChild(p); specks.append(p) }
    }

    static func dot() -> CGImage {
        let n = 32, ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 1), CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: n / 2, y: n / 2), startRadius: 0, endCenter: CGPoint(x: n / 2, y: n / 2), endRadius: CGFloat(n / 2), options: [])
        return ctx.makeImage()!
    }

    // MARK: per frame
    override func update(_ currentTime: TimeInterval) {
        stats.tick(currentTime)
        let t = currentTime
        if morphT0 == 0 { morphT0 = t }
        // the morph loops every 3.5 s: glyph, then specks to the silhouette (spec units → stage box at the creature)
        if let m = morph {
            let s = (t - morphT0).truncatingRemainder(dividingBy: 3.5)
            glyph.alpha = s < m.spec.glow ? 1 : max(0, 1 - CGFloat((s - m.spec.glow) / m.spec.dissolve))
            let pa: CGFloat = s < m.spec.glow ? 0 : 1
            for (i, p) in specks.enumerated() {
                let q = m.position(i, at: s); p.position = CGPoint(x: 640 + q.x * 330, y: 360 + q.y * 330)
                p.alpha = pa * CGFloat(0.6 + 0.4 * sin(9 * s + Double(i)))
            }
        }
        // idles: parts named neck/head/jaw/tail/wing* rotate gently about their pivots (≤ 1 Hz)
        for c in [current, leaving].compactMap({ $0 }) + walkers {
            c.enumerateChildNodes(withName: "//*") { n, _ in
                switch n.name ?? "" {
                case "neck": n.zRotation = CGFloat(0.05 * sin(2 * .pi * 0.25 * t))
                case "head": n.zRotation = CGFloat(0.04 * sin(2 * .pi * 0.33 * t))
                case "jaw": n.zRotation = CGFloat(0.06 * max(0, sin(2 * .pi * 0.5 * t)))
                case "tail": n.zRotation = CGFloat(0.06 * sin(2 * .pi * 0.4 * t))
                case "wing_far", "wing_near": n.zRotation = CGFloat(0.25 * sin(2 * .pi * 0.9 * t))
                default: break
                }
            }
        }
        // the parade walks across the visible rect in 11 s
        let w = fit.visibleW, speed = (w + 200 + 900) / 11
        let pt = (t - morphT0).truncatingRemainder(dividingBy: 11)
        for (i, n) in walkers.enumerated() { n.position.x = CGFloat(fit.visibleX - 100 + speed * pt - Double(i) * 150) }
        // weather: snow 60 + windy (tilt 15°), stars twinkle ≤ 0.35 Hz, clouds drift ×2
        for (i, f) in flakes.enumerated() {
            var y = f.position.y + 0.5, x = f.position.x + 0.13 + 0.3 * sin(2 * .pi * 0.3 * t + Double(i))
            if y > 760 { y = -20; x = Double((i * 211) % 1400) - 60 }
            f.position = CGPoint(x: x, y: y)
        }
        for (i, s) in stars.enumerated() { s.alpha = CGFloat(0.6 + 0.4 * sin(2 * .pi * 0.3 * t + Double(i))) }
        for c in clouds { c.position.x += 0.27; if c.position.x > 1500 { c.position.x = -220 } }
    }

    override func didFinishUpdate() {
        if stats.deltas.count == 600, UserDefaults.standard.bool(forKey: "smoke") {
            onLog(String(format: "smoke: 600 frames, option %@, p50 %.2f ms p99 %.2f ms (Simulator: not evidence)", option == .a ? "A" : "B", stats.percentile(0.5), stats.percentile(0.99)))
        }
        guard dumpRemaining > 0, let v = view, let tex = v.texture(from: self) else { return }
        let img = tex.cgImage()
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("framedump", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(String(format: "f%05d.png", dumpIndex))
        if let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) { CGImageDestinationAddImage(dest, img, nil); CGImageDestinationFinalize(dest) }
        dumpIndex += 1; dumpRemaining -= 1
        if dumpRemaining == 0 { onLog("frame dump done: \(dumpIndex) frames in \(dir.path)") }
    }
}
