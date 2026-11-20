/// The play clock (ADR-0002 D3, derived in KidCore; Reveal Stage R8; Press Queue R8a, R9): uptime minus the total time
/// spent frozen (the Parent Gate challenge) or in the background. While paused it stands still, so the paused time
/// never counts and nothing sees a gap. The Reveal Stage pauses and resumes it; every system that times play reads it.
///
/// Example:
/// ```swift
/// let play = PlayClock(uptime: appUptime)
/// play.pause(.freeze, at: 11.0); play.resume(.freeze, at: 31.0)
/// play.play(32.5)   // 12.5
/// ```
public final class PlayClock: UptimeClock {
    /// Why the clock is paused. Both may overlap (a background during a challenge); it runs again when neither holds.
    public enum Pause: Hashable, Sendable {
        case freeze
        case background
    }

    private let uptime: UptimeClock
    private var pausedTotal = 0.0
    private var pausedSince: Double?
    /// The uptime of the last resume: an older stamp is clamped to the play time at that resume.
    private var lastResume: Double?
    private var reasons: Set<Pause> = []

    /// A play clock that starts equal to `uptime`.
    public init(uptime: UptimeClock) { self.uptime = uptime }

    /// The play time now.
    public func now() -> Double { play(uptime.now()) }

    /// The play time of an uptime stamp (a press's `time`, Input R8, or a frame's target time). While paused, a stamp
    /// at or after the pause maps to the paused play time. A stamp from before the last resume is clamped to the play
    /// time at that resume, so play time never steps back (no press arrives during a freeze, Input R6, and a
    /// background clears the queue, R9, so this is a guard, not a path the queue relies on).
    public func play(_ u: Double) -> Double {
        if let since = pausedSince { return min(u, since) - pausedTotal }
        if let r = lastResume, u < r { return r - pausedTotal }
        return u - pausedTotal
    }

    /// True while any pause reason holds.
    public var isPaused: Bool { !reasons.isEmpty }

    /// Starts a pause for `reason` at uptime `u`; a reason already holding changes nothing.
    public func pause(_ reason: Pause, at u: Double) {
        if reasons.isEmpty { pausedSince = u }
        reasons.insert(reason)
    }

    /// Ends the pause for `reason` at uptime `u`; the clock runs again when no reason is left.
    public func resume(_ reason: Pause, at u: Double) {
        guard reasons.remove(reason) != nil, reasons.isEmpty, let since = pausedSince else { return }
        pausedTotal += max(0, u - since)
        pausedSince = nil
        lastResume = u
    }
}
