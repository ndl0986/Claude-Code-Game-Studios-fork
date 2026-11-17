/// The star rule (rules.json `quiz_stars`): retries are wrong picks before the right one,
/// summed across the whole quiz; the first threshold whose max_retries covers the total wins.
public struct StarRule: Sendable {
    public let thresholds: [RulesFile.StarThreshold]

    public init(_ rules: RulesFile.QuizStars) { thresholds = rules.thresholds }

    /// Stars for a quiz finished with `totalRetries` wrong picks.
    public func stars(totalRetries: Int) -> Int {
        for t in thresholds where t.maxRetries.map({ totalRetries <= $0 }) ?? true { return t.stars }
        return 1
    }
}

/// One quiz run (Quiz & stars GDD, P-05): retry until right; a wrong card greys and shakes for
/// 0.5 s, and taps are ignored while it shakes; a repeat tap on a greyed card is ignored, not
/// counted (D-11a); after the right card the `why` line shows and "Tiếp / Next" advances.
public struct QuizSession: Sendable {
    public enum Pick: String, Sendable { case right, wrong, ignored }

    public let questions: [QuizFile.Question]
    public let seed: Int
    public private(set) var index = 0
    /// Display slot k shows original choice `order[k]` (P-05 shuffle).
    public private(set) var order: [Int] = []
    /// Wrong cards picked on the current question (original indices, greyed).
    public private(set) var wrong: Set<Int> = []
    /// The right card (original index) once picked; the `why` line shows until Next.
    public private(set) var okIndex: Int?
    public private(set) var okTime = 0.0
    public private(set) var retries = 0
    /// The wrong card shaking (original index), and how long it has left.
    public private(set) var shakeIndex: Int?
    public private(set) var shakeTime = 0.0
    public static let shakeDuration = 0.5

    /// The first `count` questions in file order, `count` clamped to 3–5 and to the questions available.
    public init(quiz: QuizFile, count: Int, seed: Int) {
        let n = max(3, min(5, count, quiz.questions.count))
        questions = Array(quiz.questions.prefix(n))
        self.seed = seed
        order = Self.shuffle(n: questions.first?.choices.count ?? 3, seed: seed, questionIndex: 0)
    }

    /// P-05: Mulberry32(seed + question_index), Fisher–Yates from the last index down.
    public static func shuffle(n: Int, seed: Int, questionIndex: Int) -> [Int] {
        var rng = Mulberry32(seed: seed + questionIndex)
        var o = Array(0..<n)
        var i = n - 1
        while i >= 1 {
            let j = Int((rng.next() * Double(i + 1)).rounded(.down))
            o.swapAt(i, j); i -= 1
        }
        return o
    }

    public var current: QuizFile.Question { questions[min(index, questions.count - 1)] }
    public var isFinished: Bool { index >= questions.count }

    /// The child taps the card in display slot `slot`.
    @discardableResult
    public mutating func pick(slot: Int) -> Pick {
        guard slot >= 0, slot < order.count else { return .ignored }
        return pick(original: order[slot])
    }

    /// The child taps original choice `j` (fixtures use original indices).
    @discardableResult
    public mutating func pick(original j: Int) -> Pick {
        guard !isFinished, okIndex == nil, shakeTime <= 0, !wrong.contains(j), j >= 0, j < current.choices.count else { return .ignored }
        if j == current.correctIndex { okIndex = j; okTime = 0; return .right }
        wrong.insert(j); retries += 1; shakeIndex = j; shakeTime = Self.shakeDuration
        return .wrong
    }

    /// "Tiếp / Next" after the `why` line. Returns true when the quiz has just finished.
    @discardableResult
    public mutating func advance() -> Bool {
        guard okIndex != nil else { return false }
        index += 1; okIndex = nil; wrong = []; shakeIndex = nil; shakeTime = 0
        if !isFinished { order = Self.shuffle(n: current.choices.count, seed: seed, questionIndex: index) }
        return isFinished
    }

    /// Advances the shake and feedback animation timers.
    public mutating func update(_ dt: Double) {
        shakeTime = max(0, shakeTime - dt)
        if okIndex != nil { okTime += dt }
    }

    /// Debug screen jump: show question `q` (0-based).
    public mutating func jump(to q: Int) {
        index = max(0, min(q, questions.count - 1))
        order = Self.shuffle(n: current.choices.count, seed: seed, questionIndex: index)
    }
}
