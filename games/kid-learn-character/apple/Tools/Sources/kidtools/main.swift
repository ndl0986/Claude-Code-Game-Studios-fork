// kidtools: the build-time command line (ADR-0002 Validation 4, ADR-0003).
//
//   kidtools api-surface <symbol-graph-dir> <module> <out.md>   write a module's public API surface
//   kidtools api-surface --check <symbol-graph-dir> <module> <file.md>   exit 1 if <file.md> is stale
import Foundation

func fail(_ s: String) -> Never { FileHandle.standardError.write(Data((s + "\n").utf8)); exit(2) }

let args = Array(CommandLine.arguments.dropFirst())
guard let cmd = args.first else { fail("usage: kidtools api-surface [--check] <symbol-graph-dir> <module> <file.md>") }

switch cmd {
case "api-surface":
    var rest = Array(args.dropFirst()), check = false
    if rest.first == "--check" { check = true; rest.removeFirst() }
    guard rest.count == 3 else { fail("usage: kidtools api-surface [--check] <symbol-graph-dir> <module> <file.md>") }
    let text: String
    do { text = try APISurface.render(symbolGraphDir: rest[0], module: rest[1]) } catch { fail("api-surface: \(error)") }
    let path = rest[2]
    if check {
        let old = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        if old != text { print("STALE \(path): regenerate with kidtools api-surface"); exit(1) }
        print("OK \(path)")
    } else {
        do { try text.write(toFile: path, atomically: true, encoding: .utf8) } catch { fail("write \(path): \(error)") }
        print("wrote \(path)")
    }
default:
    fail("unknown command \(cmd)")
}
