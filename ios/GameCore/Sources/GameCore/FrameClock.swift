/// The app's fixed-step frame clock: turns display-frame times into whole 1/60 s simulation steps (iOS r10, N1).
///
/// The same rules as Android's `core/FrameClock.kt` (r13):
/// - `dt` is clamped to [0, `maxDt`]; it is 0 on the first frame, when there is no earlier frame time.
/// - The debug slow-motion `scale` multiplies `dt` before it reaches the accumulator (1 in Release).
/// - The remainder of a frame below one step carries into the next frame.
/// - On the frame where the game leaves the pause screen, `dt` and the carried remainder are both dropped, so the
///   simulation counts only time after that frame. Before r10 the first frame after a resume credited time from
///   before the press (≤ 33 ms), and the banner moment's 0.833 s after a resume measured 0.800–0.812 s.
public struct FrameClock: Sendable {
    /// Length of one simulation step, seconds.
    public let step: Double
    /// The longest frame credited, seconds: a stall never runs more than this much simulation at once.
    public let maxDt: Double
    /// The previous frame's time, or nil before the first frame.
    public private(set) var last: Double?
    /// Simulation time owed but not yet stepped, seconds, in (−1 ns, `step`) after `frame`.
    public private(set) var acc = 0.0
    /// The (scaled) time credited this frame, seconds; 0 on the first frame and on a resume frame.
    public private(set) var dt = 0.0
    /// Rounding slack on the step comparison, seconds.
    static let slack = 1e-9

    /// - Parameters:
    ///   - step: simulation step length, seconds.
    ///   - maxDt: clamp on one frame's credited time, seconds.
    public init(step: Double = 1.0 / 60, maxDt: Double = 0.25) {
        self.step = step; self.maxDt = maxDt
    }

    /// Advances the clock to the frame at `now` and returns how many simulation steps to run this frame.
    /// - Parameters:
    ///   - now: this frame's time, seconds (SpriteKit's `currentTime`).
    ///   - leftPause: true on the frame where the game left the pause screen (resume, or Home from pause).
    ///   - scale: debug slow-motion factor applied to `dt`; 1 in play.
    public mutating func frame(_ now: Double, leftPause: Bool = false, scale: Double = 1) -> Int {
        let raw = last.map { min(max(now - $0, 0), maxDt) } ?? 0
        last = now
        if leftPause { dt = 0; acc = 0; return 0 }
        dt = raw * scale
        acc += dt
        var n = 0
        // 1 ns of slack: frame times differ from a whole step by rounding (k/60 − (k−1)/60 ≠ 1/60 in binary),
        // which would otherwise make an exact 60 Hz display alternate 0 and 2 steps a frame
        while acc >= step - Self.slack { acc -= step; n += 1 }
        return n
    }

    /// Forgets the previous frame time and the remainder: the next frame credits 0 (the scene starting again).
    public mutating func restart() { last = nil; acc = 0; dt = 0 }
}
