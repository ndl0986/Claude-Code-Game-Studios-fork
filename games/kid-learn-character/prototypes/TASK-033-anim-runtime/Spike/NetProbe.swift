// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Play-time network probe: a URLProtocol registered for the whole process sees every request made through the URL
// loading system (URLSession.shared / NSURLSession sharedSession, which Rive's CDN loader uses). It records the URL
// and lets the request continue, so the sandbox (no network.client entitlement) is what stops it. Lines go to
// stderr with the prefix "[net]" and to Documents/<label>-net.txt.
import Foundation

#if NORIVE
// TASK-078: the no-Rive build (P-1 baseline) has nothing that loads URLs, so the probe is a no-op and the binary
// carries no URL-loading code at all.
enum NetProbe { static func install() {}; static func dump(label: String) {} }
#else
final class NetProbe: URLProtocol {
    nonisolated(unsafe) static var seen: [String] = []
    static func install() { URLProtocol.registerClass(NetProbe.self) }

    override class func canInit(with request: URLRequest) -> Bool {
        let line = "[net] request \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "?")"
        seen.append(line)
        FileHandle.standardError.write((line + "\n").data(using: .utf8)!)
        return false // observe only: the request goes on to the real loader (and the sandbox)
    }

    static func dump(label: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let text = seen.isEmpty ? "[net] no requests seen\n" : seen.joined(separator: "\n") + "\n"
        try? text.write(to: docs.appendingPathComponent("\(label)-net.txt"), atomically: true, encoding: .utf8)
    }
}
#endif
