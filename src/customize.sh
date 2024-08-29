#!/bin/sh
# shellcheck disable=SC2086
# shellcheck disable=SC2046
# shellcheck disable=SC2034

: '----- Module Installer -----'

SKIPUNZIP=1

ui_print ""
ui_print "░█▀█░█▀▀░█▀▀░█▀█░▀█▀░█▀█░█░█░█▀▀░█░█
░█░█░█░█░█▀▀░█░█░░█░░█░█░█░█░█░░░█▀█
░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀"
ui_print "_____________________________________________"
ui_print "   Feel The Responsiveness and Smoothness!  "
ui_print ""
sleep 1

rm -rf /data/ngentouch

sleep 1

ui_print "- Finding BusyBox Binary..."
sleep 2
BB_BIN=$(
    if $(which busybox) >/dev/null 2>&1; then
        echo $(which busybox)
    else
        __=$(find /data/adb -type f -name busybox)
        if [ -n "$__" ] && $__ >/dev/null 2>&1; then
            echo $__
        fi
    fi
)
if [ -n "$BB_BIN" ]; then
    ui_print "- Found BusyBox Binary: $BB_BIN"
    BB=true
else
    abort "! Cant Find BusyBox Binary!"
fi

ui_print
ui_print "  Testing commands..."

if settings put global test 1 2>/dev/null; then
    ui_print "  Test 1: PASSED"
    test1=true
else
    ui_print "  Test 1: FAILED"
    test1=false
fi

if a=$(settings get global test 2>/dev/null) && [ "$a" = "1" ]; then
    ui_print "  Test 2: PASSED"
    test2=true
else
    ui_print "  Test 2: FAILED"
    test2=false
fi

if settings delete global test >/dev/null 2>&1; then
    ui_print "  Test 3: PASSED"
    test3=true
else
    ui_print "  Test 3: FAILED"
    test3=false
fi

ui_print ""
if $test1 && $test2 && $test3; then
    ui_print "  Result: all commands work properly"
else
    abort "  Result: Not Supported"
fi

ui_print ""

unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'system.prop' -d "$MODPATH" >&2
mv -f $TMPDIR/module.prop $MODPATH

if grep 'Hardware' /proc/cpuinfo | uniq | cut -d ':' -f 2 | tr -d ' ' | grep -q 'Qualcomm'; then
    cat <<EOF >>$MODPATH/system.prop
persist.vendor.qti.inputopts.movetouchslop=0.1
persist.vendor.qti.inputopts.enable=true
EOF
fi

if $BB; then
    sed -i "s|BB=|BB=$BB_BIN|g" $MODPATH/system/bin/ntm
fi

set_perm_recursive "$MODPATH" 0 0 0777 0777
