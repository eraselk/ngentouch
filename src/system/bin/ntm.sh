#!/system/bin/sh
#
# Free to use.
# You can steal/modify/copy any codes in this script without any credits.
#

# Automatically sets by the installer
BB=

prerr() {
    echo -e "$1\a" >&2
}
    
run() {

    # usage: write <VALUE> <PATH>
    write() {
        if [ -f "$2" ]; then
            if [ ! -w "$2" ]; then
                chmod +w "$2"
            fi
            echo "$1" >"$2"
        fi
    }

    settings put secure multi_press_timeout 300
    settings put secure long_press_timeout 300
    settings put global block_untrusted_touches 0
    settings put system pointer_speed 7

    # Edge Fixer, Special for fog, rain, wind
    # Thanks to @Dahlah_Men
    edge="edge_pressure
    edge_size
    edge_type"
    for row in $edge; do
        settings put system "$row" 0
    done

    edge2="edge_mode_state_title
    pref_edge_handgrip"
    for row in $edge2; do
        settings put global "$row" false
    done

    # Gimmick 696969
    settings put system high_touch_polling_rate_enable 1
    settings put system high_touch_sensitivity_enable 1

    i="/proc/touchpanel"
    write "1" "$i/game_switch_enable"
    write "1" "$i/oppo_tp_direction"
    write "0" "$i/oppo_tp_limit_enable"
    write "0" "$i/oplus_tp_limit_enable"
    write "1" "$i/oplus_tp_direction"

    # bump sampling rate
    find /sys -type f -name bump_sample_rate | while read -r boost_sr; do
        write "1" "$boost_sr"
    done

    write "1" /sys/module/msm_performance/parameters/touchboost
    write "1" /sys/power/pnpmgr/touch_boost
    write "7035" /sys/class/touch/switch/set_touchscreen
    write "8002" /sys/class/touch/switch/set_touchscreen
    write "11000" /sys/class/touch/switch/set_touchscreen
    write "13060" /sys/class/touch/switch/set_touchscreen
    write "14005" /sys/class/touch/switch/set_touchscreen
    write "enable 1" /proc/perfmgr/tchbst/user/usrtch
    write "1" /proc/perfmgr/tchbst/kernel/tb_enable
    write "1" /sys/devices/virtual/touch/touch_boost
    write "1" /sys/module/msm_perfmon/parameters/touch_boost_enable

    # SF Tweaks from HuoTouch
    fps_raw=$(dumpsys SurfaceFlinger | grep refresh-rate | awk '{t=$0;gsub(/.*: |.fps*/,"",t);print t}' | cut -d '.' -f1 | xargs echo)
    fps_a=$(echo "scale=7;a=1000/${fps_raw};if(length(a)==scale(a)) print 0;print a" | bc)
    fps_b=$(echo "scale=7;a=$fps_a*1000000;if(length(a)==scale(a)) print 0;print a" | bc)
    fun_fps=${fps_b%.*}

    resetprop -n debug.sf.phase_offset_threshold_for_next_vsync_ns $fun_fps

    # InputDispatcher, and InputReader tweaks
    systemserver="$(pidof -s system_server)"
    input_reader="$(ps -A -T -p "$systemserver" -o tid,cmd | grep 'InputReader' | awk '{print $1}')"
    input_dispatcher="$(ps -A -T -p "$systemserver" -o tid,cmd | grep 'InputDispatcher' | awk '{print $1}')"

    # Input Reader
    # 24.08.11: Use busybox util-linux
    $BB renice -n -20 -p "$input_reader"
    $BB chrt -f -p 99 "$input_reader"

    # Input Dispatcher
    # 24.08.11: Use busybox util-linux
    $BB renice -n -20 -p "$input_dispatcher"
    $BB chrt -f -p 99 "$input_dispatcher"

    # always return success
    true
}

remove() {
    (
        settings delete system pointer_speed
        settings delete secure multi_press_timeout
        settings delete secure long_press_timeout
        settings delete global block_untrusted_touches

        edge="edge_pressure
        edge_size
        edge_type"
        for row in $edge; do
            settings delete system "$row"
        done

        edge2="edge_mode_state_title
        pref_edge_handgrip"
        for row in $edge2; do
            settings delete global "$row"
        done

        settings delete system high_touch_polling_rate_enable
        settings delete system high_touch_sensitivity_enable

        touch /data/adb/modules/ngentouch_module/remove
    ) &>/dev/null
    echo "Done, please reboot to apply changes."
    exit 0
}

help_menu() {
    cat <<EOF
NgenTouch Module Manager
Version $(grep 'version=' /data/adb/modules/ngentouch_module/module.prop | cut -f 2 -d '=' | tr -d 'v')

Usage: ntm --apply|--remove|--update|--help|help|--version|-v

--apply         	Apply touch tweaks [SERVICE MODE]
--remove                Remove NgenTouch module
--update                Update NgenTouch module [WGET REQUIRED]
--help|help            Show this message
--version|-v        Show version

Bug or error reports, feature requests, discussions: https://t.me/gudangtoenixzdisc.
EOF
}

