import Foundation

/// Where the stuck arrow (ASSET-034) and the telegraph "!" bubble (ASSET-208) go (design/ux/hud.md §3.3, r8; HUD
/// AC17; hints Rule 4; Combat V/A). On a banner beat nothing straddles the motto bar: each sits fully below it,
/// every pixel at y ≥ bar bottom + 8. World px, y down; `cam` is the screen's left edge in world x.
public enum HintPlacement {
    /// The motto bar: top 156, 112 tall (HUD §3.3, W9), so its bottom is 268; hints keep 8 below it.
    public static let barBottom = 156.0 + 112, clearY = barBottom + 8
    /// The arrow's shape (64 tall, 60 wide) and its bounce (12): it bounces above a target only when all of that fits
    /// below the bar, i.e. the target's top is at least 276 + 64 + 12 = 352.
    public static let arrowLength = 64.0, arrowWidth = 60.0, arrowBounce = 12.0
    public static let arrowAboveMinTop = clearY + arrowLength + arrowBounce
    /// The "!" bubble: radius 30 plus its 4 px outline, so a 64 × 64 box; it sits 20 above the helmet when above.
    public static let bangSize = 64.0, bangLift = 20.0
    /// Gap between a target's edge and an arrow or bubble beside it; the screen-edge margin.
    public static let sideGap = 8.0, edge = 8.0

    /// A hint target: the enemy, a dummy or the flag pole.
    public struct Target: Equatable, Sendable {
        public var x, top, halfWidth: Double
        public var bottom: Double
        public init(x: Double, top: Double, halfWidth: Double, bottom: Double = 470) { self.x = x; self.top = top; self.halfWidth = halfWidth; self.bottom = bottom }
        public var midY: Double { (top + bottom) / 2 }
    }

    /// A fighter winding up: helmet top, head centre height and the head's half width.
    public struct Fighter: Equatable, Sendable {
        public var x, top, headY, headHalfWidth: Double
        public init(x: Double, top: Double, headY: Double, headHalfWidth: Double) { self.x = x; self.top = top; self.headY = headY; self.headHalfWidth = headHalfWidth }
    }

    /// The placed hint: centre (x, y), `side` 0 above, +1 right of the target, −1 left; `angle` the rotation from
    /// "pointing down" (+π/2: on the right, pointing left at the target); `rect` its whole box (bounce included).
    public struct Placed: Equatable, Sendable {
        public var x, y, angle: Double
        public var side: Int
        public var rect: Box
    }

    /// The side away from the hero; with no hero beside it, the side nearer the screen centre.
    static func away(_ x: Double, heroX: Double?, cam: Double) -> Int {
        if let h = heroX { return x >= h ? 1 : -1 }
        return x - cam < 640 ? 1 : -1
    }

    /// Picks `side`, or the other side when the box there would come within `edge` of the screen's edge.
    static func fit(_ side: Int, cam: Double, _ box: (Int) -> Box) -> (Int, Box) {
        let b = box(side)
        if b.x >= cam + edge && b.right <= cam + 1280 - edge { return (side, b) }
        return (-side, box(-side))
    }

    /// The stuck arrow over `target` (hints Rule 4, hud §3.3).
    public static func arrow(target t: Target, heroX: Double?, cam: Double, banner: Bool) -> Placed {
        if !banner || t.top >= arrowAboveMinTop {
            // above: the tip 2 px over the target at the lowest point of the bounce
            let bottom = t.top - 2, r = Box(t.x - arrowWidth / 2, bottom - arrowLength - arrowBounce, arrowWidth, arrowLength + arrowBounce)
            return Placed(x: t.x, y: bottom - arrowLength / 2, angle: 0, side: 0, rect: r)
        }
        // rotated 90°, beside the target at its mid-height, pointing at it; the bounce runs sideways
        let (side, r) = fit(away(t.x, heroX: heroX, cam: cam), cam: cam) { s in
            let near = t.x + Double(s) * (t.halfWidth + sideGap), w = arrowLength + arrowBounce
            return Box(s > 0 ? near : near - w, t.midY - arrowWidth / 2, w, arrowWidth)
        }
        let cx = side > 0 ? r.x + arrowLength / 2 : r.right - arrowLength / 2
        return Placed(x: cx, y: t.midY, angle: Double(side) * .pi / 2, side: side, rect: r)
    }

