// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// (b) Rive: plays a stock sample .riv (runtime cost only: it is not a glyph → silhouette morph). A press restarts
// it (reset + play). The file is loaded from bundled data with loadCdn passed EXPLICITLY (the legacy API defaults to
// true, which downloads "hosted" assets from Rive's CDN at play time).
#if !NORIVE
import SwiftUI
import RiveRuntime
import QuartzCore

/// Times every frame Rive draws (the first one after a press is that press's first frame).
final class TimedRiveView: RiveView {
    override func drawRive(_ rect: CGRect, size: CGSize) {
        super.drawRive(rect, size: size)
        Metrics.shared.frame(at: CACurrentMediaTime())
        MainActor.assumeIsolated { RiveStage.shared?.controller?.frameTick() }
    }
}

final class TimedRiveViewModel: RiveViewModel {
    override func createRiveView() -> RiveView {
        let v = TimedRiveView(model: riveModel!, autoPlay: autoPlay)
        setRiveView(view: v)
        return v
    }
}

final class RiveStage: Stage {
    static var shared: RiveStage?
    weak var controller: SpikeController?
    let vm: TimedRiveViewModel
    let file: String, loadCdn: Bool
    private var startedAt = 0.0, length: Double

    init(controller: SpikeController) {
        self.controller = controller
        file = SpikeController.args.string(forKey: "riv") ?? "mascot"
        loadCdn = SpikeController.args.object(forKey: "cdn") != nil ? SpikeController.args.bool(forKey: "cdn") : false
        length = controller.spec.duration + 0.5
        let url = Bundle.main.url(forResource: file, withExtension: "riv", subdirectory: "rivassets")!
        let data = try! Data(contentsOf: url)
        let rf = try! RiveFile(data: data, loadCdn: loadCdn)
        vm = TimedRiveViewModel(RiveModel(riveFile: rf), fit: .contain, autoPlay: false)
        NSLog("[spike] rive file=%@ loadCdn=%d bytes=%d", file, loadCdn ? 1 : 0, data.count)
        RiveStage.shared = self
    }

    func start(key: String) { vm.reset(); vm.play(); startedAt = CACurrentMediaTime() }
    var activeMorphs: Int { CACurrentMediaTime() - startedAt < length && startedAt > 0 ? 1 : 0 }
}
#endif
