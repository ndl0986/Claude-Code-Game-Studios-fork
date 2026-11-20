// Press Queue: accept, queue or ignore a press, and start the next reveal (design/gdd/press-queue.md R2-R7, F1, F2).
// Story press-queue/001 implements the start-at-once, queue, formed-guard and ignore rules (AC-1..AC-4). Rest,
// jumping and mash, the formed timeout (R5.1), ids and sources, the panel and the background, and the hint on
// overflow are later stories of the epic and extend this type. Pure KidCore logic: no clock of its own beyond the
// injected `UptimeClock`, no platform types, and no tuning value in code (ADR-0001 D6, ADR-0002 D3).

/// The press queue's tuning knobs (GDD Tuning Knobs, R13). Bundled data in the app; KidCore holds no defaults.
public struct PressQueueKnobs: Equatable, Sendable {
    /// `hold_s`: the base hold while keys wait, in seconds.
    public var holdS: Double
    /// `queue_max`: the most presses that may wait.
    public var queueMax: Int
    /// `formed_timeout_s`: how long past `revealLen` a reveal may stay unformed (R5.1, a later story).
    public var formedTimeoutS: Double
    /// `word_offset_s`: the gap between the cast sound and the word (Audio & Voice).
    public var wordOffsetS: Double
    /// `hold_ext_max_s`: the longest a word may extend the hold (Audio & Voice).
    public var holdExtMaxS: Double
    /// `word_len_max_s`: the longest word line, and the bound when a `voiceDurations` entry is missing (K-53).
    public var wordLenMaxS: Double
    /// The knobs from their values; there are no defaults here.
    public init(holdS: Double, queueMax: Int, formedTimeoutS: Double, wordOffsetS: Double, holdExtMaxS: Double,
                wordLenMaxS: Double) {
        self.holdS = holdS; self.queueMax = queueMax; self.formedTimeoutS = formedTimeoutS
        self.wordOffsetS = wordOffsetS; self.holdExtMaxS = holdExtMaxS; self.wordLenMaxS = wordLenMaxS
    }
}

/// Where a press came from (R12). Every source follows the same rules; only `origin` differs.
public enum PressSource: Equatable, Sendable {
    case hardwareKey
    /// A touched hint letter, by its id.
    case hint(String)
    case keyboardRow
}

/// A point on the stage where a press happened (R12); nil for a hardware key.
public struct PressOrigin: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// Input & Key Filter's R8 event as the queue sees it.
public struct Press: Equatable, Sendable {
    /// The key, as KidCore's key string.
    public var key: String
    public var source: PressSource
    /// The event's uptime stamp, in seconds (converted to play time on arrival once freeze lands, R8a).
    public var time: Double
    public var origin: PressOrigin?
    public init(key: String, source: PressSource, time: Double, origin: PressOrigin? = nil) {
        self.key = key; self.source = source; self.time = time; self.origin = origin
    }
}

/// The outcome of a press, returned at once (R4).
public enum PressOutcome: Equatable, Sendable {
    /// The reveal started now: its id, its start time and the item's cast id (Key Table, R6).
    case started(revealId: Int, r0: Double, castId: String)
    /// Queued at this 0-based place.
    case queued(index: Int)
    /// The queue was full.
    case ignored
}

/// What the Reveal Stage and Key Table answer when a reveal starts (R6; F1's inputs).
public struct RevealStart: Equatable, Sendable {
    /// When `formed` is reported, seconds after `r0`.
    public var formedS: Double
    /// The visible reveal length.
    public var revealLen: Double
    /// False when no word will play.
    public var hasWord: Bool
    /// The word line's duration from `voiceDurations`; nil when the entry is missing.
    public var wordLen: Double?
    /// The item's cast id (Key Table).
    public var castId: String
    public init(formedS: Double, revealLen: Double, hasWord: Bool, wordLen: Double?, castId: String) {
        self.formedS = formedS; self.revealLen = revealLen; self.hasWord = hasWord; self.wordLen = wordLen
        self.castId = castId
    }
}

/// The Reveal Stage and Key Table as the queue calls them (R6): starts a reveal and answers with its lengths.
public protocol PressQueueStage {
    /// Starts the reveal `revealId` for `key` at `r0`; the stage reports `formed(revealId:)` later. The stage reads
    /// Reduce Motion itself at this start (Reveal Stage R9) and answers that timing set's lengths (F5).
    func startReveal(revealId: Int, key: String, source: PressSource, origin: PressOrigin?, r0: Double) -> RevealStart
}

/// The reveal on stage (R2). `holdEff` is locked at start.
public struct CurrentReveal: Equatable, Sendable {
    public var revealId: Int
    public var key: String
    public var source: PressSource
    public var origin: PressOrigin?
    /// The start time.
    public var r0: Double
    public var formedS: Double
    public var revealLen: Double
    /// F1, fixed when the reveal started.
    public var holdEff: Double
    public var formed: Bool
    /// When it formed; nil until then.
    public var formedAt: Double?
    /// Settled by a panel open or a background (R8, R9): its hold counts as passed.
    public var settled: Bool
}

/// The press queue (GDD R2-R7). Call `press(_:)` from Input's callback and `tick(now:)` once per frame.
public struct PressQueue {
    /// The reveal on stage, or nil before the first press (R2).
    public private(set) var current: CurrentReveal?
    /// The waiting presses, front first; a queued press has no revealId yet (R2).
    public private(set) var queue: [Press] = []
    /// The revealId the next started reveal takes; counts from 1 with no gaps (R2).
    public private(set) var nextRevealId = 1