    /// The telegraph "!" (Combat V/A, hud §3.3): above the helmet when it fits there wholly below the bar (or on a
    /// beat without the bar), else beside the head at head height, away from the hero (the hero's side at an edge).
    public static func bang(_ f: Fighter, heroX: Double?, cam: Double, banner: Bool) -> Placed {
        let aboveY = f.top - bangLift - bangSize / 2
        if !banner || aboveY - bangSize / 2 >= clearY {
            return Placed(x: f.x, y: aboveY, angle: 0, side: 0, rect: Box(f.x - bangSize / 2, aboveY - bangSize / 2, bangSize, bangSize))
        }
        let y = max(f.headY, clearY + bangSize / 2)
        let (side, r) = fit(away(f.x, heroX: heroX, cam: cam), cam: cam) { s in
            let near = f.x + Double(s) * (f.headHalfWidth + sideGap)
            return Box(s > 0 ? near : near - bangSize, y - bangSize / 2, bangSize, bangSize)
        }
        return Placed(x: r.midX, y: y, angle: Double(side) * .pi / 2, side: side, rect: r)
    }

    // MARK: the hint hand (Hints Rule 6, r9; AC12)

    /// The hand placed for a pad: `side` 0 above it, −1 left of it, +1 right of it; `pointing` the direction it
    /// points (0 down, +1 right, −1 left); `anchor` where its rotation centre goes; `rect` its whole box, bounce in.
    public struct Hand: Equatable, Sendable {
        public var side, pointing: Int
        public var anchorX, anchorY: Double
        public var rect: Box
    }

    /// The gap between the hand's tip box and its pad.
    public static let handGap = 6.0

    /// The hand's box beside or above a pad (the same art box as Android: 56 × 100 plus the ±12 bounce; its anchor is
    /// 24 inside the gap so the tip box ends `handGap` from the pad).
    public static func handBox(pad c: Circle, side: Int) -> Box {
        let a = handAnchor(pad: c, side: side)
        switch side {
        case 0: return Box(a.x - 30, a.y - 148, 56, 124)
        case -1: return Box(a.x - 148, a.y - 26, 124, 56)
        default: return Box(a.x + 24, a.y - 30, 124, 56)
        }
    }

    static func handAnchor(pad c: Circle, side: Int) -> (x: Double, y: Double) {
        switch side {
        case 0: return (c.cx, c.cy - c.r - handGap + 24)
        case -1: return (c.cx - c.r - handGap + 24, c.cy)
        default: return (c.cx + c.r + handGap - 24, c.cy)
        }
    }

    /// Above the pad when it fits (on a banner beat wholly at y ≥ 276), else beside it on the side away from the
    /// screen edge, else the other side; never over any of `avoid` (the visible pads' squares) and inside x 8…1272.
    public static func hand(pad c: Circle, avoid: [Box], banner: Bool) -> Hand {
        let away = c.cx >= 640 ? -1 : 1
        for side in [0, away, -away] {
            let b = handBox(pad: c, side: side)
            let ok = (!banner || b.y >= clearY) && b.y >= 0 && b.x >= edge && b.right <= 1280 - edge && !avoid.contains { $0.overlaps(b) }
            if ok { let a = handAnchor(pad: c, side: side); return Hand(side: side, pointing: -side, anchorX: a.x, anchorY: a.y, rect: b) }
        }
        let a = handAnchor(pad: c, side: 0)
        return Hand(side: 0, pointing: 0, anchorX: a.x, anchorY: a.y, rect: handBox(pad: c, side: 0))
    }
}
