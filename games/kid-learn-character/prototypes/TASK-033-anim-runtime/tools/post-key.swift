// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// Posts one key chord at the HID event tap (the same path a keyboard's events take into WindowServer), so system
// shortcuts are handled as for a real key press. Needs Accessibility permission for the posting process.
//   swift tools/post-key.swift <virtualKeyCode> [cmd] [opt] [ctrl] [shift]     (prints "trusted=0|1")
import ApplicationServices
import Foundation
let a = CommandLine.arguments
print("trusted=\(AXIsProcessTrusted() ? 1 : 0)")
guard a.count > 1, let code = CGKeyCode(a[1]) else { exit(0) }
var flags: CGEventFlags = []
if a.contains("cmd") { flags.insert(.maskCommand) }
if a.contains("opt") { flags.insert(.maskAlternate) }
if a.contains("ctrl") { flags.insert(.maskControl) }
if a.contains("shift") { flags.insert(.maskShift) }
let src = CGEventSource(stateID: .hidSystemState)
let down = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: true)!, up = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: false)!
down.flags = flags; up.flags = flags
down.post(tap: .cghidEventTap); usleep(80_000); up.post(tap: .cghidEventTap)