update_module() {
    # Check if 'com.termux' package and wget are installed
    if ! cmd package -l | grep -q 'com.termux' || ! command -v /data/data/com.termux/files/usr/bin/wget &>/dev/null; then
        echo
        WGET="$BB wget"
        echo "Testing wget..."
        if $WGET --help &>/dev/null; then
            echo "OK"
            echo
        else
            prerr "ERROR: The busybox doesn't have wget applet!\a"
            exit 1
        fi
    else
        WGET="/data/data/com.termux/files/usr/bin/wget"
    fi

    cd /sdcard || prerr "Can't cd into /sdcard!"; exit 1

    # Variables
    MODPATH=/data/adb/modules/ngentouch_module
    MODVER="$(grep 'version=' $MODPATH/module.prop | cut -d '=' -f 2)"
    MODVERCODE="$(grep 'versionCode=' $MODPATH/module.prop | cut -d '=' -f 2)"
    FNAME="ngentouch.zip"

    # Cleanup function
    cleanup() {
        find . -maxdepth 1 -type f -name "$FNAME" -exec rm -f {} +
        find . -maxdepth 1 -type f -name '*latest*' -exec rm -f {} +
    }

    # Clean unnecessary files
    cleanup

    # Check root method
    if command -v ksud &>/dev/null; then
        MGR="ksud"
        ARG="module install"
    elif command -v apd &>/dev/null; then
        MGR="apd"
        ARG="module install"
    elif command -v magisk &>/dev/null; then
        MGR="magisk"
        ARG="--install-module"
    fi

    echo "Checking for update..."
    # Check internet connection
    if ping -c 1 8.8.8.8 &>/dev/null; then
        echo "[ • ] Connected (Fast Connect)"
    else
        prerr "[ ! ] No internet connection"
        exit 1
    fi

    echo

    # Download latest.txt
    BRANCH="main"
    $WGET "https://github.com/eraselk/ngentouch/raw/${BRANCH}/latest.txt" -O latest.txt &>/dev/null

    # Import variables from latest.txt
    if [ -f "latest.txt" ]; then
        source latest.txt
    else
        prerr "Couldn't find file 'latest.txt'"
        echo
        cleanup
        exit 1
    fi

    echo

    VERSION="$VER"
    VERSIONCODE="$VERCODE"
    CL="$CHANGELOG"

    # Check for updates
    if [ "$MODVER" = "$VERSION" ] && [ "$VERSIONCODE" -eq "$MODVERCODE" ]; then
        echo "No update available, you're on the latest version."
        echo
        cleanup
        exit 0
    elif [ "$MODVER" != "$VERSION" ] && [ "$VERSIONCODE" -lt "$MODVERCODE" ]; then
        echo "You're on the Beta version. Please wait for the stable version."
        echo
        cleanup
        exit 0
    elif [ "$MODVER" != "$VERSION" ] && [ "$VERSIONCODE" -gt "$MODVERCODE" ]; then
        echo "New Update available!"
        echo "Version: $VERSION"
        echo
        if [ -n "$CL" ]; then
            echo "--- Changelog ---"
            echo "$CL"
            echo
        fi

        printf "Download and Install? [y/n]"
        printf ": "
        read -r pilihan

        case "$pilihan" in
        y | Y)
            echo
            echo "Downloading the latest module..."
            if $WGET "$LINK" -O "$FNAME" &>/dev/null; then
                echo "Done"
            else
                prerr "Failed."
                cleanup
                exit 1
            fi

            echo
            echo "Installing the module..."
            echo
            if $MGR "$ARG" $FNAME; then
                echo
                cleanup
                echo "Done"
                echo
                printf "Reboot now? [y/n]"
                printf ": "
                read -r choice
                case "$choice" in
                y | Y) reboot ;;
                n | N) exit 0 ;;
                *) prerr "Invalid input, use y or n to answer." && exit 1 ;;
                esac
            else
                echo
                prerr "Failed."
                cleanup
                exit 1
            fi
            ;;
        n | N)
            cleanup
            exit 0
            ;;
        *)
            echo
            prerr "Invalid input, use y or n to answer."
            cleanup
            exit 1
            ;;
        esac
    else
        prerr "----- Abnormal Version Detected -----
Current Version: $MODVER
New Version: $VERSION
Current Version Code: $MODVERCODE
New Version Code: $VERSIONCODE

Please screenshot and report to chat group: @gudangtoenixzdisc
"
        exit 1
    fi
}

version() {
    grep 'version=' /data/adb/modules/ngentouch_module/module.prop | cut -f 2 -d '=' | tr -d 'v'
}

option_list="--apply
    --remove
    --update
    --help
    --version
    -v
    help"

if [ "$(id -u)" -ne 0 ]; then
    prerr "Please run as superuser (SU)"
    exit 1
fi

me="$(basename "$0")"
case "$1" in
"--apply")
    run &>/dev/null
    ;;
"--remove")
    remove
    ;;
"--update")
    update_module
    ;;
"--help" | "help")
    help_menu
    ;;
"--version" | "-v")
    version
    ;;
*)
    if [ -z "$1" ]; then
        prerr "${me}: No option provided
Try: 'ntm --help' for more information."
        exit 1
    else
        for i in $option_list; do
            if [ "$i" = "$1" ]; then
                valid=true
            fi
        done
        if [ "$valid" != true ]; then
            prerr "${me}: Invalid option '$1'. See '${me} --help'."
            exit 1
        fi
    fi
    ;;
esac
