#!/bin/sh

# ----- Module Installer -----
# (C) gacorpkjrt°

# Flags
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

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
    cmd_pkg compile -m verify -f com.android.systemui
    cmd_pkg compile -m assume-verified -f com.android.systemui --compile-filter=assume-verified -c --reset
    sleep 5
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
    ui_print ""
    ui_print ""
    sleep 1
}

extract_files() {
    unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
}

perm() {
    set_perm_recursive $MODPATH 0 0 0777 0777
}

set -x
mod_print
extract_files
perm
