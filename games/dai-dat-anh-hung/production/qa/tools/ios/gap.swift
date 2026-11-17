import AppKit
// gap <png> x0 x1 y0 y1: per column, last drum-ring row (gold, R>200,G 150-215,B<150) and first ink row (R<110) below it
let a = CommandLine.arguments
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let x0 = Int(a[2])!, x1 = Int(a[3])!, y0 = Int(a[4])!, y1 = Int(a[5])!
var p = [Int](repeating: 0, count: 4); var best = 999, bx = 0
for x in x0...x1 { var ring = -1, ink = -1
  for y in y0...y1 { r.getPixel(&p, atX: x, y: y)
    if p[0] > 200 && p[1] > 150 && p[1] < 215 && p[2] < 150 { ring = y }
    if p[0] < 110 && ink < 0 && ring >= 0 { ink = y } }
  if ring >= 0 && ink >= 0 { let g = ink - ring - 1; if g < best { best = g; bx = x } } }
print("min gap \(best) px at x \(bx)")