    /// R10: the formed time of `current` while the queue is empty and `current` is formed; nil otherwise. The Parade
    /// reads it.
    public var restingSince: Double? {
        guard let c = current, c.formed, queue.isEmpty else { return nil }
        return c.formedAt
    }

    private let knobs: PressQueueKnobs
    private let stage: PressQueueStage
    private let clock: PlayClock
    private let log: DebugLog
    /// True during the Parent Gate challenge (R8a): no tick advances the queue and nothing is cleared.
    public private(set) var frozen = false

    /// A queue with no reveal on stage. Every time it keeps is play time (R8a): `clock` stamps `formed(revealId:)`
    /// arrivals (R7) and settles, and turns a press's uptime stamp into play time on arrival. `log` takes the debug
    /// lines for a missing `voiceDurations` entry (F1) and a formed timeout (R5). F5 (Reduce Motion locked at a
    /// reveal's start) holds because `holdEff` is computed once, from the lengths the stage answers at that start.
    public init(knobs: PressQueueKnobs, stage: PressQueueStage, clock: PlayClock, log: DebugLog) {
        self.knobs = knobs; self.stage = stage; self.clock = clock; self.log = log
    }

    /// F1: the hold of a reveal, from the Reveal Stage's answer. A missing word length uses
    /// `formedS + word_offset_s + word_len_max_s`; `hasWord` false drops the word term.
    static func holdEff(_ r: RevealStart, knobs k: PressQueueKnobs) -> Double {
        var hold = max(k.holdS, r.revealLen)
        if r.hasWord {
            let wordEnd = r.formedS + k.wordOffsetS + (r.wordLen ?? k.wordLenMaxS)
            hold = max(hold, min(wordEnd, k.holdS + k.holdExtMaxS))
        }
        return hold
    }

    /// R3 / F2: accepts, queues or ignores a press, and returns the outcome at once (R4).
    public mutating func press(_ p: Press) -> PressOutcome {
        let t = clock.play(p.time)
        if startsAtOnce(at: t) {
            let started = start(p, r0: t)
            return .started(revealId: started.revealId, r0: t, castId: started.castId)
        }
        if queue.count < knobs.queueMax {
            queue.append(p)
            return .queued(index: queue.count - 1)
        }
        return .ignored
    }

    /// R5: once per frame, before drawing. 1. The formed timeout: a reveal not formed by `r0 + revealLen +
    /// formed_timeout_s` (inclusive) is marked formed at `now`, with one debug line; a later `formed` is ignored (R7).
    /// 2. Starts the front press when the reveal is formed and its hold has passed (inclusive); at most one per tick.
    /// `now` is the frame's play time. A frozen queue ignores the tick (R8a).
    public mutating func tick(now: Double) {
        if frozen { return }
        if var c = current, !c.formed, now >= c.r0 + c.revealLen + knobs.formedTimeoutS {
            c.formed = true
            c.formedAt = now
            current = c
            log.log("press-queue: reveal \(c.revealId) (\(c.key)) formed timeout at \(now)")
        }
        guard let c = current, c.formed, !queue.isEmpty, now >= c.r0 + c.holdEff else { return }
        _ = start(queue.removeFirst(), r0: now)
    }

    /// R7: the Reveal Stage reports `formed`. A report for a reveal that is not on stage, or a second one, is
    /// ignored.
    public mutating func formed(revealId: Int) {
        guard var c = current, c.revealId == revealId, !c.formed else { return }
        c.formed = true
        c.formedAt = clock.now()
        current = c
    }

    /// R8a: the Parent Gate challenge shows. The queue stops where it is; the Reveal Stage pauses the play clock.
    public mutating func freeze() { frozen = true }

    /// R8a: a wrong answer or a timeout. The queue resumes exactly where it stopped.
    public mutating func resume() { frozen = false }

    /// R8 (the panel opens, which also ends a challenge's freeze) and R9 (background): the queue is cleared with no
    /// outcome for the dropped presses, and the current reveal settles to formed with its hold passed. A reveal not yet
    /// formed takes `formedAt` = the play time of the settle; one already formed keeps its own.
    public mutating func settle() {
        frozen = false
        queue.removeAll()
        guard var c = current else { return }
        if !c.formed { c.formed = true; c.formedAt = clock.now() }
        c.settled = true
        current = c
    }

    /// F2: nothing on stage, or an empty queue and a formed reveal whose hold has passed at `t` (or was settled).
    private func startsAtOnce(at t: Double) -> Bool {
        guard let c = current else { return true }
        return queue.isEmpty && c.formed && (c.settled || t >= c.r0 + c.holdEff)
    }

    /// R6: calls the Reveal Stage, locks `holdEff`, takes the next revealId.
    private mutating func start(_ p: Press, r0: Double) -> (revealId: Int, castId: String) {
        let id = nextRevealId
        let answer = stage.startReveal(revealId: id, key: p.key, source: p.source, origin: p.origin, r0: r0)
        if answer.hasWord && answer.wordLen == nil {
            log.log("press-queue: reveal \(id) (\(p.key)) has no voiceDurations entry; word end bound formedS + word_offset_s + word_len_max_s")
        }
        current = CurrentReveal(revealId: id, key: p.key, source: p.source, origin: p.origin, r0: r0,
                                formedS: answer.formedS, revealLen: answer.revealLen,
                                holdEff: Self.holdEff(answer, knobs: knobs), formed: false, formedAt: nil, settled: false)
        nextRevealId = id + 1
        return (id, answer.castId)
    }
}
