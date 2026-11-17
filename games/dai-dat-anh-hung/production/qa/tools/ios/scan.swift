// colour runs along one row or column (colours quantised to /16); prints index = px/2 and colour at each change
// usage: swift scan.swift <png> row|col <fixed px>   (or compile: swiftc -O scan.swift -o scan)
import AppKit
let a = CommandLine.arguments
let r = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let horiz = a[2] == "row"; let fixed = Int(a[3])!
var prev = ""; let n = horiz ? r.pixelsWide : r.pixelsHigh
for i in stride(from: 0, to: n, by: 2) { let c = (horiz ? r.colorAt(x: i, y: fixed) : r.colorAt(x: fixed, y: i))!.usingColorSpace(.sRGB)!
 let k = String(format: "%02X%02X%02X", Int(c.redComponent*255)/16*16, Int(c.greenComponent*255)/16*16, Int(c.blueComponent*255)/16*16)
 if k != prev { print(i/2, k); prev = k } }
