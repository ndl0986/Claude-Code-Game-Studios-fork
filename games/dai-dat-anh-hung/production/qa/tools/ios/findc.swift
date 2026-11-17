import AppKit
// findc <png> r g b [tol]: prints a 40-px grid of cells containing the exact colour, with counts
let a = CommandLine.arguments
let rep = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let t = [Int(a[2])!, Int(a[3])!, Int(a[4])!]; let tol = a.count > 5 ? Int(a[5])! : 0
var cells = [String: Int](); var p = [Int](repeating: 0, count: 4)
for y in stride(from: 0, to: rep.pixelsHigh, by: 2) { for x in stride(from: 0, to: rep.pixelsWide, by: 2) {
  rep.getPixel(&p, atX: x, y: y)
  if abs(p[0]-t[0]) <= tol && abs(p[1]-t[1]) <= tol && abs(p[2]-t[2]) <= tol { cells["\(x/40*40),\(y/40*40)", default: 0] += 1 } } }
print("size", rep.pixelsWide, rep.pixelsHigh)
for (k, v) in cells.sorted(by: { $0.key < $1.key }) where v > 3 { print(k, v) }
