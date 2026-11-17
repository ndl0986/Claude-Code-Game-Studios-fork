#!/bin/zsh
# Polls every 2 s while mp17863 runs. Each poll keeps a snapshot of adb/emulator-related processes.
# When the emulator log shows a shutdown request or the qemu process vanishes, it writes the time and the last two snapshots, then exits.
S=${0:h}; LOG=${EMULOG:-$S/emu.log}; OUT=$S/emu-stop-evidence.txt
prev=""; cur=""
while true; do
  prev=$cur
  cur="$(date '+%F %T')
$(ps -axo pid,ppid,lstart,command | grep -E 'adb|emulator|qemu|avdmanager|emu kill|Simulator' | grep -v grep | cut -c1-220)"
  if grep -q "shutdown gracefully" $LOG 2>/dev/null || ! pgrep -f qemu-system >/dev/null; then
    { echo "=== emulator stop detected at $(date '+%F %T')"
      echo "--- log lines:"; grep -n -i "shutdown gracefully\|removeAll\|console" $LOG | tail -5
      echo "--- snapshot 2 s before:"; echo "$prev"
      echo "--- snapshot at detection:"; echo "$cur"
      echo "--- adb server log tail:"; tail -20 ${TMPDIR:-/tmp}/adb.$(id -u).log 2>/dev/null; } > $OUT
    exit 0
  fi
  sleep 2
done
