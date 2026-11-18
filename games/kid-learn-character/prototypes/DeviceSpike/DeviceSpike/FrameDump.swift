// PROTOTYPE - NOT FOR PRODUCTION (TASK-118; ADR-0013 D5 rehearsal for P-3 / M-12)
// The frame dump by ADR-0013 G5's method: after the view's own update for a tick, a second SKRenderer on the same scene
// calls render(withViewport:…) ONLY, never updateAtTime: (an update would advance every action a second time). It draws
// into a Metal texture at the view's drawable size and pixel format, reads it back off the main thread and writes raw
// pixels plus a times.csv of each frame's update time. Never SKView.texture(from:) (cropped to the node, not the
// drawable) and never PNG-encoding on the main thread. Sharing one scene between an SKView and an SKRenderer is
// NOT SOURCED: the V7 probe (RenderScene) shows whether the dump disturbs the scene.
import SpriteKit
import Metal
import QuartzCore

final class FrameDump {
    struct Target { let width: Int; let height: Int; let format: MTLPixelFormat; let colorSpace: String; let source: String }
    private let device: MTLDevice, queue: MTLCommandQueue, renderer: SKRenderer
    private let target: Target, bytesPerPixel: Int, dir: URL
    private let io = DispatchQueue(label: "framedump.io")
    private let lock = NSLock()
    private var inFlight = 0, written = 0, dropped = 0, index = 0
    private var times: [String] = ["frame,update_time_s"]
    private let maxInFlight = 6

    /// The view's drawable: its CAMetalLayer when it has one (size, pixel format, colour space), else bounds × scale.
    static func target(of view: SKView, scale: CGFloat) -> Target {
        if let ml = view.layer as? CAMetalLayer, ml.drawableSize.width > 0 {
            let cs = ml.colorspace.flatMap { $0.name as String? } ?? "nil (the layer's default)"
            return Target(width: Int(ml.drawableSize.width), height: Int(ml.drawableSize.height), format: ml.pixelFormat,
                          colorSpace: cs, source: "CAMetalLayer")
        }
        return Target(width: Int((view.bounds.width * scale).rounded()), height: Int((view.bounds.height * scale).rounded()),
                      format: .bgra8Unorm, colorSpace: "unknown (no CAMetalLayer; assumed sRGB)", source: "bounds x scale")
    }

