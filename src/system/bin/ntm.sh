#!/system/bin/sh
#
# Free to use.
# You can steal/modify/copy any codes in this script without any credits.
#

normal=false

run() {
    set -x

    # Backup SELinux mode
    if $normal; then
        case "$(cat /sys/fs/selinux/enforce 2>/dev/null || getenforce 2>/dev/null)" in
        "0") permissive=true ;;
        "1") permissive=false ;;
        "Permissive") permissive=true ;;
        "Enforcing") permissive=false ;;
        esac
    fi

    if $normal && ! $permissive; then
        setenforce 0 || echo -n "0" >/sys/fs/selinux/enforce
    fi

    # usage: write <VALUE> <PATH>
    write() {
        if [ -f "$2" ]; then
            if [ ! -w "$2" ]; then
                chmod +w "$2"
            fi
            echo "$1" >"$2"
        fi
    }

    settings put secure multi_press_timeout 200
    settings put secure long_press_timeout 200
    settings put global block_untrusted_touches 0
    settings put system pointer_speed 7

    # Edge Fixer, Special for fog, rain, wind
    # Thanks to @Dahlah_Men
    edge=("edge_pressure" "edge_size" "edge_type")
    for row in ${edge[@]}; do
        settings put system $row 0
    done

    edge2=("edge_mode_state_title" "pref_edge_handgrip")
    for row in ${edge2[@]}; do
        settings put global $row false
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
        for boosts in ${boost_sr[@]}; do
            write "1" "$boosts"
        done
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

    # InputDispatcher, and InputReader tweaks
    systemserver="$(pidof -s system_server)"
    input_reader="$(ps -A -T -p $systemserver -o tid,cmd | grep 'InputReader' | awk '{print $1}')"
    input_dispatcher="$(ps -A -T -p $systemserver -o tid,cmd | grep 'InputDispatcher' | awk '{print $1}')"

    # Input Reader
    renice -n -20 -p $input_reader
    chrt -r -p 99 $input_reader

    # Input Dispatcher
    renice -n -20 -p $input_dispatcher
    chrt -r -p 99 $input_dispatcher

    # change back selinux mode
    if $normal && ! $permissive; then
        setenforce 1 || echo -n "1" >/sys/fs/selinux/enforce
    fi

    # always return success
    true
}

