// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike, ADR-0009 with ADR-0006 D1–D7)
// The SKView is wrapped directly (not SpriteView), sets accessibilityIgnoresInvertColors on iPad (ADR-0006 D5,
// P-13), and reads DisplayMetrics and ppi (D2, D7; P-11, M-10). The SKView's own loop drives the scene here; the
// production frame driver (display link → tick(now:), D3) is the stage story's, the spike measures drawing cost.
import SwiftUI
import Combine
import SpriteKit
import SpikeKit
#if os(iOS)
import UIKit
#else
import AppKit
import CoreGraphics
#endif

@MainActor
final class RenderModel: ObservableObject {
    let scene = RenderScene(size: CGSize(width: 1194, height: 834))
    weak var view: SKView?
    @Published var option: RenderOption = .a { didSet { scene.option = option } }
    @Published var fps120 = false { didSet { view?.preferredFramesPerSecond = fps120 ? 120 : 60 } }
    @Published var readout = ""
    init() {
        scene.onLog = { s in SpikeLog.shared.line("[render] \(s)") }
        // `-option a|candidate|b`: open Render on that option (headless smoke runs, and the TASK-127 crispness still
        // taken with `devicectl device capture screenshot`, which cannot tap)
        let arg: [String: RenderOption] = ["a": .a, "candidate": .aCandidate, "b": .b]
        if let o = UserDefaults.standard.string(forKey: "option").flatMap({ arg[$0] }) { option = o; scene.option = o }
    }

    func refresh() {
        let f = scene.fit
        let (ppi, src) = Self.ppi()
        var reduce = false
        #if os(iOS)
        reduce = UIAccessibility.isReduceMotionEnabled
        let invert = view?.accessibilityIgnoresInvertColors ?? false
        #else
        reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let invert = false
        #endif
        readout = String(format: "p50 %.2f ms  p99 %.2f ms  (n=%d)  |  s_fit %.4f  visible %.0f,%.0f %.0f×%.0f  pxPerPt %.1f  ppi %.0f (%@)  |  reduceMotion %@  ignoresInvert %@",
                         scene.stats.percentile(0.5), scene.stats.percentile(0.99), scene.stats.deltas.count, f.scale, f.visibleX, f.visibleY, f.visibleW, f.visibleH,
                         Double(scene.pxPerPt), ppi, "\(src)", "\(reduce)", "\(invert)")
    }
    func logStats() { refresh(); SpikeLog.shared.line("[render] option=\(option.rawValue) outline=\(scene.outlineVariant.rawValue) fps120=\(fps120) \(readout)") }
    func overlapCheck() { scene.overlapCheck() }

    static func ppi() -> (Double, PPI.Source) {
        #if os(iOS)
        var model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        if model.isEmpty { var u = utsname(); uname(&u); model = withUnsafeBytes(of: &u.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) } }
        return PPI.iPad(model: model)
        #else
        let d = CGMainDisplayID()
        return PPI.mac(pixelsW: Double(CGDisplayPixelsWide(d)), mmW: Double(CGDisplayScreenSize(d).width))
        #endif
    }
}

struct RenderScreen: View {
    @StateObject private var model = RenderModel()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Picker("Option", selection: $model.option) { ForEach(RenderOption.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).frame(maxWidth: 420)
                Toggle("120 Hz", isOn: $model.fps120).fixedSize()
                Button("Log stats") { model.logStats() }
                Button("Overlap check") { model.overlapCheck() }
                Button("Reset stats") { model.scene.stats.reset() }
                Button("Dump 120 frames") { model.scene.dumpIndex = 0; model.scene.dumpRemaining = 120 }
            }.buttonStyle(.bordered)
            Text(model.readout).font(.caption.monospaced()).lineLimit(2)
            StageView(model: model)
        }
        .padding(6)
        .onReceive(timer) { _ in model.refresh() }
    }
}

#if os(iOS)
struct StageView: UIViewRepresentable {
    let model: RenderModel
    func makeUIView(context: Context) -> SKView {
        let v = SKView(); v.preferredFramesPerSecond = 60; v.ignoresSiblingOrder = true
        v.accessibilityIgnoresInvertColors = true                               // ADR-0006 D5, K-30
        model.view = v; model.scene.pxPerPt = v.window?.windowScene?.screen.nativeScale ?? v.traitCollection.displayScale
        v.presentScene(model.scene); return v
    }
    func updateUIView(_ v: SKView, context: Context) { model.scene.pxPerPt = v.window?.windowScene?.screen.nativeScale ?? v.traitCollection.displayScale; model.scene.layout() }
}
#else
struct StageView: NSViewRepresentable {
    let model: RenderModel
    func makeNSView(context: Context) -> SKView {
        let v = SKView(); v.preferredFramesPerSecond = 60; v.ignoresSiblingOrder = true
        model.view = v; model.scene.pxPerPt = NSScreen.main?.backingScaleFactor ?? 2
        v.presentScene(model.scene); return v
    }
    func updateNSView(_ v: SKView, context: Context) { model.scene.pxPerPt = v.window?.backingScaleFactor ?? 2; model.scene.layout() }
}
#endif
