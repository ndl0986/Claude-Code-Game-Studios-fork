// frames.swift: read every decoded frame of an mp4 with its timestamp (AVAssetReader).
//   swift frames.swift dump <mp4> <outdir> <t0> <t1> [width]  -> PNG per frame in [t0,t1], named f_<ms>.png
//   swift frames.swift probe <mp4> "x,y,w,h;..."               -> per frame: pts_ms then mean R,G,B per rect (device px)
import AVFoundation
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
let mode = a[1], url = URL(fileURLWithPath: a[2])
let asset = AVURLAsset(url: url)
let sem = DispatchSemaphore(value: 0)
var track: AVAssetTrack!
Task { track = try! await asset.loadTracks(withMediaType: .video).first!; sem.signal() }
sem.wait()
let reader = try! AVAssetReader(asset: asset)
let out = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
reader.add(out); reader.startReading()
let ctx = CIContext()
var rects: [[Int]] = []
if mode == "probe" { rects = a[3].split(separator: ";").map { $0.split(separator: ",").map { Int($0)! } } }
while let sb = out.copyNextSampleBuffer() {
    guard let pb = CMSampleBufferGetImageBuffer(sb) else { continue }
    let ms = Int(CMSampleBufferGetPresentationTimeStamp(sb).seconds * 1000)
    if mode == "dump" {
        let t0 = Double(a[4])! * 1000, t1 = Double(a[5])! * 1000
        if Double(ms) < t0 || Double(ms) > t1 { continue }
        var img = CIImage(cvPixelBuffer: pb)
        if a.count > 6 { let s = Double(a[6])! / img.extent.width; img = img.transformed(by: .init(scaleX: s, y: s)) }
        let cg = ctx.createCGImage(img, from: img.extent)!
        let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "\(a[3])/f_\(String(format: "%06d", ms)).png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dst, cg, nil); CGImageDestinationFinalize(dst)
    } else {
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let bpr = CVPixelBufferGetBytesPerRow(pb)
        var line = "\(ms)"
        for r in rects {
            var s = [0, 0, 0], n = 0
            for y in stride(from: r[1], to: r[1] + r[3], by: 2) { for x in stride(from: r[0], to: r[0] + r[2], by: 2) {
                let p = base + y * bpr + x * 4; s[0] += Int(p[2]); s[1] += Int(p[1]); s[2] += Int(p[0]); n += 1 } }
            line += " \(s[0] / max(n, 1)),\(s[1] / max(n, 1)),\(s[2] / max(n, 1))"
        }
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)
        print(line)
    }
}
