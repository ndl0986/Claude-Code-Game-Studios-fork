// sheet.swift <out.png> <cols> <png...> : grid contact sheet with each file's name (timestamp) stamped on it.
import AppKit
let a = CommandLine.arguments
let cols = Int(a[2])!, files = Array(a[3...])
let imgs = files.map { NSImage(contentsOfFile: $0)! }
let w = imgs[0].size.width, h = imgs[0].size.height, rows = (imgs.count + cols - 1) / cols
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w) * cols, pixelsHigh: Int(h) * rows, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor.black.setFill(); NSRect(x: 0, y: 0, width: w * CGFloat(cols), height: h * CGFloat(rows)).fill()
for (i, im) in imgs.enumerated() {
    let x = CGFloat(i % cols) * w, y = CGFloat(rows - 1 - i / cols) * h
    im.draw(in: NSRect(x: x, y: y, width: w, height: h))
    let label = (files[i] as NSString).lastPathComponent.replacingOccurrences(of: ".png", with: "")
    NSString(string: label).draw(at: NSPoint(x: x + 6, y: y + h - 26), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 20), .foregroundColor: NSColor.red, .backgroundColor: NSColor.white])
}
NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[1]))