remove() {
    (
        # Backup SELinux mode
        if $normal; then
            case "$(cat /sys/fs/selinux/enforce 2>/dev/null || getenforce 2>/dev/null)" in
            "0") permissive=true ;;
            "1") permissive=false ;;
            "Permissive") permissive=true ;;
            "Enforcing") permissive=false ;;
            esac
        fi

        if $normal && ! $permissive; then
            setenforce 0 || echo -n "0" >/sys/fs/selinux/enforce
        fi

        settings delete system pointer_speed
        settings delete secure multi_press_timeout
        settings delete secure long_press_timeout
        settings delete global block_untrusted_touches

        edge=("edge_pressure" "edge_size" "edge_type")
        for row in ${edge[@]}; do
            settings delete system $row
        done

        edge2=("edge_mode_state_title" "pref_edge_handgrip")
        for row in ${edge2[@]}; do
            settings delete global $row
        done

        settings delete system high_touch_polling_rate_enable
        settings delete system high_touch_sensitivity_enable
        cmd package compile -m verify -f com.android.systemui
        cmd package compile -m assume-verified -f com.android.systemui --compile-filter=assume-verified -c --reset
        rm -rf /data/dalvik-cache/*
        touch /data/adb/modules/ngentouch_module/remove

        if $normal && ! $permissive; then
            setenforce 1 || echo -n "1" >/sys/fs/selinux/enforce
        fi

    ) >/dev/null 2>&1
    echo "Done, please reboot to apply changes."
    exit 0
}

help_menu() {
    cat <<EOF
NgenTouch Module Manager
Version $(cat /data/adb/modules/ngentouch_module/module.prop | grep 'version=' | cut -f 2 -d '=' | sed 's/v//g')

Usage: ntm [OPTION]

--apply         	Apply touch tweaks [SERVICE MODE]
--remove                Remove NgenTouch module
--update                Update NgenTouch module [WGET REQUIRED]
--help, help            Show this message

Bug or error reports, feature requests, discussions: https://t.me/gudangtoenixzdisc.
EOF
}

update_module() {
    # Check if 'com.termux' package and wget are installed
    if ! cmd package -l | grep -q 'com.termux' || ! command -v /data/data/com.termux/files/usr/bin/wget >/dev/null 2>&1; then
        echo "Searching BusyBox binary in /data/adb..."
        BB="$(find /data/adb -type f -name busybox | head -n1)"

        if [ -n "$BB" ]; then
            echo "Found BB: $BB"
            echo
            WGET="$BB wget"
            echo "Testing wget..."
            if $WGET --help >/dev/null 2>&1; then
                echo "OK"
                echo
            else
                echo "ERROR: The busybox doesn't have wget applet!"
                exit 1
            fi
        else
            echo "ERROR: Can't find busybox binary!"
            exit 1
        fi
    else
        WGET="/data/data/com.termux/files/usr/bin/wget"
    fi

    cd /sdcard

    # Variables
    MODPATH=/data/adb/modules/ngentouch_module
    MODVER="$(grep 'version=' $MODPATH/module.prop | cut -d '=' -f 2)"
    MODVERCODE="$(grep 'versionCode=' $MODPATH/module.prop | cut -d '=' -f 2)"

    case "$(getprop ro.product.cpu.abi)" in
    arm64-v8a) ARCH="64" ;;
    armeabi-v7a) ARCH="32" ;;
    esac

    KASU="/data/adb/ksu/bin/ksud"
    APCH="/data/adb/ap/bin/apd"
    MAGISK="/data/adb/magisk/magisk$ARCH"
    FNAME="ngentouch.zip"

    # Cleanup function
    cleanup() {
        find . -maxdepth 1 -type f -name "$FNAME" -exec rm -f {} +
        find . -maxdepth 1 -type f -name '*latest*' -exec rm -f {} +
    }

    # Clean unnecessary files
    cleanup

    # Set up MGR and ARG variables
    if [ -f "$KASU" ]; then
        MGR="$KASU"
        ARG="module install"
    elif [ -f "$APCH" ]; then
        MGR="$APCH"
        ARG="module install"
    elif [ -f "$MAGISK" ]; then
        MGR="$MAGISK"
        ARG="--install-module"
    fi

    echo "Checking for update..."
    # Check internet connection
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "[ • ] Connected (Fast Connect)"
    else
        echo "[ ! ] No internet connection"
        exit 1
    fi

    echo

    # Download latest.txt
    $WGET "https://github.com/eraselk/ngentouch/raw/main/latest.txt" -O latest.txt >/dev/null 2>&1

    # Import variables from latest.txt
    if [ -f "latest.txt" ]; then
        source latest.txt
    else
        echo "Couldn't find file 'latest.txt'"
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

        echo -n "Download and Install? [y/n]"
        echo -n ": "
        read -r pilihan

        case "$pilihan" in
        y | Y)
            echo
            echo "Downloading the latest module..."
            if $WGET "$LINK" -O "$FNAME" >/dev/null 2>&1; then
                echo "Done"
            else
                echo "Failed."
                cleanup
                exit 1
            fi

            echo
            echo "Installing the module..."
            echo
            if $MGR $ARG $FNAME; then
                echo
                cleanup
                echo "Done"
                echo
                echo -n "Reboot now? [y/n]"
                echo -n ": "
                read -r choice
                case "$choice" in
                y | Y) reboot ;;
                n | N) exit 0 ;;
                *) echo "Invalid input, use y or n to answer." && exit 1 ;;
                esac
            else
                echo
                echo "Failed."
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
            echo "Invalid input, use y or n to answer."
            cleanup
            exit 1
            ;;
        esac
    else
        echo "----- Abnormal Version Detected -----"
        echo "Current Version: $MODVER"
        echo "New Version: $VERSION"
        echo "Current Version Code: $MODVERCODE"
        echo "New Version Code: $VERSIONCODE"
        echo
        echo "Please screenshot and report to chat group: @gudangtoenixzdisc"
        echo
        exit 1
    fi
}

option_list=(
    "--apply"
    "--remove"
    "--update"
    "--help"
    "help"
)

if [ $(id -u) -ne 0 ]; then
    echo "Please run as superuser (SU)"
    exit 1
fi

me="$(basename "$0")"
case "$1" in
"--apply")
    run >/sdcard/ngentouch.log 2>&1
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
*)
    if [ -z "$1" ]; then
        echo "${me}: No option provided
Try: 'ntm --help' for more information."
        exit 1
    else
        for i in "${option_list[@]}"; do
            if [ "$i" = "$1" ]; then
                valid=true
            fi
        done
        if [ "$valid" != true ]; then
            echo "${me}: Invalid option '$1'. See '${me} --help'."
            exit 1
        fi
    fi
    ;;
esac
