/// Rule R12: what a build and a running app do with pending claims (content/fixtures/claim-gate.json).
public enum ClaimGate {
    public enum Build: String, Sendable { case pass, fail }
    public enum Runtime: String, Sendable { case show, hideAndLog = "hide_and_log" }

    public struct Result: Equatable, Sendable {
        public let releaseBuild: Build
        public let runtimeRelease: Runtime
        /// Claim ids a debug build badges as `UNSIGNED Cxx`, sorted.
        public let debugBadges: [String]
    }

    /// `claims`: claim id → approved?; `textClaims`: the claim list of every Text shown.
    /// An unknown claim id counts as unsigned.
    public static func evaluate(claims: [String: Bool], textClaims: [[String]]) -> Result {
        let unsigned = Set(textClaims.joined().filter { claims[$0] != true }).sorted()
        return Result(releaseBuild: unsigned.isEmpty ? .pass : .fail,
                      runtimeRelease: unsigned.isEmpty ? .show : .hideAndLog,
                      debugBadges: unsigned)
    }

    /// The gate for one hero's content.
    public static func evaluate(_ hero: HeroContent) -> Result {
        let approved = Dictionary(hero.claims.claims.map { ($0.id, $0.signoff.status == .approved) }, uniquingKeysWith: { a, _ in a })
        let texts = hero.mission.allTexts + hero.quiz.allTexts
        return evaluate(claims: approved, textClaims: texts.map(\.claims))
    }

    /// The pending claim ids of one Text (for its debug badge).
    public static func unsigned(_ text: Text, in hero: HeroContent) -> [String] {
        text.claims.filter { id in hero.claims.claims.first { $0.id == id }?.signoff.status != .approved }
    }
}
