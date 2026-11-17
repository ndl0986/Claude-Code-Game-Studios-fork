# tt <case-name> '<fastmt script>'  -> runs it under getevent, appends kernel timing to $EV/input-timing.txt, screenshot $EV/<case>.png
tt(){ local n=$1; $A shell "getevent -lt /dev/input/event1" > $S/ge_$n.txt 2>&1 &
  sleep 0.8; python3 -I $S/fastmt.py "$2"; sleep ${3:-1.2}; $A shell pkill getevent >/dev/null 2>&1; sleep 0.3
  python3 -I - "$S/ge_$n.txt" "$n" "$2" >> $EV/input-timing.txt <<'PY'
import re, sys
ev=[]; slot=0
for l in open(sys.argv[1]):
    m=re.match(r'\[\s*([\d.]+)\]\s+EV_ABS\s+(ABS_MT_SLOT|ABS_MT_TRACKING_ID)\s+([0-9a-f]+)', l)
    if not m: continue
    t,k,v=float(m.group(1)),m.group(2),int(m.group(3),16)
    if k=='ABS_MT_SLOT': slot=v; continue
    ev.append((t,'up' if v==0xffffffff else 'down',slot))
t0=ev[0][0] if ev else 0
print(f"{sys.argv[2]}: script='{sys.argv[3][:100]}…' kernel: " + ', '.join(f"{e[1]}{e[2]}@{e[0]-t0:.3f}" for e in ev))
PY
  tail -1 $EV/input-timing.txt; shot $n; }
