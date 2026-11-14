import SpriteKit

/// The prototype's palette (art bible: warm primaries to touch and reward; red never reads as blood).
enum C {
    static let red = SKColor(hex: 0xd9342b), gold = SKColor(hex: 0xf2b632), goldDark = SKColor(hex: 0xc98a12)
    static let cream = SKColor(hex: 0xfff6e3), ink = SKColor(hex: 0x3a2a1f), skin = SKColor(hex: 0xf5c9a0)
    static let hair = SKColor(hex: 0x231a16), indigo = SKColor(hex: 0x2b4c8c), leaf = SKColor(hex: 0x6cbf4f)
    static let leafDark = SKColor(hex: 0x3f8a3a), river = SKColor(hex: 0x5ab4d6), earth = SKColor(hex: 0xc99a5b)
    static let earthDark = SKColor(hex: 0xa87a45), enemy = SKColor(hex: 0x6b5b95), enemyDark = SKColor(hex: 0x4b3f6e)
    static let steel = SKColor(hex: 0x8d93a8), teal = SKColor(hex: 0x3e6b6b), glow = SKColor(hex: 0xffe24a)
    static let panel = SKColor(red: 42 / 255, green: 36 / 255, blue: 64 / 255, alpha: 0.86)
    static let night = SKColor(hex: 0x2a2440), wood = SKColor(hex: 0x8a5a2b), padded = SKColor(hex: 0xe9e1cf)
    /// Wrong quiz answer (TASK-004 art fix): muted lavender, never red.
    static let wrong = SKColor(hex: 0x9C8FB8)
}

extension SKColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
    }
}

/// Drawing helpers in the prototype's coordinates: y grows DOWN. `D.p(x, y)` maps a screen point
/// (1280×720, y down) to SpriteKit; shapes built with `rr` / `circle` use local y-down coords.
enum D {
    static func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: 720 - y) }

    static func shape(_ path: CGPath, _ fill: SKColor?, _ stroke: SKColor? = nil, _ lw: CGFloat = 0) -> SKShapeNode {
        let n = SKShapeNode(path: path)
        n.fillColor = fill ?? .clear
        n.strokeColor = stroke ?? .clear
        n.lineWidth = stroke == nil ? 0 : lw
        n.isAntialiased = true
        return n
    }
    static func rr(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double, _ fill: SKColor?, _ stroke: SKColor? = nil, _ lw: CGFloat = 0) -> SKShapeNode {
        let rad = min(r, w / 2, h / 2)
        return shape(CGPath(roundedRect: CGRect(x: x, y: -(y + h), width: w, height: h), cornerWidth: rad, cornerHeight: rad, transform: nil), fill, stroke, lw)
    }
    static func circle(_ x: Double, _ y: Double, _ r: Double, _ fill: SKColor?, _ stroke: SKColor? = nil, _ lw: CGFloat = 0) -> SKShapeNode {
        shape(CGPath(ellipseIn: CGRect(x: x - r, y: -y - r, width: 2 * r, height: 2 * r), transform: nil), fill, stroke, lw)
    }
    static func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ fill: SKColor?) -> SKShapeNode {
        shape(CGPath(ellipseIn: CGRect(x: x - rx, y: -y - ry, width: 2 * rx, height: 2 * ry), transform: nil), fill)
    }
    /// A polygon from y-down points.
    static func poly(_ pts: [(Double, Double)], _ fill: SKColor?, _ stroke: SKColor? = nil, _ lw: CGFloat = 0) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: pts[0].0, y: -pts[0].1))
        for q in pts.dropFirst() { path.addLine(to: CGPoint(x: q.0, y: -q.1)) }
        path.closeSubpath()
        return shape(path, fill, stroke, lw)
    }
    /// A drawn 5-point star (rewards, bursts): never a font symbol.
    static func star(_ r: Double, _ fill: SKColor, _ stroke: SKColor? = nil) -> SKShapeNode {
        var pts: [(Double, Double)] = []
        for i in 0..<10 {
            let a = -Double.pi / 2 + Double(i) * .pi / 5, rad = i % 2 == 0 ? r : r * 0.45
            pts.append((cos(a) * rad, sin(a) * rad))
        }
        return poly(pts, fill, stroke, stroke == nil ? 0 : 3)
    }
    /// The bronze-drum ring motif.
    static func drum(_ r: Double, _ c: SKColor) -> SKNode {
        let n = SKNode()
        n.addChild(circle(0, 0, r, nil, c, 4))
        n.addChild(circle(0, 0, r * 0.62, nil, c, 3))
        n.addChild(star(r * 0.3, c))
        for i in 0..<8 { let a = Double(i) * .pi / 4; n.addChild(circle(cos(a) * r * 0.82, sin(a) * r * 0.82, r * 0.07, c)) }
        return n
    }
}

/// Text in the bundled Nunito, multi-line, centred by default.
enum Font {
    /// The weight-800 named instance of the bundled variable Nunito (the prototype's weight). The
    /// file's first descriptor is ExtraLight (its default axis), so never pick descriptors by order (iOS-R1-02).
    static let name = "Nunito-ExtraBold"

    /// Registers data/fonts/nunito.ttf; its named instances (Nunito-Regular … Nunito-Black) become available.
    static func register(_ url: URL) {
        var err: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err)
    }

    static func heavy(_ size: Double) -> UIFont { UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .heavy) }

    /// Body reading text (intro, scene, ending, quiz prompt, why, dialog) is weight 600: Nunito-SemiBold
    /// (Language & text GDD F1). Buttons, titles, goal and choices stay 800.
    static func body(_ size: Double) -> UIFont { UIFont(name: "Nunito-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold) }

    /// Text with a double outline, ink outside and cream inside, so it reads on every sky band from the
    /// pale village to the navy camp (≥ 3:1 either way; iOS QC r5 N1): two stroked copies under the fill.
    static func outlined(_ s: String, _ size: Double, _ c: SKColor) -> SKNode {
        let n = SKNode()
        for (stroke, w) in [(C.ink, 34.0), (C.cream, 16.0)] {
            let l = label(s, size, .clear)
            let a = NSMutableAttributedString(attributedString: l.attributedText!)
            a.addAttributes([.strokeColor: stroke, .strokeWidth: w], range: NSRange(location: 0, length: a.length))
            l.attributedText = a; n.addChild(l)
        }
        n.addChild(label(s, size, c))
        return n
    }

    static func label(_ s: String, _ size: Double, _ c: SKColor, width: Double? = nil, align: SKLabelHorizontalAlignmentMode = .center, weight: Int = 800) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: name)
        let style = NSMutableParagraphStyle()
        style.alignment = align == .left ? .left : (align == .right ? .right : .center)
        // Language & text GDD F1: the line height is 1.35 × the font size. (lineHeightMultiple multiplied the
        // font's own ≈ 1.36 em line, giving 68 px lines at 37 and the EN banner overflowing its bar, iOS-R5-01.)
        style.minimumLineHeight = 1.35 * size; style.maximumLineHeight = 1.35 * size
        let font = weight == 600 ? body(size) : heavy(size)
        l.attributedText = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: c, .paragraphStyle: style])
        l.numberOfLines = 0
        if let w = width { l.preferredMaxLayoutWidth = w; l.lineBreakMode = .byWordWrapping }
        l.horizontalAlignmentMode = align
        l.verticalAlignmentMode = .center
        return l
    }
}
