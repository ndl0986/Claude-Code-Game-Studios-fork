// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Writes fixtures/morph-D-dinosaur.json: the inputs (glyph path, silhouette path, spec) and the expected particle
// positions at t = 0, 0.5 and 1 of the morph's duration. A Kotlin port loads the inputs, runs its own MorphCore and
// must match every position within 1e-3 (unit-box units).
//   swift run --package-path MorphCore morph-fixture <fixtures dir>
import Foundation
import MorphCore

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "fixtures")
func json(_ name: String) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent(name))) as! [String: Any]
}
let glyph = try json("glyph-D.json")["d"] as! String
let sil = try json("silhouette-dinosaur.json")["d"] as! String
let spec = try JSONDecoder().decode(MorphSpec.self, from: Data(contentsOf: dir.appendingPathComponent("morph-spec.json")))
let m = try Morph(spec: spec, glyphPath: glyph, silhouettePath: sil)
func pts(_ p: [Pt]) -> [[Double]] { p.map { [$0.x, $0.y] } }
var rng = SplitMix64(seed: spec.seed)
let out: [String: Any] = [
    "about": "TASK-033 shared morph fixture. Recipe: MorphCore/Sources/MorphCore/Morph.swift (doc comment) and SVGPath.swift. Tolerance for ports: 1e-3.",
    "glyphPath": glyph, "silhouettePath": sil,
    "spec": ["count": spec.count, "seed": spec.seed, "glow": spec.glow, "dissolve": spec.dissolve, "travel": spec.travel,
             "spread": spec.spread, "drift": spec.drift, "swirl": spec.swirl, "hold": spec.hold],
    "curveSegments": SVGPath.curveSegments,
    "rngFirst4": (0..<4).map { _ in String(rng.next()) },
    "from": pts(m.from), "to": pts(m.to), "pairing": m.pairing,
    "times": [0.0, 0.5, 1.0].map { $0 * spec.duration },
    "positions": [0.0, 0.5, 1.0].map { pts(m.positions(at: $0 * spec.duration)) },
]
let data = try JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
try data.write(to: dir.appendingPathComponent("morph-D-dinosaur.json"))
print("wrote \(dir.appendingPathComponent("morph-D-dinosaur.json").path) (\(data.count) bytes)")