    /// `view`: the SKView presenting `scene`; its draw settings are copied so the dump draws what the view draws.
    init?(scene: SKScene, view: SKView, target: Target, log: (String) -> Void) {
        guard let d = MTLCreateSystemDefaultDevice(), let q = d.makeCommandQueue() else { log("frame dump: no Metal device"); return nil }
        let bpp: Int
        switch target.format {
        case .bgra8Unorm, .bgra8Unorm_srgb, .rgba8Unorm, .rgba8Unorm_srgb, .bgr10a2Unorm, .rgb10a2Unorm: bpp = 4
        case .bgra10_xr, .bgra10_xr_srgb, .rgba16Float: bpp = 8
        default: log("frame dump: drawable pixel format \(target.format.rawValue) not handled; not started"); return nil
        }
        device = d; queue = q; self.target = target; bytesPerPixel = bpp
        renderer = SKRenderer(device: d); renderer.scene = scene
        renderer.ignoresSiblingOrder = view.ignoresSiblingOrder; renderer.shouldCullNonVisibleNodes = view.shouldCullNonVisibleNodes
        dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("framedump", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let meta = "width \(target.width)\nheight \(target.height)\npixel_format \(target.format.rawValue)\nbytes_per_pixel \(bpp)\n" +
                   "color_space \(target.colorSpace)\nsource \(target.source)\nmethod SKRenderer render only (no updateAtTime), after the view's update\n" +
                   "ignores_sibling_order \(renderer.ignoresSiblingOrder) (copied from the view)\nshould_cull_non_visible_nodes \(renderer.shouldCullNonVisibleNodes) (copied from the view)\n" +
                   "scale_mode \(scene.scaleMode.rawValue) (how SKRenderer applies it to the viewport is NOT SOURCED; ADR-0013 V2 checks it)\n"
        try? meta.write(to: dir.appendingPathComponent("format.txt"), atomically: true, encoding: .utf8)
        log("frame dump: \(target.width)x\(target.height) px, format \(target.format.rawValue) (\(bpp) B/px), colour space \(target.colorSpace), from \(target.source); ignoresSiblingOrder \(renderer.ignoresSiblingOrder), shouldCullNonVisibleNodes \(renderer.shouldCullNonVisibleNodes) (from the view)")
    }

    /// One frame of the scene as the view is about to draw it. Call from didFinishUpdate (main thread).
    func capture(scene: SKScene, updateTime: TimeInterval) {
        lock.lock(); let busy = inFlight >= maxInFlight; if !busy { inFlight += 1 }; lock.unlock()
        let i = index; index += 1
        if busy { lock.lock(); dropped += 1; lock.unlock(); return }      // a gap the coverage rule (D5) will see in times.csv
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: target.format, width: target.width, height: target.height, mipmapped: false)
        d.usage = [.renderTarget, .shaderRead]
        #if os(macOS)
        d.storageMode = device.hasUnifiedMemory ? .shared : .managed   // a discrete-GPU Mac needs a blit synchronize
        #else
        d.storageMode = .shared                                       // iOS GPUs share memory with the CPU
        #endif
        guard let tex = device.makeTexture(descriptor: d), let cb = queue.makeCommandBuffer() else { finish(nil, i); return }
        times.append(String(format: "%d,%.6f", i, updateTime))      // only a frame that is actually rendered gets a row
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture = tex; rpd.colorAttachments[0].loadAction = .clear; rpd.colorAttachments[0].storeAction = .store
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        #if os(iOS)
        scene.backgroundColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        if let c = scene.backgroundColor.usingColorSpace(.sRGB) { r = c.redComponent; g = c.greenComponent; b = c.blueComponent; a = c.alphaComponent }
        #endif
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
        renderer.render(withViewport: CGRect(x: 0, y: 0, width: target.width, height: target.height), commandBuffer: cb, renderPassDescriptor: rpd)
        #if os(macOS)
        if d.storageMode == .managed, let blit = cb.makeBlitCommandEncoder() { blit.synchronize(resource: tex); blit.endEncoding() }
        #endif
        let w = target.width, h = target.height, rowBytes = target.width * bytesPerPixel
        cb.addCompletedHandler { [weak self] _ in
            var data = Data(count: rowBytes * h)
            data.withUnsafeMutableBytes { tex.getBytes($0.baseAddress!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0) }
            self?.finish(data, i)
        }
        cb.commit()
    }

    private func finish(_ data: Data?, _ i: Int) {
        io.async { [self] in
            if let data { try? data.write(to: dir.appendingPathComponent(String(format: "f%05d.raw", i))) }
            lock.lock(); inFlight -= 1; if data != nil { written += 1 }; lock.unlock()
        }
    }

    /// Waits for the writes, writes times.csv, and reports what was captured.
    func close(log: @escaping (String) -> Void) {
        let t = times.joined(separator: "\n") + "\n", requested = index
        io.async { [self] in
            while true { lock.lock(); let n = inFlight; lock.unlock(); if n == 0 { break }; Thread.sleep(forTimeInterval: 0.01) }
            try? t.write(to: dir.appendingPathComponent("times.csv"), atomically: true, encoding: .utf8)
            lock.lock(); let w = written, dr = dropped; lock.unlock()
            let mb = Double(w * target.width * target.height * bytesPerPixel) / 1_048_576
            DispatchQueue.main.async { log(String(format: "frame dump done: %d of %d frames written, %d dropped (in-flight cap %d), %.0f MB raw in %@",
                                                  w, requested, dr, self.maxInFlight, mb, self.dir.path)) }
        }
    }
}
