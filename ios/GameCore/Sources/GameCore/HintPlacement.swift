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
}
