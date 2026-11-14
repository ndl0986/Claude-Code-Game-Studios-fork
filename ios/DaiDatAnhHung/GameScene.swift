import SpriteKit
import GameCore

/// The one scene for every screen. Scaffold only: shows the app title from content/data.
final class GameScene: SKScene {
    private let content: ContentBundle

    init(content: ContentBundle) {
        self.content = content
        super.init(size: CGSize(width: 1280, height: 720))
        scaleMode = .aspectFit
        backgroundColor = SKColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        let title = SKLabelNode(text: content.strings()?.string("ui.app.title")?.text(.vi) ?? "—")
        title.fontSize = 64
        title.fontColor = SKColor(red: 0.20, green: 0.16, blue: 0.12, alpha: 1)
        title.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(title)
    }
}
