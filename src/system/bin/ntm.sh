#!/system/bin/sh
#
# Free to use.
# You can steal/modify/copy any codes in this script without any credits.
#

normal_method=0
another_method=0

setput() {
    if [ $another_method -eq 1 ]; then
        su -lp 2000 -c "settings put $1 $2 $3" # Experimental
    elif [ $normal_method -eq 1 ]; then
        settings put $1 $2 $3
    fi
}

setget() {
    if [ $another_method -eq 1 ]; then
        su -lp 2000 -c "settings get $1 $2" # Experimental
    elif [ $normal_method -eq 1 ]; then
        settings get $1 $2
    fi
}

run() {

    # Functions that needed by this script.
    write() {
        if [ -f "$2" ]; then
            if [ ! -w "$2" ]; then
                chmod +w "$2"
            fi
            echo "$1" >"$2"
        fi
    }

    set_prop() {
        resetprop -n "$1" "$2"
    }

    ## end

    set_prop ro.input.resampling 1
    set_prop touch.pressure.scale 0.001
    set_prop touch.size.calibration diameter
    set_prop touch.pressure.calibration amplitude
    set_prop touch.size.scale 1
    set_prop touch.size.bias 0
    set_prop touch.size.isSummed 1
    set_prop touch.orientation.calibration none
    set_prop touch.distance.calibration none
    set_prop touch.distance.scale 0
    set_prop touch.coverage.calibration box
    set_prop touch.gestureMode spots
    set_prop ro.surface_flinger.max_frame_buffer_acquired_buffers 3
    set_prop debug.input.normalizetouch true

    if cat /proc/cpuinfo | grep "Hardware" | uniq | cut -d ":" -f 2 | grep 'Qualcomm'; then
        set_prop persist.vendor.qti.inputopts.movetouchslop 0.1
        set_prop persist.vendor.qti.inputopts.enable true
    fi

    setput secure multi_press_timeout 200
    setput secure long_press_timeout 200
    setput global block_untrusted_touches 0
    setput system pointer_speed 7

    edge="$(settings list system | grep "edge_*" | cut -f1 -d '=')"

    for row in ${edge[@]}; do
        setput system $row 0
    done

    # Maybe gimmick
    setput system high_touch_polling_rate_enable 1
    setput system high_touch_sensitivity_enable 1

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

    # Input Dispatcher/Reader
    input_reader_pid=$(ps -A -T -p $(pidof -s system_server) -o tid,cmd | grep 'InputReader' | awk '{print $1}')
    input_dispatcher_pid=$(ps -A -T -p $(pidof -s system_server) -o tid,cmd | grep 'InputDispatcher' | awk '{print $1}')

    renice -n -20 -p $input_reader_pid
    renice -n -20 -p $input_dispatcher_pid

    chrt -f -p 99 $input_reader_pid
    chrt -f -p 99 $input_dispatcher_pid

    # always return success
    true
}

