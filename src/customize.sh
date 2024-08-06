#!/bin/sh

: '----- Module Installer -----'

SKIPUNZIP=1

cmd_pkg() {
		a="cmd package"
		if cmd package "$@" &>/dev/null; then
			ui_print "[INFO] $a $* : Success"
		else
			ui_print "[ERROR] $a $* : Failed"
		fi
}

# Debugging Mode: bool
DEBUG=true

	ui_print ""
	ui_print "░█▀█░█▀▀░█▀▀░█▀█░▀█▀░█▀█░█░█░█▀▀░█░█
░█░█░█░█░█▀▀░█░█░░█░░█░█░█░█░█░░░█▀█
░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀"
	ui_print "_____________________________________________"
	ui_print "   Feel The Responsiveness and Smoothness!  "
	ui_print ""
	sleep 1

	rm -rf /data/ngentouch

	if ! $DEBUG; then
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

	if ! $normal; then
		rm -rf $MODPATH
        rm -rf $NVBASE/modules/$MODID
        abort "! Not supported"
	fi
	
    unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
	unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
	unzip -o "$ZIPFILE" 'system.prop' -d "$MODPATH" >&2
	mv -f $TMPDIR/module.prop $MODPATH
	
	case "$ARCH" in
	    "arm64") unzip -o "$ZIPFILE" 'boost64' -d "$MODPATH/system/bin/boost" >&2 ;;
	    "arm") unzip -o "$ZIPFILE" 'boost32' -d "$MODPATH/system/bin/boost" >&2 ;;
	    *)
	        rm -rf $MODPATH
	        rm -rf $NVBASE/modules/$MODID
	        abort "! $ARCH arch is not supported"
	    ;;
    esac

    if cat /proc/cpuinfo | grep "Hardware" | uniq | cut -d ":" -f 2 | grep -q 'Qualcomm'; then
        echo 'persist.vendor.qti.inputopts.movetouchslop=0.1' >>$MODPATH/system.prop
        echo 'persist.vendor.qti.inputopts.enable=true' >>$MODPATH/system.prop
    fi

	set_perm_recursive "$MODPATH" 0 0 0777 0777
