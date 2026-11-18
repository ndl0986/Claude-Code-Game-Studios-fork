import KidCore
import SpriteKit
import SwiftUI

/// The stage's fixed layers and their zPositions, in Reveal Stage R10's order (ADR-0006 D1).
enum StageLayer: CGFloat, CaseIterable {
    case scene = 0, parade = 10, leaving = 20, current = 30, keyboardRow = 35, glyph = 40, sparkles = 50
    case hints = 60, tokens = 70, moon = 80
}

/// The blank Title scene: the Dusk sky colour filling the whole window and the empty fixed layers (TASK-079). No rule
/// lives here; later stories map KidCore's render plan onto these layers (ADR-0006 D1). The stage root carries
/// Reveal Stage F1 (KidCore `StageFit`): the safe stage contained, the sky extending, y flipped (ADR-0006 D2; K-39).
final class StageScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0x46 / 255.0, green: 0x55 / 255.0, blue: 0x8F / 255.0, alpha: 1)
        let root = SKNode()
        root.name = "stageRoot"
        addChild(root)
        for layer in StageLayer.allCases {
            let n = SKNode()
            n.name = "layer.\(layer)"
            n.zPosition = layer.rawValue
            root.addChild(n)
        }
    }

    /// The current F1 fit, in points (the scene is `.resizeFill`, sized in points).
    private(set) var fit = StageFit(width: 1280, height: 720)

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0, let root = childNode(withName: "stageRoot") else { return }
        fit = StageFit(width: Double(size.width), height: Double(size.height))
        root.xScale = CGFloat(fit.scale)
        root.yScale = CGFloat(-fit.scale) // KidCore is y-down, SpriteKit y-up
        root.position = CGPoint(x: fit.offsetX, y: Double(size.height) - fit.offsetY)
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}

/// One SKView per window, wrapped for SwiftUI (ADR-0006 D1), not SwiftUI's SpriteView.
#if os(iOS)
struct StageView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let v = SKView()
        v.accessibilityIgnoresInvertColors = true // ADR-0006 D5 (K-30)
        v.presentScene(StageScene(size: CGSize(width: 1280, height: 720)))
        return v
    }
    func updateUIView(_ view: SKView, context: Context) {}
}
#else
struct StageView: NSViewRepresentable {
    func makeNSView(context: Context) -> SKView {
        let v = SKView()
        v.presentScene(StageScene(size: CGSize(width: 1280, height: 720)))
        return v
    }
    func updateNSView(_ view: SKView, context: Context) {}
}
#endif
