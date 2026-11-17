// Release build gate (ADR-0001, content/README.md R11 + R12). Run by an Xcode build phase on the
// Release configuration only:
//   xcrun --sdk macosx swift Scripts/ContentGate.swift <content/data> <app's supported schema major>
// Fails the build when a bundled hero cites a claim that isn't approved (or doesn't exist), or when
// any data file's schema_version has a newer MAJOR than the app reads.
import Foundation

let args = CommandLine.arguments
guard args.count >= 3, let appMajor = Int(args[2]) else { print("usage: ContentGate <data dir> <major>"); exit(2) }
let data = URL(fileURLWithPath: args[1])
var errors: [String] = []

func json(_ url: URL) -> Any? { (try? Data(contentsOf: url)).flatMap { try? JSONSerialization.jsonObject(with: $0) } }

// R11: every JSON file under data/
let walker = FileManager.default.enumerator(at: data, includingPropertiesForKeys: nil)
while let url = walker?.nextObject() as? URL {
    guard url.pathExtension == "json", let o = json(url) as? [String: Any], let v = o["schema_version"] as? String else { continue }
    if let major = Int(v.split(separator: ".").first ?? ""), major > appMajor {
        errors.append("\(url.lastPathComponent): schema_version \(v) is newer than this app reads (\(appMajor).x) [R11]")
    }
}

// R12: every claim cited by a bundled hero's text is approved
func claimIds(_ o: Any, into out: inout Set<String>) {
    if let d = o as? [String: Any] {
        for (k, v) in d { if k == "claims", let a = v as? [String] { out.formUnion(a) } else { claimIds(v, into: &out) } }
    } else if let a = o as? [Any] { for v in a { claimIds(v, into: &out) } }
}
let heroes = (json(data.appendingPathComponent("index.json")) as? [String: Any])?["heroes"] as? [String] ?? []
for h in heroes {
    let dir = data.appendingPathComponent("heroes/\(h)")
    let claims = ((json(dir.appendingPathComponent("claims.json")) as? [String: Any])?["claims"] as? [[String: Any]]) ?? []
    let approved = Set(claims.filter { (($0["signoff"] as? [String: Any])?["status"] as? String) == "approved" }.compactMap { $0["id"] as? String })
    var cited = Set<String>()
    for f in ["mission.json", "quiz.json"] { if let o = json(dir.appendingPathComponent(f)) { claimIds(o, into: &cited) } }
    let unsigned = cited.subtracting(approved).sorted()
    if !unsigned.isEmpty { errors.append("hero \(h): claims not signed off: \(unsigned.joined(separator: ", ")) [R12]") }
}

if errors.isEmpty { print("content gate: OK (\(heroes.count) heroes)"); exit(0) }
for e in errors { print("error: \(e)") }
exit(1)
