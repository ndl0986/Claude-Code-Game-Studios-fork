// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike; TASK-035 fixture generator)
// Writes games/kid-learn-character/content/fixtures/morph-contract-v1.json: the shared cases for "morph contract v1"
// (docs/architecture/morph-contract-v1.md). Regenerate ONLY on a contract version bump.
//   swift run --package-path MorphCore morph-contract-fixture <prototype fixtures dir> <output json>
import Foundation
import MorphCore

let a = CommandLine.arguments
let src = URL(fileURLWithPath: a.count > 1 ? a[1] : "../fixtures"), out = URL(fileURLWithPath: a.count > 2 ? a[2] : "morph-contract-v1.json")
func d(_ name: String) throws -> String {
    (try JSONSerialization.jsonObject(with: Data(contentsOf: src.appendingPathComponent(name))) as! [String: Any])["d"] as! String
}
func pts(_ p: [Pt]) -> [[Double]] { p.map { [$0.x, $0.y] } }

struct Case { let id, note, glyph, silhouette: String; let spec: MorphSpec }
let base = MorphSpec(count: 240, seed: 2026, glow: 0.45, dissolve: 0.35, travel: 1.1, spread: 0.35, drift: 0.06, swirl: 0.35, hold: 3.0)
func with(_ s: MorphSpec, count: Int, seed: UInt64) -> MorphSpec { var x = s; x.count = count; x.seed = seed; return x }

let dino = try d("silhouette-dinosaur.json")
let cases = [
    Case(id: "D-dinosaur", note: "The TASK-033 case: glyph D (Fredoka SemiBold) to the placeholder dinosaur (absolute M L Q Z, two subpaths).",
         glyph: try d("glyph-D.json"), silhouette: dino, spec: base),
    Case(id: "3-relative", note: "A digit glyph to a silhouette written with relative commands, H/V and a cubic C (m h v c l q z).",
         glyph: try d("glyph-3.json"), silhouette: "m100 100 h200 v150 c0 50 -50 100 -100 100 l-100 0 q-50 -50 0 -100 z", spec: with(base, count: 120, seed: 7)),
    Case(id: "count-1", note: "Edge: N = 1 (no shuffle swaps; one sample at the path start).",
         glyph: try d("glyph-D.json"), silhouette: dino, spec: with(base, count: 1, seed: 1)),
    Case(id: "zero-length", note: "Edge: zero-length segments (f = 0) and a lone trailing M (a 1-point subpath, ignored).",
         glyph: "M0 0L0 0L10 0L10 10ZM5 5", silhouette: "M0 0L0 0L0 0L20 0L20 20Z", spec: with(base, count: 16, seed: 3)),
]

var caseOut: [[String: Any]] = []
for c in cases {
    let m = try Morph(spec: c.spec, glyphPath: c.glyph, silhouettePath: c.silhouette)
    let s = c.spec
    let times = [0, s.glow + s.dissolve / 2, 0.5 * s.duration, s.duration]
    var rng = SplitMix64(seed: s.seed)
    caseOut.append([
        "id": c.id, "note": c.note, "glyphPath": c.glyph, "silhouettePath": c.silhouette,
        "spec": ["count": s.count, "seed": String(s.seed), "glow": s.glow, "dissolve": s.dissolve, "travel": s.travel,
                 "spread": s.spread, "drift": s.drift, "swirl": s.swirl],
        "rngFirst4": (0..<4).map { _ in String(rng.next()) },
        "from": pts(m.from), "to": pts(m.to), "pairing": m.pairing,
        "times": times, "positions": times.map { pts(m.positions(at: $0)) },
    ])
}

// Tokenizer cases: the raw (un-normalised) polylines the parser must produce.
let tokenizer = ["M0 0L1e1-5", "M0 0L-.5.5", "M10-5L20-5", "M0,0\n\tL.5.5", "M1e-1 2E+1L3 4"]
let tokOut: [[String: Any]] = try tokenizer.map { ["d": $0, "polylines": try SVGPath.polylines($0).map(pts)] }

let doc: [String: Any] = [
    "contract": "morph-v1",
    "spec": "games/kid-learn-character/docs/architecture/morph-contract-v1.md",
    "tolerance": 1e-3,
    "units": "unit box (longer side 1, centred, y down); times in seconds from the press",
    "uint64AsString": "seed and rngFirst4 are decimal strings (JSON numbers lose precision above 2^53)",
    "generatedBy": "prototypes/TASK-033-anim-runtime/MorphCore: swift run morph-contract-fixture ../fixtures <out> (TASK-035, 2026-11-17)",
    "cases": caseOut,
    "tokenizer": tokOut,
]
try JSONSerialization.data(withJSONObject: doc, options: [.sortedKeys]).write(to: out)
print("wrote \(out.path)")
