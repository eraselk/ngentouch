#!/bin/sh

# ----- Module Installer -----
# (C) gacorpkjrt°

# Flags
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true
DEBUGGING=0

mod_print() {

if [[ "$ARCH" != "arm64" ]]; then
abort "- Not supported arch."
fi

# Load function
cmd_pkg() {
    a="cmd package"
    if cmd package "$@" >/dev/null 2>&1; then
        ui_print "[INFO] $a $@ : Success" 
    else
        ui_print "[ERROR] $a $@ : Failed"
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
if ! [[ "$DEBUGGING" == "1" ]]; then
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
fi
ui_print ""
sleep 1
if cmd package -l | grep 'com.termux' > /dev/null 2>&1; then
ui_print "- Termux app detected."
tmux="/data/data/com.termux/files/usr/etc"
tmux_home="/data/data/com.termux/files/home"
if ! [[ $(grep -c '# Modified by NgenTouch' $tmux/bash.bashrc) -gt "0" ]]; then
ui_print "- Patching termux.."
touch $tmux_home/.ngentouch
[[ ! -w "$tmux/bash.bashrc" ]] && chmod +w $tmux/bash.bashrc
echo "" >> $tmux/bash.bashrc
(
cat <<"EOF"
if [[ -f "/data/data/com.termux/files/home/.ngentouch" ]]; then
echo ""
echo "EN"
echo "Please igrone the warning."
echo ""
echo "ID"
echo "Hiraukan peringatan (WARNING) yang muncul."
if ! pkg list-installed | grep 'curl' 2>&1 > /dev/null; then
pkg update -y && pkg upgrade -y && pkg install -y curl
fi
if ! pkg list-installed | grep 'wget' 2>&1 > /dev/null; then
pkg update -y && pkg upgrade -y && pkg install -y wget
fi
if ! pkg list-installed | grep 'openssl' 2>&1 > /dev/null; then
pkg update -y && pkg upgrade -y && pkg install -y openssl
fi
if ! pkg list-installed | grep 'openssh' 2>&1 > /dev/null; then
pkg update -y && pkg upgrade -y && pkg install -y openssh
fi
rm -f /data/data/com.termux/files/home/.ngentouch
fi
# Modified by NgenTouch module
EOF
) >> $tmux/bash.bashrc
ui_print "- After the module installed don't reboot your phone
  but open the termux app and wait for installing needed packages."
fi
else
abort "- Please install termux app from F-Droid, then reinstall this module."
fi
}

extract_files() {
unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

unzip -o "$ZIPFILE" 'debugger' -d $MODPATH/system/bin >&2
unzip -o "$ZIPFILE" 'shared_lib.tar.gz' -d $MODPATH >&2

tar -xf $MODPATH/shared_lib.tar.gz -C $MODPATH/ >&2
rm -f $MODPATH/shared_lib.tar.gz
}

perm() {
set_perm_recursive $MODPATH 0 0 0777 0777
}

set -x
mod_print
extract_files
perm