remove() {
    (
        settings delete system pointer_speed
        settings delete secure multi_press_timeout
        settings delete secure long_press_timeout
        settings delete global block_untrusted_touches
        edge="$(settings list system | grep "edge_*" | cut -f1 -d '=')"
        for row in ${edge[@]}; do
            settings delete system $row
        done
        settings delete system high_touch_polling_rate_enable
        settings delete system high_touch_sensitivity_enable
        cmd package compile -m verify -f com.android.systemui
        cmd package compile -m assume-verified -f com.android.systemui --compile-filter=assume-verified -c --reset
        rm -rf /data/dalvik-cache/*
        touch /data/adb/modules/ngentouch_module/remove
    ) >/dev/null 2>&1
    echo "Done, please reboot to apply changes."
    exit 0
}

help_menu() {
    cat <<EOF
NgenTouch Module Manager
Version $(cat /data/adb/modules/ngentouch_module/module.prop | grep 'version=' | cut -f 2 -d '=')

Usage: ntm [OPTION]

--apply         	Apply touch tweaks [SERVICE MODE]
--remove                Remove NgenTouch module
--update                Update NgenTouch module [WGET REQUIRED]
--help, help            Show this message

Bug or error reports, feature requests, discussions: https://t.me/gudangtoenixzdisc.
EOF
}

update_module() {

    if ! cmd package -l | grep 'com.termux' >/dev/null 2>&1 || ! command -v /data/data/com.termux/files/usr/bin/wget >/dev/null 2>&1; then
        echo "Searching BusyBox binary in /data/adb..."
        BB="$(find /data/adb -type f -name busybox | head -n1)"

        if [ -n "$BB" ]; then
            echo "OK"
            echo
            WGET="$BB wget"
            echo "Testing wget..."
            if command -v $WGET >/dev/null 2>&1; then
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

    fi

    if command -v /data/data/com.termux/files/usr/bin/wget >/dev/null 2>&1; then
        WGET="/data/data/com.termux/files/usr/bin/wget"
    fi

    cd /sdcard

    # Detect ARCH
    ARCH=""
    if [ "$(getprop ro.product.cpu.abi)" = "arm64-v8a" ]; then
        ARCH="64"
    fi

    if [ "$(getprop ro.product.cpu.abi)" = "armeabi-v7a" ]; then
        ARCH="32"
    fi

    # Declare module version
    MODVER="$(grep 'version=' /data/adb/modules/ngentouch_module/module.prop | cut -f 2 -d '=')"

    # Declare module versionCode
    MODVERCODE="$(grep 'versionCode=' /data/adb/modules/ngentouch_modules/module.prop | cut -f 2 -d '=')"

    # Setup Daemon's variable
    KASU="/data/adb/ksu/bin/ksud"
    APCH="/data/adb/ap/bin/apd"
    MAGISK="/data/adb/magisk/magisk${ARCH}"

    # FNAME Variable - zip name
    FNAME="ngentouch.zip"

    # Cleanup function
    cleanup() {
        find . -maxdepth 1 -type f -name $FNAME -exec rm -f {} +
        find . -maxdepth 1 -type f -name '*latest*' -exec rm -f {} +
    }

    # Clean unnecessary files
    cleanup

    # Set up $MGR and $ARG variable
    MGR=""
    ARG=""

    # KernelSU
    if [ -f "$KASU" ]; then
        MGR="$KASU"
        ARG="module install"
    fi

    # Apatch
    if [ -f "$APCH" ]; then
        MGR="$APCH"
        ARG="module install"
    fi

    # Magisk
    if [ -f "$MAGISK" ]; then
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

    # Download latest.txt - Important
    $WGET "https://github.com/eraselk/ngentouch/raw/main/latest.txt" >/dev/null 2>&1

    # Import variables from latest.txt
    if [ -f "latest.txt" ]; then
        source latest.txt
    else
        echo
        echo "Couldn't found file 'latest.txt'"
        echo
        cleanup
        exit 1
    fi

    VERSION="$VER"
    CL="$CHANGELOG"
    VERSIONCODE="$VERCODE"

    # $MODVER means the Module's version (strings)
    # $MODVERCODE means the Module's versionCode (number)
    # $VERSION means the module source's version (strings)
    # $VERSIONCODE means the module source's version (number)

    # Check if update is available
    if [ "$MODVER" = "$VERSION" ] && [ "$VERSIONCODE" -eq "$MODVERCODE" ]; then
        echo
        echo "No update available, you're on the latest version."
        cleanup
        exit 0
    elif [ "$MODVER" != "$VERSION" ] && [ "$VERSIONCODE" -lt "$MODVERCODE" ]; then
        echo
        echo "You're on the Beta version. Please wait for the stable version."
        cleanup
        exit 0
    fi

    if [ "$MODVER" != "$VERSION" ] && [ "$VERSIONCODE" -gt "$MODVERCODE" ]; then
        echo
        echo "New Update available!"
        echo "Version: $VERSION"

        if [ -n "$CL" ]; then
            echo
            echo "--- Changelog ---"
            echo "$CL"
        fi

        echo
        echo "Download and Install? [y/n]"
        echo -n ": "
        read -r pilihan

        case "$pilihan" in
        y)
            echo
            echo "Downloading the latest module..."
            echo

            $WGET "$LINK" -O "$FNAME" >/dev/null 2>&1 && {
                echo "Done"
            } || {
                echo "Failed."
                echo "Report this error to @gudangtoenixzdisc"
                echo
                cleanup
                exit 1
            }

            echo
            echo "Installing the module..."
            echo

            $MGR $ARG "$FNAME" && {
                echo
                echo "Cleaning..."
                cleanup
                echo "Done"

                echo
                echo "Reboot now? [y/n]"
                echo -n ": "
                read -r choice

                case "$choice" in
                y)
                    reboot
                    ;;
                n)
                    exit 0
                    ;;
                *)
                    echo "Invalid input, use y/n to answer." && exit 1
                    ;;
                esac
            } || {
                echo
                echo "Failed."
                echo "Report this error to @gudangtoenixzdisc"
                echo
                cleanup
                exit 1
            }
            ;;
        n)
            cleanup
            exit 0
            ;;
        *)
            echo "Invalid input, use y/n to answer."
            cleanup
            exit 1
            ;;
        esac
    fi
}

option_list=(
    "--apply"
    "--remove"
    "--update"
    "--help"
    "help"
)

if ! [ $(id -u) -eq 0 ]; then
    echo "Please run as superuser (SU)"
    exit 1
fi

case "$1" in
"--apply")
    run >/dev/null 2>&1
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
        echo "No option provided
Try: 'ntm --help' for more information."
        exit 1
    else
        for i in "${option_list[@]}"; do
            if [ "$i" = "$1" ]; then
                valid=true
            fi
        done
        if [ "$valid" != true ]; then
            script_name=$(basename "$0")
            echo "${script_name}: Invalid option '$1'. See '${script_name} --help'."
            exit 1
        fi
    fi
    ;;
esac
