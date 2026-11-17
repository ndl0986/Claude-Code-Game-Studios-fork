// top 5 exact colours in a rect.  usage: hist2 <png> x y w h  (px)
import AppKit
let a = CommandLine.arguments
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let x = Int(a[2])!, y = Int(a[3])!, w = Int(a[4])!, h = Int(a[5])!
var c: [String: Int] = [:]
for j in y..<y+h { for i in x..<x+w { let k = r.colorAt(x: i, y: j)!.usingColorSpace(.sRGB)!; c[String(format: "%02X%02X%02X", Int(k.redComponent*255+0.5), Int(k.greenComponent*255+0.5), Int(k.blueComponent*255+0.5)), default: 0] += 1 } }
for (k, v) in c.sorted(by: { $0.value > $1.value }).prefix(5) { print(k, v) }
