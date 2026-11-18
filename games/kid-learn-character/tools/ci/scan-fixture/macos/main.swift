// API-scan proof fixture (ADR-0011 Validation 7): references every PKC-named API reachable on macOS so pkc-scan.sh
// can be proven to list each one. Built, never run. Not part of the app.
import AppKit
import AVFoundation
import BackgroundAssets
import CloudKit
import CoreSpotlight
import Darwin
import Foundation
import Intents
import Network
import Speech
import StoreKit
import WebKit
import AdSupport

@inline(never) func keep(_ x: Any) { if CommandLine.arguments.count > 99 { print(x) } }

@MainActor func fixture() async throws {
    keep(URLSession.shared)
    keep(NSURLConnection.self)
    keep(NWConnection(host: "x", port: 1, using: .tcp))
    keep(nw_connection_create(nw_endpoint_create_host("x", "1"), nw_parameters_create()))
    var r: Unmanaged<CFReadStream>?; var w: Unmanaged<CFWriteStream>?
    CFStreamCreatePairWithSocketToHost(nil, "x" as CFString, 1, &r, &w)
    keep(WKWebView())
    keep(CKContainer.default())
    keep(NSUbiquitousKeyValueStore.default)
    keep(FileManager.default.url(forUbiquityContainerIdentifier: nil) as Any)
    keep(UserDefaults(suiteName: "x") as Any)
    keep(NSSharingService(named: .composeEmail) as Any)
    NSWorkspace.shared.open(URL(fileURLWithPath: "/"))
    keep(ASIdentifierManager.shared().advertisingIdentifier)
    keep(AVCaptureDevice.default(for: .video) as Any)
    keep(AVCaptureSession())
    keep(try AVAudioRecorder(url: URL(fileURLWithPath: "/tmp/x"), settings: [:]))
    keep(SFSpeechRecognizer() as Any)
    let v = try URL(fileURLWithPath: "/").resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey, .volumeAvailableCapacityForImportantUsageKey])
    keep(v.creationDate as Any); keep(v.contentModificationDate as Any); keep(v.volumeAvailableCapacityForImportantUsage as Any)
    keep(try FileManager.default.attributesOfItem(atPath: "/")[.modificationDate] as Any)
    var st = Darwin.stat(); keep(stat("/", &st)); keep(fstat(0, &st)); keep(lstat("/", &st))
    var sf = statfs(); keep(statfs("/", &sf))
    var al = attrlist(); keep(getattrlist("/", &al, nil, 0, 0))
    keep(ProcessInfo.processInfo.systemUptime)
    keep(mach_absolute_time())
    keep(BADownloadManager.shared)
    let a = NSUserActivity(activityType: "x"); a.isEligibleForHandoff = true; a.isEligibleForSearch = true; keep(a)
    keep(CSSearchableItem())
    keep(INInteraction(intent: INIntent(), response: nil))
    if let scene = NSApplication.shared.windows.first?.contentViewController { await AppStore.requestReview(in: scene) }
}
@main struct Fixture { static func main() async throws { if CommandLine.arguments.count > 99 { try await fixture() } } }
