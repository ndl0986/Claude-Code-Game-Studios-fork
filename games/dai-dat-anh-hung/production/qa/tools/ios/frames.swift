// extract frames from a video every <step> s into <outdir>/f_<t>.png.  usage: frames <video> <outdir> <step> [<from> <to>]
import AVFoundation; import AppKit
let a = CommandLine.arguments; let url = URL(fileURLWithPath: a[1]); let out = a[2]; let step = Double(a[3])!
let asset = AVURLAsset(url: url); let g = AVAssetImageGenerator(asset: asset)
g.requestedTimeToleranceBefore = .zero; g.requestedTimeToleranceAfter = .zero; g.appliesPreferredTrackTransform = true
let dur = CMTimeGetSeconds(asset.duration); let from = a.count > 4 ? Double(a[4])! : 0; let to = a.count > 5 ? Double(a[5])! : dur
var t = from
while t <= to { if let cg = try? g.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
  let rep = NSBitmapImageRep(cgImage: cg); try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: String(format: "%@/f_%05.2f.png", out, t))) }
  t += step }
print("duration", dur)
