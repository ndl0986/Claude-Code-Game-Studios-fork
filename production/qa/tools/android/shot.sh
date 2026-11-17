#!/bin/zsh
# shot.sh <delay_s> [out.png]  -> captures, writes downscaled view to scratchpad/v.png
A=~/Android/sdk/platform-tools/adb; S=${0:h}
[ "$1" != 0 ] && $A shell sleep $1
OUT=${2:-$S/s.png}
$A exec-out screencap -p > $OUT
sips -Z 900 $OUT --out $S/v.png >/dev/null
echo saved $OUT
