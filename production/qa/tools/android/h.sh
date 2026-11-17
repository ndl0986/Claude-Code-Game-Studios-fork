S=${QCW:?set QCW to the work dir (see README)}
EV=${EV:-${QCREPO:-~/orca/workspaces/Claude-Code-Game-Studios-fork/game-qc-android}/production/qa/evidence/TASK-007/android-qc-r12}
A=~/Android/sdk/platform-tools/adb; P=com.galaxyandsun.daidatanhhung
wt(){ python3 -I $S/wt.py "$1"; }
tap(){ wt "down 0 $1 $2; wait ${3:-0.08}; up 0"; }
shot(){ $A exec-out screencap -p > ${2:-$S/s.png}; sips -Z 900 ${2:-$S/s.png} --out $S/v.png >/dev/null; [ -n "$1" ] && cp ${2:-$S/s.png} $EV/$1.png; true; }
launch(){ $A shell am start -W -n $P/.GameActivity "$@" | grep -E "TotalTime"; }
