// PROTOTYPE - NOT FOR PRODUCTION (ADR-0009 H-2, headless): does ONE SKShapeNode blend its own overlap twice?
// SpriteKit renders offscreen through SKRenderer into a Metal texture (no view, no window). An X (two crossing strokes
// in one path) is drawn white over black three ways; the crossing and a point on an arm are read back. Over black, a
// single blend at 0.8 reads 0.8 everywhere; a double blend reads ≈ 0.96 at the crossing.
// Run: swift tools/overlap-check.swift   (macOS GPU; the device run of the in-app "Overlap check" confirms on the iPad)
import SpriteKit
import Metal

guard let dev = MTLCreateSystemDefaultDevice(), let queue = dev.makeCommandQueue() else { print("no Metal device"); exit(2) }
let side = 200
func render(_ node: SKNode) -> (cross: Double, arm: Double) {
    let scene = SKScene(size: CGSize(width: side, height: side))
    scene.backgroundColor = .black; scene.anchorPoint = CGPoint(x: 0.5, y: 0.5); scene.addChild(node)
    let r = SKRenderer(device: dev); r.scene = scene
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: side, height: side, mipmapped: false)
    d.usage = [.renderTarget, .shaderRead]; d.storageMode = .managed
    let tex = dev.makeTexture(descriptor: d)!
    let rpd = MTLRenderPassDescriptor()
    rpd.colorAttachments[0].texture = tex; rpd.colorAttachments[0].loadAction = .clear
    rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1); rpd.colorAttachments[0].storeAction = .store
    let cb = queue.makeCommandBuffer()!
    r.update(atTime: 0)
    r.render(withViewport: CGRect(x: 0, y: 0, width: side, height: side), commandBuffer: cb, renderPassDescriptor: rpd)
    let blit = cb.makeBlitCommandEncoder()!; blit.synchronize(resource: tex); blit.endEncoding()
    cb.commit(); cb.waitUntilCompleted()
    var px = [UInt8](repeating: 0, count: side * side * 4)
    tex.getBytes(&px, bytesPerRow: side * 4, from: MTLRegionMake2D(0, 0, side, side), mipmapLevel: 0)
    func lum(_ x: Int, _ y: Int) -> Double { let o = (y * side + x) * 4; return (Double(px[o]) + Double(px[o + 1]) + Double(px[o + 2])) / (3 * 255) }
    return (lum(side / 2, side / 2), lum(side / 2 + 40, side / 2 + 40))   // the crossing; a point on one arm (the arms run on the diagonals)
}
let x = CGMutablePath(); x.move(to: CGPoint(x: -70, y: -70)); x.addLine(to: CGPoint(x: 70, y: 70))
x.move(to: CGPoint(x: -70, y: 70)); x.addLine(to: CGPoint(x: 70, y: -70))
func node(_ strokeAlpha: CGFloat, _ nodeAlpha: CGFloat) -> SKShapeNode {
    let n = SKShapeNode(path: x); n.strokeColor = SKColor(white: 1, alpha: strokeAlpha); n.lineWidth = 12; n.lineCap = .round
    n.fillColor = .clear; n.alpha = nodeAlpha; return n
}
func effect() -> SKNode { let e = SKEffectNode(); e.shouldRasterize = true; e.alpha = 0.8; e.addChild(node(1, 1)); return e }
var anyTwice = false
print("ADR-0009 H-2 overlap check (SKRenderer offscreen, \(dev.name)): white X over black; single blend at 0.8 reads 0.800")
for (name, n) in [("SKShapeNode, stroke alpha 0.8", node(0.8, 1) as SKNode), ("SKShapeNode, node alpha 0.8", node(1, 0.8)),
                  ("SKEffectNode(shouldRasterize) alpha 0.8 (the fallback)", effect())] {
    let r = render(n)
    let twice = r.cross > r.arm + 0.02
    if twice && !name.hasPrefix("SKEffectNode") { anyTwice = true }
    print(String(format: "%-56@ crossing %.3f  arm %.3f  → %@", name as NSString, r.cross, r.arm, twice ? "BLENDS TWICE" : "blends once"))
}
print(anyTwice ? "RESULT: a merged outline in one SKShapeNode does NOT give the group look here; use the fallback" :
                 "RESULT: one SKShapeNode blends its overlap once here; the merged outline gives the group look")
