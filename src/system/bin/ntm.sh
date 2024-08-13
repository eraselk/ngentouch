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

    edge="edge_mode_state_title
    pref_edge_handgrip"
    for row in $edge; do
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

    # Enable Touch boost
    write "1" /sys/module/msm_performance/parameters/touchboost
    write "1" /sys/power/pnpmgr/touch_boost
    write "enable 1" /proc/perfmgr/tchbst/user/usrtch
    write "1" /proc/perfmgr/tchbst/kernel/tb_enable
    write "1" /sys/devices/virtual/touch/touch_boost
    write "1" /sys/module/msm_perfmon/parameters/touch_boost_enable

    write "7035" /sys/class/touch/switch/set_touchscreen
    write "8002" /sys/class/touch/switch/set_touchscreen
    write "11000" /sys/class/touch/switch/set_touchscreen
    write "13060" /sys/class/touch/switch/set_touchscreen
    write "14005" /sys/class/touch/switch/set_touchscreen

    # SF Tweaks from HuoTouch
    rr=$(dumpsys SurfaceFlinger | grep refresh-rate | awk '{t=$0;gsub(/.*: |.fps*/,"",t);print t}' | cut -d '.' -f1 | xargs echo)
    _rr=$(echo "scale=7;a=1000/${rr};if(length(a)==scale(a)) print 0;print a" | bc)
    __rr=$(echo "scale=7;a=$_rr*1000000;if(length(a)==scale(a)) print 0;print a" | bc)
    threshold=${__rr%.*}

    resetprop -n debug.sf.phase_offset_threshold_for_next_vsync_ns $threshold

    # InputDispatcher, and InputReader tweaks
    systemserver="$(pidof -s system_server)"
    input_reader="$(ps -ATp "$systemserver" -o tid,cmd | grep 'InputReader' | awk '{print $1}')"
    input_dispatcher="$(ps -ATp "$systemserver" -o tid,cmd | grep 'InputDispatcher' | awk '{print $1}')"

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

        edge="edge_mode_state_title
        pref_edge_handgrip"
        for row in $edge; do
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

Usage: $me --apply|--remove|--help|help|--version|-v

--apply         	Apply touch tweaks [SERVICE MODE]
--remove                Remove NgenTouch module
--help                  Show this message
--version               Show version
-v                      Alias for --version
help                    Alias for --help


Bug or error reports, feature requests, discussions: https://t.me/gudangtoenixzdisc.
EOF
}

version() {
    grep 'version=' /data/adb/modules/ngentouch_module/module.prop | cut -f 2 -d '=' | tr -d 'v'
}

option_list="--apply
    --remove
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
"--help" | "help")
    help_menu
    ;;
"--version" | "-v")
    version
    ;;
*)
    if [ -z "$1" ]; then
        prerr "$me: No option provided
Try: '$me --help' for more information."
        exit 1
    else
        for i in $option_list; do
            if [ "$i" != "$1" ]; then
                valid=false
            fi
        done
        if ! $valid; then
            prerr "$me: Invalid option '$1'. See '$me --help'."
            exit 1
        fi
    fi
    ;;
esac
