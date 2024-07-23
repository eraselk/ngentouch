#!/bin/sh

# ----- Module Installer -----
# (C) gacorpkjrt°

# Flags
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true
dbg=1

mod_print() {

    # Load function
    cmd_pkg() {
        a="cmd package"
        if cmd package "$@" >/dev/null 2>&1; then
            ui_print "[INFO] $a $* : Success"
        else
            ui_print "[ERROR] $a $* : Failed"
        fi
    }
    rm -rf /data/ngentouch

    ui_print ""
    ui_print "░█▀█░█▀▀░█▀▀░█▀█░▀█▀░█▀█░█░█░█▀▀░█░█
░█░█░█░█░█▀▀░█░█░░█░░█░█░█░█░█░░░█▀█
░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀"
    ui_print "_____________________________________________"
    ui_print "   Feel The Responsiveness and Smoothess !  "
    ui_print ""
    sleep 1
    if [ $dbg -ne 1 ]; then
    cmd_pkg compile -m verify -f com.android.systemui
    cmd_pkg compile -m assume-verified -f com.android.systemui --compile-filter=assume-verified -c --reset
    cmd_pkg force-dex-opt com.android.systemui
    cmd_pkg compile -r bg-dexopt -f com.android.systemui
    cmd_pkg compile -m everything -f com.android.systemui
    cmd_pkg compile -r first-boot -f com.android.systemui
    cmd_pkg compile -m everything --secondary-dex -f com.android.systemui
    cmd_pkg compile -r bg-dexopt --check-prof true -f com.android.systemui
    cmd_pkg compile -r bg-dexopt --secondary-dex -f com.android.systemui
    cmd_pkg compile -m everything --check-prof true -f com.android.systemui
    cmd_pkg compile -r shared --secondary-dex -f com.android.systemui
    cmd_pkg compile -r shared --secondary-dex com.android.systemui
    cmd_pkg reconcile-secondary-dex-files com.android.systemui
    fi
    ui_print ""
    ui_print ""
    sleep 1
    
    ui_print "  Testing cmd... (1/3)"
    if settings put global test 1; then
        sleep 0.4
        ui_print "  Normal method: OK"
        normal1=1
    else
        ui_print "  Normal method: ERROR"
        ui_print ""
        sleep 0.2
        ui_print "  Trying another method..."
        sleep 0.2
        if su -lp 2000 -c "settings put global test 1"; then
            ui_print "  Another method: OK"
            another1=1
        else
            ui_print "  Another method: ERROR"
            another1=0
        fi
    fi
    
    ui_print ""
    ui_print "  Testing cmd... (2/3)"
    if settings get global test >/dev/null 2>&1; then
        ui_print "  Normal method: OK"
        normal2=1
    else
        ui_print "  Normal method: ERROR"
        ui_print ""
        sleep 0.2
        ui_print "  Trying another method..."
        sleep 0.2
        if su -lp 2000 -c "settings get global test >/dev/null 2>&1"; then
            ui_print "  Another method: OK"
            another2=1
        else
            ui_print "  Another method: ERROR"
            another2=0
        fi
    fi
    
    ui_print ""
    ui_print " Testing cmd... (3/3)"
    if settings delete global test >/dev/null 2>&1; then
        ui_print " Normal method: OK"
        test_cmd3=1
    else
        ui_print " Normal method: ERROR"
        ui_print ""
        sleep 0.2
        ui_print " Trying another method..."
        sleep 0.2
        if su -lp 2000 -c "settings delete global test >/dev/null 2>&1"; then
            ui_print " Another method: OK"
            another3=1
        else
            ui_print " Another method: ERROR"
            another3=0
        fi
    fi
    
    ui_print ""
    if [ $normal1 -eq 1 ] && [ $normal2 -eq 1 ] && [ $normal3 -eq 1 ]; then
        ui_print " Result: use normal method"
        normal_method=1
    elif [ $another1 -eq 1 ] && [ $another2 -eq 1 ] && [ $another3 -eq 1 ]; then
        ui_print " Result: use another method"
        another_method=1 
    elif [ $another1 -eq 0 ] && [ $another2 -eq 0 ] && [ $another3 -eq 1 ] then
        ui_print " Result: ERROR"
    else
        ui_print " Result: abnormal"
        sleep 1
        ui_print "  using another method instead."
        another_method=1
    fi
    ui_print ""  
}

extract_files() {
    unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
}

perm() {
    set_perm_recursive $MODPATH 0 0 0777 0777
}

apply_method() {
if [ $normal_method -eq 1 ]; then
    sed -i "s/normal_method=0/normal_method=1/g" $MODPATH/system/bin/ntm
elif [ $another_method -eq 1 ]; then
    sed -i "s/another_method=0/another_method=1/g" $MODPATH/system/bin/ntm
fi
}

set -x
mod_print
extract_files
perm
apply_method