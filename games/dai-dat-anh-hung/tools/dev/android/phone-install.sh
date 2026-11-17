#!/bin/zsh
# phone-install.sh <serial> [--no-install]: build the D-37 preview APK (release-like, signed with a local key) and
# install it on a real phone with `adb -s <serial> install -r`. Refuses emulator serials (5554 is game-qc-android's,
# 5556 is game-dev-android's). The first run creates the local key in ~/.config/daidatanhhung (outside git).
set -euo pipefail
serial=${1:-}; mode=${2:-}
if [[ -z "$serial" ]]; then echo "usage: phone-install.sh <serial from 'adb devices'> [--no-install]" >&2; exit 2; fi
if [[ "$serial" == emulator-* ]]; then echo "phone-install: $serial is an emulator; this script is for a real phone" >&2; exit 2; fi
ROOT=${0:A:h:h:h:h}; ADB=~/Android/sdk/platform-tools/adb
KEYDIR=~/.config/daidatanhhung; PROPS=$KEYDIR/preview.properties; STORE=$KEYDIR/preview.jks
export JAVA_HOME=${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}
if [[ ! -f $PROPS ]]; then
  echo "phone-install: creating the local preview key in $KEYDIR (keep it; it signs every preview update)"
  mkdir -p $KEYDIR; chmod 700 $KEYDIR
  pass=$(openssl rand -hex 16)
  $JAVA_HOME/bin/keytool -genkeypair -v -keystore $STORE -storetype PKCS12 -alias preview -keyalg RSA -keysize 3072 \
    -validity 10000 -storepass "$pass" -keypass "$pass" -dname "CN=Dai Dat Anh Hung preview, O=local" >/dev/null 2>&1
  umask 077; printf 'storeFile=%s\nstorePassword=%s\nkeyAlias=preview\nkeyPassword=%s\n' "$STORE" "$pass" "$pass" > $PROPS
  chmod 600 $PROPS $STORE
fi
(cd $ROOT/android && nice -n 10 ./gradlew -q assemblePreview)
APK=$ROOT/android/app/build/outputs/apk/preview/app-preview.apk
[[ -f $APK ]] || { echo "phone-install: no APK at $APK" >&2; exit 1; }
echo "APK (for sideloading): $APK"
shasum -a 256 $APK
[[ "$mode" == --no-install ]] && exit 0
$ADB -s "$serial" install -r "$APK"
$ADB -s "$serial" shell am start -n com.galaxyandsun.daidatanhhung.preview/com.galaxyandsun.daidatanhhung.GameActivity >/dev/null
echo "installed and launched on $serial"
