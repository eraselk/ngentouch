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
        echo "[INFO] $a $@ : Success" 
    else
        echo "[ERROR] $a $@ : Failed"
    fi
}

[[ -d "/data/ngentouch" ]] && {
rm -rf /data/ngentouch
}

mkdir /data/ngentouch
touch /data/ngentouch/first_boot

ui_print ""
ui_print "░█▀█░█▀▀░█▀▀░█▀█░▀█▀░█▀█░█░█░█▀▀░█░█
░█░█░█░█░█▀▀░█░█░░█░░█░█░█░█░█░░░█▀█
░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀"
ui_print "_____________________________________________"
ui_print "   Feel The Responsiveness and Smoothess !  "
ui_print ""
sleep 1
ui_print "[•] Patching package com.android.systemui"
{
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
}
if [[ $? -eq 0 ]]; then
	ui_print "[√] Done"
else
	ui_print "[!] Failed"
fi
ui_print ""
sleep 1
}

extract_files() {
unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

if [[ "$ARCH" != *arm* ]]; then
ui_print "- Can't install this module for your ARCH"
ui_print "- Your ARCH is: $ARCH"
exit 1
else
unzip -o "$ZIPFILE" 'debugger' -d $MODPATH/system/bin >&2
fi
}

perm() {
set_perm_recursive $MODPATH 0 0 0777 0777
}

set -x
mod_print
extract_files
perm