// API-scan proof fixture, iOS (ADR-0011 Validation 7): references the PKC-named APIs that exist only on iOS, plus the
// shared ones, built for generic/platform=iOS as a dynamic library. Built, never run. Not part of the app.
#if os(iOS)
import AdSupport
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
import UIKit
import WebKit

@inline(never) func keep(_ x: Any) { if ProcessInfo.processInfo.arguments.count > 99 { print(x) } }

@MainActor public func pkcFixture() async throws {
    _ = await UIApplication.shared.open(URL(fileURLWithPath: "/"))
    keep(SKStoreReviewController.self)
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene { AppStore.requestReview(in: scene) }
    keep(UIActivityViewController(activityItems: [], applicationActivities: nil))
    keep(UIDevice.current.identifierForVendor as Any)
    keep(UITextInputMode.activeInputModes)
    keep(NSBundleResourceRequest(tags: ["x"]))
    keep(ASIdentifierManager.shared().advertisingIdentifier)
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
}
#endif
