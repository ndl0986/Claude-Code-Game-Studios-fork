import SwiftUI
import SpriteKit
import AVFoundation
import GameCore

/// The SwiftUI shell (ADR-0001): loads content/data from the bundle, hosts one SpriteKit scene.
/// The scene is built off the main thread so the launch colour shows at once (iOS-R2-05), and it
/// is hosted in a plain SKView (not SwiftUI's SpriteView) so UIKit delivers every touch phase to
/// the scene (iOS-R2-03).
@main
struct DaiDatAnhHungApp: App {
    @Environment(\.scenePhase) private var phase
    @State private var scene: GameScene?

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color("LaunchColor")
                if let scene { GameSKView(scene: scene) }
            } // content that fails to load leaves the launch colour (logged); never a crash in front of a child
            .ignoresSafeArea()
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .task {
                guard scene == nil else { return }
                scene = await Task.detached(priority: .userInitiated) { Boot.makeScene() }.value
            }
            .onChange(of: phase) { _, p in if p != .active { scene?.appWillResignActive() } }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { _ in
                scene?.releaseAllInput() // Input GDD Rule 11: audio route change
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in
                scene?.releaseAllInput() // Input GDD Rule 11: audio interruption
            }
        }
    }
}

/// A plain SKView for the scene: multi-touch on, sibling order ignored (z decides), transparent
/// until the first frame so the launch colour shows through.
struct GameSKView: UIViewRepresentable {
    let scene: GameScene
    func makeUIView(context: Context) -> SKView {
        let v = SKView()
        v.isMultipleTouchEnabled = true
        v.ignoresSiblingOrder = true
        v.allowsTransparency = true
        v.backgroundColor = .clear
        v.presentScene(scene)
        return v
    }
    func updateUIView(_ uiView: SKView, context: Context) {}
}

extension UserDefaults: KeyValueStore {}

enum Boot {
    #if DEBUG
    static let isDebug = true
    #else
    static let isDebug = false
    #endif

    /// Debug launch arguments (same names as Android): -startScreen quiz -q 2 -beat 3 -stage telegraph
    /// -stars 2 -wrong 1 -hero sample -lang en. UserDefaults reads `-key value` arguments.
    static func makeScene() -> GameScene? {
        let bundle = Bundle.main.bundleURL
        let data = bundle.appendingPathComponent("data")
        Font.register(data.appendingPathComponent("fonts/nunito.ttf"))
        let samples = bundle.appendingPathComponent("samples/heroes/sample")
        // the debug sample hero loads only when asked (`-hero sample`), as on Android: debug and QC play the real progression
        // the unlock jump also loads it, so the screen has a second hero to name (iOS QC r4 N2)
        let askedSample = isDebug && (UserDefaults.standard.string(forKey: "hero") == "sample" || UserDefaults.standard.string(forKey: "startScreen") == "unlock")
        let extra = askedSample && FileManager.default.fileExists(atPath: samples.path) ? [samples] : []
        do {
            let content = try ContentSet.load(dataRoot: data, extraHeroDirs: extra)
            for a in content.assets.assets where a.kind == "picture" { Pictures.files[a.id] = data.appendingPathComponent(a.file) }
            for (id, t) in content.themes?.themes ?? [:] { Backdrop.bands[id] = (Backdrop.hex(t.skyBand.top), Backdrop.hex(t.skyBand.bottom)) }
            let d = UserDefaults.standard
            #if DEBUG
            // UI tests (TASK-023 G): `-resetProgress YES` starts from a fresh install's saved state
            if d.bool(forKey: "resetProgress") {
                for h in content.heroes.map(\.mission.hero.id) { for k in ["stars", "completed", "medal", "seen_open"] { d.removeObject(forKey: "\(k).\(h)") } }
            }
            #endif
            let wanted = isDebug ? d.string(forKey: "hero") : nil
            guard let hero = content.heroes.first(where: { $0.mission.hero.id == wanted }) ?? content.heroes.first else {
                NSLog("[content] no hero bundled"); return nil
            }
            let game = Game(content: content, hero: hero, store: d, isDebug: isDebug)
            if isDebug, let s = d.string(forKey: "startScreen") {
                func int(_ k: String) -> Int? { d.object(forKey: k) == nil ? nil : d.integer(forKey: k) }
                game.debugStart(screen: s, q: int("q"), beat: int("beat"), stage: d.string(forKey: "stage"), stars: int("stars"))
            }
            let audio = Audio(volume: content.tuning["volume"])
            return GameScene(game: game, audio: audio)
        } catch {
            NSLog("[content] failed to load: \(error)")
            return nil
        }
    }
}
