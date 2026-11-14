import SwiftUI
import SpriteKit
import GameCore

/// The SwiftUI shell (ADR-0001): hosts one SpriteKit scene that draws every screen.
@main
struct DaiDatAnhHungApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

/// Wraps the game scene; the scene reads the safe area itself to place the pads.
struct GameView: View {
    @State private var scene = GameScene(content: ContentBundle.main)

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
    }
}
