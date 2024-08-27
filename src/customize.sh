#!/bin/sh

: '----- Module Installer -----'

SKIPUNZIP=1

ui_print ""
ui_print "   ░█▀█░█▀▀░█▀▀░█▀█░▀█▀░█▀█░█░█░█▀▀░█░█
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
BB_BIN="$(find /data/adb -type f -name busybox | head -n1)"
if [ -n "$BB_BIN" ] && $BB_BIN &>/dev/null; then
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

a="$(settings get global test 2>/dev/null)"
if [ -n "$a" ] && [ "$a" != "null" ] && [ "$a" = "1" ]; then
    ui_print "  Test 2: PASSED"
    test2=true
else
    ui_print "  Test 2: FAILED"
    test2=false
fi

if settings delete global test &>/dev/null; then
    ui_print "  Test 3: PASSED"
    test3=true
else
    ui_print "  Test 3: FAILED"
    test3=false
fi

ui_print ""
if $test1 && $test2 && $test3; then
    ui_print "  Result: all commands work properly"
    normal=true
else
    ui_print "  Result: -"
    normal=false
fi

ui_print ""

$normal || {
    abort "! Not supported"
}

unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'system.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'booster64' -d "$TMPDIR" >&2
unzip -o "$ZIPFILE" 'booster32' -d "$TMPDIR" >&2
mv -f $TMPDIR/module.prop $MODPATH

if cat /proc/cpuinfo | grep "Hardware" | uniq | cut -d ":" -f 2 | grep -q 'Qualcomm'; then
    echo 'persist.vendor.qti.inputopts.movetouchslop=0.1' >>$MODPATH/system.prop
    echo 'persist.vendor.qti.inputopts.enable=true' >>$MODPATH/system.prop
fi

if $BB; then
sed -i "s|BB=|BB=$BB_BIN|g" $MODPATH/system/bin/ntm
fi

set_perm_recursive "$MODPATH" 0 0 0777 0777
