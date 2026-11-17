// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// One press handler for every source (touch, hardware key, synthetic driver), the ADR-0001 queue (start now when
// idle, else queue up to 3, else drop), the sound, and the automated runs driven by launch arguments:
//   -runtime spritekit|rive   -hold <s>   -latency <n presses>   -mash <seconds at 10/s>   -label <name>
//   -riv mascot|hosted_assets   -cdn 0|1   (Rive file and its loadCdn flag; hosted_assets = the network check)
import Foundation
import QuartzCore
import MorphCore

protocol Stage: AnyObject {
    /// Shows `key`'s morph from the next frame on, replacing whatever is on stage.
    func start(key: String)
    /// Morphs currently animating on the stage (the mash check: never above 1).
    var activeMorphs: Int { get }
}

@MainActor
final class SpikeController: ObservableObject {
    static let args = UserDefaults.standard
    @Published var runtime: String = SpikeController.args.string(forKey: "runtime") ?? "spritekit"
    @Published var status = "Press D, B or 3"
    let spec: MorphSpec
    let audio = Audio()
    weak var stage: Stage?
    private var active: Int?, queue: [(String, Int)] = [], generation = 0
    let keys = ["D", "B", "3"]

    init() {
        let url = Bundle.main.url(forResource: "morph-spec", withExtension: "json", subdirectory: "fixtures")!
        var s = try! JSONDecoder().decode(MorphSpec.self, from: Data(contentsOf: url))
        if Self.args.object(forKey: "hold") != nil { s.hold = Self.args.double(forKey: "hold") }
        spec = s
    }

    var revealLength: Double { spec.duration + spec.hold }

    /// Every press, from every source, comes here. `t` is the event's own timestamp.
    func press(_ key: String, source: String, at t: Double) {
        let k = key.uppercased()
        guard keys.contains(k) else { return }
        let m = Metrics.shared, row = m.press(key: k, source: source, runtime: runtime, at: t)
        if active == nil { begin(k, row) }
        else if queue.count < 3 { queue.append((k, row)); m.rows[row].queued = true }
        else { m.rows[row].dropped = true }
        m.maxQueue = max(m.maxQueue, queue.count)
    }

    private func begin(_ key: String, _ row: Int) {
        let m = Metrics.shared
        active = row
        m.awaitFrame(row)
        stage?.start(key: key)
        let (sched, est) = audio.roar()
        m.rows[row].soundSched = sched; m.rows[row].soundEst = est
        status = "\(key) (\(runtime))"
        generation += 1
        let g = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + revealLength) { [weak self] in
            guard let self, self.generation == g else { return }
            self.active = nil
            if !self.queue.isEmpty { let (k, r) = self.queue.removeFirst(); self.begin(k, r) }
        }
    }

    /// Called every frame by the stage's renderer.
    func frameTick() { Metrics.shared.maxActiveMorphs = max(Metrics.shared.maxActiveMorphs, stage?.activeMorphs ?? 0) }

    // MARK: automated runs

    private var memTimer: Timer?

    func startAutomation() {
        memTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in Metrics.shared.sampleMemory() }
        let label = Self.args.string(forKey: "label") ?? runtime
        if Self.args.integer(forKey: "latency") > 0 {
            let n = Self.args.integer(forKey: "latency"), gap = revealLength + 0.4
            // first press 2 s after launch (cold), then every key in turn (each key's first press is cold too)
            for i in 0..<n {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2 + Double(i) * gap) { [weak self] in
                    guard let self else { return }
                    self.press(self.keys[i % self.keys.count], source: "synthetic", at: CACurrentMediaTime())
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2 + Double(n) * gap + 1) { Metrics.shared.dump(label: label) }
        }
        if Self.args.double(forKey: "mash") > 0 {
            let secs = Self.args.double(forKey: "mash")
            var i = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                Metrics.shared.sampleMemory()
                let start = CACurrentMediaTime()
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
                    MainActor.assumeIsolated {
                        guard let self else { t.invalidate(); return }
                        if CACurrentMediaTime() - start >= secs { t.invalidate(); Metrics.shared.sampleMemory(); Metrics.shared.dump(label: label); return }
                        self.press(self.keys[i % self.keys.count], source: "mash", at: CACurrentMediaTime()); i += 1
                    }
                }
            }
        }
    }

    func dumpNow() { Metrics.shared.sampleMemory(); status = Metrics.shared.dump(label: (Self.args.string(forKey: "label") ?? runtime) + "-manual") }
}
