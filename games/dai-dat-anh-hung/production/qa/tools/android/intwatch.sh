#!/bin/zsh
# Interference watcher for mp17863 (emulator-5554). Every 2 s: host processes whose argv has adb/monkey/uiautomator/sendevent/input,
# each with its parent chain (pid:comm up to 4 levels), appended with a timestamp to intwatch-ps.txt (only when the set changes).
S=${0:h}; OUT=$S/intwatch-ps.txt; last=""
chain(){ local p=$1 s=""; for i in 1 2 3 4; do local l=$(ps -o ppid=,comm= -p $p 2>/dev/null); [ -z "$l" ] && break; s="$s <- $p:${${l#* }##*/}"; p=${l%% *}; p=${p// /}; done; echo "$s"; }
while true; do
  cur=$(ps -axo pid=,command= | grep -E "adb|monkey|uiautomator|sendevent|input (tap|swipe|keyevent)" | grep -v -E "grep|intwatch|logcat -v threadtime|logcat -b events|fork-server" | while read pid cmd; do echo "$pid ${cmd[1,160]} | $(chain $pid)"; done)
  if [ "$cur" != "$last" ]; then { echo "== $(date '+%T')"; echo "$cur"; } >> $OUT; last=$cur; fi
  sleep 2
done
