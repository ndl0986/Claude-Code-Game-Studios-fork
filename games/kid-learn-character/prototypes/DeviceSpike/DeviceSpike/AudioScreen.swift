// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike; P-1, P-7, P-8, P-9, M-14)
// The pad: a press (touch or any key) lights a small dot on the pad on the next frame and plays the chime, for the
// TASK-033 240 fps camera procedure. Never a full-pad flash (TASK-118, ADR-0013 D7): mashing a full-width pad white
// flashed a large area more than 3 times a second. The dot (36 pt) stays under the smallest flash field ADR-0013 allows
// (4,347 px at the 72 ppi floor): about 1,018 px at 1x and 4,072 px at 2x. Not with the child watching (README). Buttons play and cut each bus for the click checks.
import SwiftUI
import QuartzCore

struct AudioScreen: View {
    @State private var audio: AudioSpike? = nil
    @State private var pressed = false
    @State private var muted = false
    @State private var tone1k = false     // TASK-128: the Tone buttons' test tone, 100 Hz (default) or 1 kHz (audible on the iPad speaker)
    @State private var lastHandOff = ""
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(red: 0.12, green: 0.15, blue: 0.30))     // constant: the pad never flashes
                Text("Press here or any key").foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
                Circle().fill(pressed ? Color(white: 0.85) : Color.clear)          // the press marker the camera sees
                    .overlay(Circle().stroke(Color(white: 0.5), lineWidth: 1))
                    .frame(width: 36, height: 36).padding(12)
            }
            .frame(maxWidth: .infinity, minHeight: 240)
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in if !pressed { press(source: "touch") } }.onEnded { _ in pressed = false })
            .focusable().onKeyPress(phases: .down) { _ in press(source: "key"); return .handled }
            .onKeyPress(phases: .up) { _ in pressed = false; return .handled }
            Text(lastHandOff).font(.caption.monospaced())
            HStack {
                ForEach(AudioSpike.Bus.allCases, id: \.self) { b in
                    VStack {
                        Button("Play \(b.rawValue)") { audio?.play(b == .ui ? "chime" : b.rawValue, on: b) }
                        Button("Cut \(b.rawValue)") { audio?.cut(b) }
                    }.buttonStyle(.bordered)
                }
            }
            HStack {
                Button("Scripted reveal") { scripted() }
                Toggle("Mute", isOn: $muted).onChange(of: muted) { _, m in audio?.setMuted(m) }.fixedSize()
                Button("Freeze") { audio?.freeze() }; Button("Resume") { audio?.resume() }
            }
            // ADR-0010 row helpers: P-7 / M-14 tone tests (detector on the live output), P-8 simulated reset
            Toggle("Tone 1 kHz (off: 100 Hz)", isOn: $tone1k).onChange(of: tone1k) { _, on in audio?.toneHz = on ? 1000 : 100 }.fixedSize()
            HStack {
                ForEach([AudioSpike.Bus.voice, .cast, .music], id: \.self) { b in
                    Button("Tone cut \(b.rawValue)") { audio?.toneTest(.cut, on: b) }
                }
                Button("Tone, no event") { audio?.toneTest(.none, on: .voice) }   // control: the tone's start and end only
                Button("Tone mute") { audio?.toneTest(.mute, on: .voice) }
                Button("Tone freeze") { audio?.toneTest(.freeze, on: .music) }
                Button("Freeze continuity") { audio?.continuityTest(on: .voice) }
                Button("Tone + arm 5 s") { audio?.toneArmed5s() }
                #if os(iOS)
                Button("Simulate media reset") { audio?.simulateMediaServicesReset() }
                #endif
            }.buttonStyle(.bordered)
            LogView()
        }
        .padding()
        .onAppear { if audio == nil { audio = AudioSpike(log: { s in Task { @MainActor in SpikeLog.shared.line("[audio] \(s)") } }) } }
    }

    private func press(source: String) {
        pressed = true
        let t = audio?.play("chime", on: .ui) ?? 0
        lastHandOff = String(format: "%@ handed to the audio queue at uptime %.4f", source, t)
        SpikeLog.shared.line("[audio] press \(source) handed=\(String(format: "%.4f", t))")
        #if os(iOS)
        NextFrame.log(after: t)      // ADR-0010 D9: the first frame that draws the press dot
        #endif
    }

    /// Audio E6 → E9 timing on the normal set: letter at 0, twinkle at 0.8, cast at 2.45, word at 2.70 (cast ducked).
    private func scripted() {
        guard let a = audio else { return }
        a.play("voice", on: .voice)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { a.play("ping", on: .ui) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) { a.play("cast", on: .cast) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.70) { a.play("voice", on: .voice) }
        SpikeLog.shared.line("[audio] scripted reveal E6/E7/E8/E9")
    }
}

#if os(iOS)
/// ADR-0010 D9: logs the `targetTimestamp` (display time) and the display rate of the next display-link frame after a
/// press: the press dot set in the same callback is drawn in that frame. One-shot; the link invalidates itself.
@MainActor final class NextFrame: NSObject {
    private var link: CADisplayLink?
    private let handed: Double
    private static var live: [NextFrame] = []
    private init(_ handed: Double) { self.handed = handed }
    static func log(after handed: Double) {
        let f = NextFrame(handed); live.append(f)
        f.link = CADisplayLink(target: f, selector: #selector(tick(_:)))
        f.link?.add(to: .main, forMode: .common)
    }
    @objc private func tick(_ l: CADisplayLink) {
        let hz = l.targetTimestamp > l.timestamp ? 1 / (l.targetTimestamp - l.timestamp) : 0
        SpikeLog.shared.line(String(format: "[audio] split frame: handed %.4f firstFrame %.4f (%.0f Hz)", handed, l.targetTimestamp, hz))
        l.invalidate(); NextFrame.live.removeAll { $0 === self }
    }
}
#endif
