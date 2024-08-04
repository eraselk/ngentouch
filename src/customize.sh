#!/bin/sh

: '----- Module Installer -----'

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
	ui_print "   Feel The Responsiveness and Smoothness!  "
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
	sleep 1

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
    
    if settings delete global test >/dev/null; then
        ui_print "  Test 3: PASSED"
        test3=true
    else
        ui_print "  Test 3: FAILED"
        test3=false
    fi
    
    if setenforce 0 || echo -n "0" >/sys/fs/selinux/enforce 2>/dev/null; then
        if [ "$(getenforce)" = "Permissive" ]; then
            ui_print "  Test 4: PASSED"
            test4=true
        else
            ui_print "  Test 4: FAILED"
            test4=false
        fi
    else
        ui_print "  Test 4: FAILED"
        test4=false
    fi
    
	ui_print ""
    if $test1 && $test2 && $test3 && $test4; then
        ui_print "  Result: all commands work properly"
        normal=true
    else
        ui_print "  Result: abnormal, maybe the module won't working.."
        normal=false
    fi
        
	ui_print ""
}

deploy() {
	unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
	unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
    rm -rf \
    $MODPATH/META-INF
}

perm() {
	set_perm_recursive $MODPATH 0 0 0777 0777
}

apply_method() {
	if $normal; then
		sed -i "s/normal=false/normal=true/g" $MODPATH/system/bin/ntm
	fi
}

set -x
mod_print
deploy
perm
apply_method
