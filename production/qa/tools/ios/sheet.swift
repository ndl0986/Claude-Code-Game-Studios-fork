// contact sheet, 2 columns, each tile 760x522 (keeps nothing of the aspect ratio: for looking, not measuring)
// usage: sheet <out.png> <in.png>...
import AppKit
let a = CommandLine.arguments; let out = a[1]; let files = Array(a[2...])
let w: CGFloat = 760, h: CGFloat = 522, cols = 2, rows = (files.count + 1) / 2
let img = NSImage(size: NSSize(width: w*CGFloat(cols), height: h*CGFloat(rows)))
img.lockFocus(); NSColor.black.setFill(); NSRect(origin: .zero, size: img.size).fill()
for (i, f) in files.enumerated() { guard let im = NSImage(contentsOfFile: f) else { continue }
  let c = i % cols, r = i / cols
  im.draw(in: NSRect(x: CGFloat(c)*w + 2, y: CGFloat(rows-1-r)*h + 2, width: w-4, height: h-4)) }
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
