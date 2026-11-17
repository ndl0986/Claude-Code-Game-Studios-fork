# dj <name> "<am extras>" <ntaps> [x y] [reclimit] : debug-jump, record, mash every 0.35 s, then a deliberate tap 0.6 s after; pull <name>.mp4
dj(){ local n=$1 ex=$2 nt=$3 x=${4:-1112} y=${5:-628}
  $A shell am force-stop $P; sleep 0.5; eval launch $ex; sleep 2.5; shot $n-entry
  $A shell "screenrecord --bit-rate 4000000 --time-limit ${6:-30} /sdcard/$n.mp4" & sleep 1.5
  tt $n "$(python3 $S/mash.py $x $y $nt) ; wait 0.6; down 0 $x $y; wait 0.06; up 0" 2.0
  $A shell pkill -INT screenrecord; wait; sleep 0.5; $A pull /sdcard/$n.mp4 $S/$n.mp4 >/dev/null; uptime; }
