import Foundation

/// Touch tracking for the thumb pads: one action per touch id, pads fire on touch-down, a thumb
/// sliding between ◀ and ▶ switches direction, and every held action is cleared on cancel,
/// focus loss and pause (no stuck input).
public struct TouchPads: Sendable {
    public private(set) var holds: [Int: PadAction] = [:]
    var taps: Set<PadAction> = []

    public init() {}

    /// Pointers that landed on a pad another pointer already holds: ignored until they lift (TASK-019 b).
    var ignored: Set<Int> = []

    public mutating func down(_ id: Int, _ action: PadAction?) {
        guard let a = action else { return }
        if holds.values.contains(a) { ignored.insert(id); return } // no second hold, no second tap
        holds[id] = a; taps.insert(a)
    }

    /// A move only switches between ◀ and ▶; it never starts or changes attack or defend.
    public mutating func moved(_ id: Int, _ action: PadAction?) {
        guard let cur = holds[id], cur == .left || cur == .right, let a = action, a == .left || a == .right,
              a == cur || !holds.values.contains(a) else { return } // never slide onto a pad another finger holds
        holds[id] = a
    }

    public mutating func up(_ id: Int) { holds[id] = nil; ignored.remove(id) }

    public enum Phase: Sendable { case began, moved, ended }

    /// One touch callback as the platform delivers it, plus the ids of every touch still live in that
    /// event (`event.allTouches` minus ended/cancelled). The map is reconciled against `live` on every
    /// callback, so an end that arrives under a different touch id, or never arrives, can't leave a pad
    /// held (iOS-R2-03 / R3).
    public mutating func apply(_ phase: Phase, id: Int, action: PadAction?, live: Set<Int>) {
        switch phase {
        case .began: down(id, action)
        case .moved: moved(id, action)
        case .ended: up(id)
        }
        reconcile(live: live)
    }

    /// Releases every hold whose touch is no longer live (iOS-R2-03: an end event that never
    /// arrived for a moved touch must not leave a pad held).
    public mutating func reconcile(live: Set<Int>) { holds = holds.filter { live.contains($0.key) }; ignored = ignored.filter { live.contains($0) } }
    public mutating func clearAll() { holds = [:]; taps = []; ignored = [] }

    /// This step's input; taps are consumed.
    public mutating func take(confirm: Bool = false) -> StepInput {
        defer { taps = [] }
        return StepInput(held: Set(holds.values), tapped: taps, confirm: confirm)
    }
}

/// A circle or a rectangle in scene units (the 1280×720 world).
public struct Circle: Equatable, Sendable { public var cx, cy, r: Double
    public func contains(_ x: Double, _ y: Double, slop: Double = 1.15) -> Bool { hypot(x - cx, y - cy) <= r * slop } }

/// Where the pads and HUD buttons go: the prototype's positions, pads at least `pad_min` points
/// across, and everything inside the safe area (Dynamic Island, home indicator).
public struct PadLayout: Equatable, Sendable {
    public var left, right, defend, attack, special, pause, mute: Circle
    public var lang: (x: Double, y: Double, w: Double, h: Double)
    /// Points per scene unit.
    public let scale: Double
    /// The safe rect in scene units (insets plus an 8-unit margin), y down.
    public let safeLeft, safeTop, safeRight, safeBottom: Double
    /// `pad_min` in scene units (the touch size every button keeps).
    public let padWorld: Double

    public static func == (a: PadLayout, b: PadLayout) -> Bool {
        a.left == b.left && a.right == b.right && a.defend == b.defend && a.attack == b.attack && a.special == b.special && a.scale == b.scale
    }

    /// `view` and `insets` (top, left, bottom, right) are in points; the scene is aspect-fit
    /// into the view. Scene y grows downward here (0 = top), like the prototype.
    /// `padGap` (points, tuning `pad_gap`, Input Rule 4): the gap between ◀ ▶ and between pause and sound.
    public init(view: (w: Double, h: Double), insets: (top: Double, left: Double, bottom: Double, right: Double), padMin: Double, padGap: Double = 12) {
        let s = min(view.w / 1280, view.h / 720)
        scale = s
        let ox = (view.w - 1280 * s) / 2, oy = (view.h - 720 * s) / 2
        // the safe rect in scene units, plus an 8-unit gap
        let l = max(0, insets.left - ox) / s + 8, r = 1280 - max(0, insets.right - ox) / s - 8
        let tp = max(0, insets.top - oy) / s + 8, b = 720 - max(0, insets.bottom - oy) / s - 8
        safeLeft = l; safeTop = tp; safeRight = r; safeBottom = b; padWorld = padMin / s
        let gap = padGap / s
        func pad(_ cx: Double, _ cy: Double, _ r0: Double) -> Circle {
            let rr = max(r0, padMin / 2 / s)
            return Circle(cx: min(max(cx, l + rr), r - rr), cy: min(max(cy, tp + rr), b - rr), r: rr)
        }
        left = pad(140, 610, 80); right = pad(330, 610, 80)
        if right.cx - right.r < left.cx + left.r + gap { right.cx = left.cx + left.r + gap + right.r }
        defend = pad(950, 625, 80); attack = pad(1150, 590, 92)
        if defend.cx + defend.r > attack.cx - attack.r - 10 { defend.cx = attack.cx - attack.r - 10 - defend.r }
        // special sits above attack (hold-meter and training only)
        special = pad(attack.cx, attack.cy - attack.r - 14 - max(80, padMin / 2 / s), 80)
        pause = pad(66, 66, 48); mute = pad(176, 66, 48)
        if mute.cx - mute.r < pause.cx + pause.r + gap { mute.cx = pause.cx + pause.r + gap + mute.r }
        // the VI|EN chip (title.md 5.2): height ≥ pad_min, width ≤ 1.6 × height, its left edge kept ≥ 1028 so it
        // clears the hero card (x ≤ 1020) at every supported k
        let lh = max(96, padMin / s), lw = min(1.6 * lh, max(lh, r - 1028))
        lang = (x: r - lw, y: max(18, tp), w: lw, h: lh)
    }

    /// HUD spec §3.3: the top stack (dots, goal plate, banner bar; 920 wide) starts at
    /// max(330, the pause/sound block's right edge + 8), its centre clamped to 790–810.
    public var topStackCentre: Double { min(810, max(790, max(330, mute.cx + mute.r + 8) + 460)) }

    /// The pad under a point (scene units, y down), with the prototype's 15% slop.
    public func action(at x: Double, _ y: Double, visible: Set<PadAction> = Set(PadAction.allCases)) -> PadAction? {
        for (c, a) in [(attack, PadAction.attack), (special, .special), (defend, .defend), (right, .right), (left, .left)] where visible.contains(a) && c.contains(x, y) { return a }
        return nil
    }

    func anyAction(at x: Double, _ y: Double) -> PadAction? {
        for (c, a) in [(attack, PadAction.attack), (special, .special), (defend, .defend), (right, .right), (left, .left)] where c.contains(x, y) { return a }
        return nil
    }
}
