import AppKit
// crop <png> x y w h scale <out>: crops in NSBitmapImageRep pixel coords (top-left origin) and scales up
let a = CommandLine.arguments
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let x = Int(a[2])!, y = Int(a[3])!, w = Int(a[4])!, h = Int(a[5])!, s = Int(a[6])!
let o = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w*s, pixelsHigh: h*s, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
var p = [Int](repeating: 0, count: 4)
for yy in 0..<h { for xx in 0..<w { r.getPixel(&p, atX: x+xx, y: y+yy); for dy in 0..<s { for dx in 0..<s { o.setPixel(&p, atX: xx*s+dx, y: yy*s+dy) } } } }
try! o.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[7]))
