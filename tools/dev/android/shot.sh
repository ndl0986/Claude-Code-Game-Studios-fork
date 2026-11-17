#!/bin/zsh
# shot.sh <out_dir> <name> <wait_s> <am extras...>: relaunch the debug app on emulator-5556 (via adbdev) with
# the given intent extras, wait, and screencap to <out_dir>/<name>.png.
A=${0:A:h}/adbdev
D=$1; name=$2; w=$3; shift 3
mkdir -p "$D"
$A shell am force-stop com.galaxyandsun.daidatanhhung
$A shell am start -W -n com.galaxyandsun.daidatanhhung/.GameActivity "$@" >/dev/null
perl -e "select(undef,undef,undef,$w)"
$A exec-out screencap -p > "$D/$name.png"; echo "$name ok"
