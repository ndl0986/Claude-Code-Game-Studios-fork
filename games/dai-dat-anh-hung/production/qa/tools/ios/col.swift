import AppKit
// col <png> x y0 y1: runs of similar colour down column x (tolerance 18), printed as y-start..y-end #hex
let a = CommandLine.arguments
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let x = Int(a[2])!, y0 = Int(a[3])!, y1 = Int(a[4])!
var p = [Int](repeating: 0, count: 4); var start = y0; var cur = [Int]()
func out(_ s: Int, _ e: Int, _ c: [Int]) { if e - s >= 2 { print("\(s)..\(e) (\(e-s+1)) #" + c.prefix(3).map { String(format: "%02X", $0) }.joined()) } }
for y in y0...y1 { r.getPixel(&p, atX: x, y: y)
  if cur.isEmpty { cur = p; start = y; continue }
  if zip(p.prefix(3), cur.prefix(3)).contains(where: { abs($0 - $1) > 18 }) { out(start, y-1, cur); cur = p; start = y } }
out(start, y1, cur)
