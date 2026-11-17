// Timed taps on the Device Hub window (iOS Simulator), posted to the Device Hub process (needs Accessibility).
// usage: taps <x> <y> [<gap s> <x> <y>]...   window-relative points; each tap is down, 60 ms, up.
// Prints the window origin and each tap's send time (mach uptime, s). Gaps are measured from the previous tap's down.
import AppKit
let pid = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Devices").first!.processIdentifier
let wins = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
let w = wins.first { ($0[kCGWindowOwnerPID as String] as? Int32) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }!
let b = w[kCGWindowBounds as String] as! [String: CGFloat]; let ox = b["X"]!, oy = b["Y"]!
print("window origin", ox, oy, "size", b["Width"]!, b["Height"]!)
var a = Array(CommandLine.arguments.dropFirst()); var i = 0; var last = 0.0
func now() -> Double { ProcessInfo.processInfo.systemUptime }
while i < a.count {
  var gap = 0.0
  if i > 0 { gap = Double(a[i])!; i += 1 }
  let p = CGPoint(x: ox + CGFloat(Double(a[i])!), y: oy + CGFloat(Double(a[i+1])!)); i += 2
  if last > 0 { while now() < last + gap { usleep(500) } }
  let t = now(); last = t
  CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: p, mouseButton: .left)!.postToPid(pid)
  usleep(60_000)
  CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: p, mouseButton: .left)!.postToPid(pid)
  print(String(format: "tap %.0f,%.0f @ %.3f", p.x - ox, p.y - oy, t))
}
