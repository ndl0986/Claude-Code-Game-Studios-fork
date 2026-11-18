import SpriteKit
import SwiftUI

/// The stage's fixed layers and their zPositions, in Reveal Stage R10's order (ADR-0006 D1).
enum StageLayer: CGFloat, CaseIterable {
    case scene = 0, parade = 10, leaving = 20, current = 30, keyboardRow = 35, glyph = 40, sparkles = 50
    case hints = 60, tokens = 70, moon = 80
}

/// The blank Title scene: the Dusk sky colour and the empty fixed layers (TASK-079 S1). No rule lives here; later
/// stories map KidCore's render plan onto these layers (ADR-0006 D1).
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
