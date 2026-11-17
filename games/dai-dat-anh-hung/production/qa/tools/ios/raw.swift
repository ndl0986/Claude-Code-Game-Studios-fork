import AppKit
let a = CommandLine.arguments
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let x = Int(a[2])!, y = Int(a[3])!
var p = [Int](repeating: 0, count: 4); r.getPixel(&p, atX: x, y: y); print("raw", p, r.colorSpace.localizedName ?? "")
