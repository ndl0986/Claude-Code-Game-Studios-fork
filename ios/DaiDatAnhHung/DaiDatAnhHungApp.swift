import SwiftUI
import SpriteKit
import GameCore

/// The SwiftUI shell (ADR-0001): loads content/data from the bundle, hosts one SpriteKit scene.
@main
struct DaiDatAnhHungApp: App {
    @Environment(\.scenePhase) private var phase
    @State private var scene = Boot.makeScene()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // the launch colour behind the first SpriteKit frame: no grey flash on a fresh install (iOS-R2-02)
                Color("LaunchColor")
                if let scene { SpriteView(scene: scene, options: [.ignoresSiblingOrder, .allowsTransparency]) }
            } // content that fails to load leaves the launch colour (logged); never a crash in front of a child
            .ignoresSafeArea()
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .onChange(of: phase) { _, p in if p != .active { scene?.appWillResignActive() } }
        }
    }
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
        let askedSample = isDebug && UserDefaults.standard.string(forKey: "hero") == "sample"
        let extra = askedSample && FileManager.default.fileExists(atPath: samples.path) ? [samples] : []
        do {
            let content = try ContentSet.load(dataRoot: data, extraHeroDirs: extra)
            for a in content.assets.assets where a.kind == "picture" { Pictures.files[a.id] = data.appendingPathComponent(a.file) }
            for (id, t) in content.themes?.themes ?? [:] { Backdrop.bands[id] = (Backdrop.hex(t.skyBand.top), Backdrop.hex(t.skyBand.bottom)) }
            let d = UserDefaults.standard
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
