#!/bin/sh
# PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
# Child lock-in on macOS: launches the Release spike with -kiosk 1 (or 0 for the baseline) and posts system
# shortcuts at the HID tap, one at a time. After each it records which app is in front and whether the Spike
# process is still alive. SAFETY: a chord is only posted while Spike is the frontmost app (so a shortcut that
# escapes never reaches another app); lock screen (⌃⌘Q) and log out (⇧⌘Q) are never posted.
#   tools/kiosk-check.sh 1|0
set -u
cd "$(dirname "$0")/.."
K=${1:-1}
OUT=../../production/qa/evidence/TASK-033/lockin; mkdir -p "$OUT"
LOG="$OUT/kiosk-$K.txt"; : > "$LOG"
APP=build/dd/Build/Products/Release/Spike.app/Contents/MacOS/Spike
"$APP" -kiosk "$K" -label "kiosk-$K" >/dev/null 2>&1 &
PID=$!
sleep 4
front() { lsappinfo info -only name "$(lsappinfo front)" | head -1 | sed -n 's/^"\([^"]*\)".*/\1/p'; }
activate() { osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $PID) to true" >/dev/null 2>&1; sleep 1; }
post() { # name keycode mods...
  name=$1; shift
  if ! kill -0 $PID 2>/dev/null; then echo "$name: SKIPPED (Spike not running)" >> "$LOG"; return; fi
  activate
  f=$(front)
  if [ "$f" != "Spike" ]; then echo "$name: SKIPPED (front is '$f', not Spike)" >> "$LOG"; return; fi
  swift tools/post-key.swift "$@" >/dev/null
  sleep 1.5
  screencapture -x "$OUT/kiosk-$K-$(echo "$name" | tr -c 'A-Za-z0-9' '_' | cut -c1-24).png" 2>/dev/null
  after=$(front); alive=$(kill -0 $PID 2>/dev/null && echo yes || echo no)
  verdict=held; [ "$after" != "Spike" ] && verdict=ESCAPED; [ "$alive" = no ] && verdict="ESCAPED (Spike quit)"
  echo "$name: front after='$after' spikeAlive=$alive -> $verdict" >> "$LOG"
  # close any system UI it opened (Spotlight, Force Quit window, Mission Control) before the next test
  # (never into Orca or a terminal: an Esc there could interrupt the session running this test)
  f2=$(front)
  case "$f2" in Orca|Terminal|iTerm2|"") ;; *) swift tools/post-key.swift 53 >/dev/null; sleep 0.5 ;; esac
}
echo "kiosk=$K pid=$PID macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))" >> "$LOG"
screencapture -x "$OUT/kiosk-$K-screen.png" 2>/dev/null
post "Esc"                    53
post "Tab (no modifier)"      48
post "Cmd+Tab app switcher"   48 cmd
post "Cmd+\` next window"     50 cmd
post "Cmd+H hide"             4 cmd
post "Cmd+M minimise"         46 cmd
post "Cmd+W close window"     13 cmd
post "Cmd+Space Spotlight"    49 cmd
post "Cmd+Opt+Esc Force Quit" 53 cmd opt
post "Ctrl+Up Mission Control" 126 ctrl
post "Ctrl+Right next Space"  124 ctrl
post "Cmd+Ctrl+F full screen" 3 cmd ctrl
post "Cmd+Q quit"             12 cmd
post "Ctrl+Opt+Cmd+Q parent exit" 12 cmd opt ctrl
kill $PID 2>/dev/null
cat "$LOG"
