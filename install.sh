#!/system/bin/sh
# Install from source

su -c "
ABI="$(getprop ro.product.cpu.abi)"

case "$ABI" in
    "arm64-v8a") BIT="64" ;;
    "armeabi-v7a") BIT="32" ;;
esac

KSU="/data/adb/ksu/ksud"
AP="/data/adb/ap/apd"
MAGISK="/data/adb/magisk/magisk$BIT"

if [ -f "$KSU" ]; then
    CMD="$KSU"
    ARG="module install"
elif [ -f "$AP" ]; then
    CMD="$AP"
    ARG="module install"
elif [ -f "$MAGISK" ]; then
    CMD="$MAGISK"
    ARG="--install-module"
fi

# <CMD> <ARG> <ZIP>
find . -maxdepth 1 -type f -name '*.zip' | while read -r arr
    for i in $arr; do
        if [ "$i" = '*NgenTouch*' ]; then
            ZN="$i"
            break
        fi
    done
$CMD $ARG $ZN
"