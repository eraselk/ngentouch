#!/bin/sh
#
# Free to use.
# You can steal/modify/copy any codes in this script without any credits.
#

run() {

set -x

# Functions that needed by this script.
write() {
    if [[ -f "$2" ]]; then
    	echo "$2 Exists"
        if [[ ! -w "$2" ]]; then
            chmod +w "$2"
        fi
        echo "$1" > "$2"
    else
     	echo "$2 does not exists"
    fi
}

setput() {
    db="$1"
    row="$2"
    value="$3"
    
settings put "$db" "$row" "$value"
}

ps_ret="$(ps -Ao pid,args)"

change_thread_nice() {
 for temp_pid in $(echo "$ps_ret" | grep -i -E "$1" | awk '{print $1}'); do
  for temp_tid in $(ls "/proc/$temp_pid/task/"); do
   comm="$(cat "/proc/$temp_pid/task/$temp_tid/comm")"
   [[ "$(echo "$comm" | grep -i -E "$2")" != "" ]] && {
    renice -n +40 -p "$temp_tid"
    renice -n -19 -p "$temp_tid"
    renice -n "$3" -p "$temp_tid"
   }
  done
 done
}

change_thread_cgroup() {
	for temp_pid in $(echo "$ps_ret" | grep -i -E "$1" | awk '{print $1}'); do
		for temp_tid in $(ls "/proc/$temp_pid/task/"); do
			comm="$(cat "/proc/$temp_pid/task/$temp_tid/comm")"
			[[ "$(echo "$comm" | grep -i -E "$2")" != "" ]] && echo "$temp_tid" >"/dev/$4/$3/tasks"
		done
	done
}

change_task_cgroup() {
	for temp_pid in $(echo "$ps_ret" | grep -i -E "$1" | awk '{print $1}'); do
		for temp_tid in $(ls "/proc/$temp_pid/task/"); do
			comm="$(cat "/proc/$temp_pid/task/$temp_tid/comm")"
			echo "$temp_tid" >"/dev/$3/$2/tasks"
		done
	done
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

	if cat /proc/cpuinfo | grep "Hardware" | uniq | cut -d ":" -f 2 | grep 'Qualcomm' 2>&1 >/dev/null; then
    	set_prop persist.vendor.qti.inputopts.movetouchslop 0.1
    	set_prop persist.vendor.qti.inputopts.enable true
	fi

setput secure multi_press_timeout 200
setput secure long_press_timeout 200
setput global block_untrusted_touches 0
setput system pointer_speed 7

i="/proc/touchpanel"
write "1" "$i/game_switch_enable"
write "1" "$i/oppo_tp_direction"
write "0" "$i/oppo_tp_limit_enable"
write "0" "$i/oplus_tp_limit_enable"
write "1" "$i/oplus_tp_direction"

# bump sampling rate
for boost_sr in "$(find /sys -type f -name bump_sample_rate)"; do
	if [[ -n "$boost_sr" ]]; then
	    echo "$boost_sr"
    for boosts in ${boost_sr[@]}; do
		write "1" "$boosts"
    done
	else
		echo "can't apply boost_sr"
	fi
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

# Input Dispatcher/Reader
change_thread_nice "system_server" "InputReader" "-20"
change_thread_nice "system_server" "InputDispatcher" "-20"

change_thread_cgroup "system_server" "InputReader" "top-app" "cpuset"
change_thread_cgroup "system_server" "InputReader" "foreground" "stune"

change_thread_cgroup "system_server" "InputDispatcher" "top-app" "cpuset"
change_thread_cgroup "system_server" "InputDispatcher" "foreground" "stune"
}

remove() {
  (
    settings put system pointer_speed -7
    settings delete secure multi_press_timeout
    settings delete secure long_press_timeout
    settings delete global block_untrusted_touches
    cmd package compile -m verify -f com.android.systemui
	cmd package compile -m assume-verified -f com.android.systemui --compile-filter=assume-verified -c --reset
	rm -rf /data/dalvik-cache/*
	rm -rf /data/ngentouch
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
--update-module         Update NgenTouch module [WGET REQUIRED]
--upload-log		Upload log to developer [CURL REQUIRED]
--help, help            Show this message

Bug or error reports, feature requests, discussions: https://t.me/gudangtoenixzdisc.
EOF
}

update_module() {

# Check if Termux app is installed
if [[ ! -d "/data/data/com.termux" ]]; then
	echo "Termux app required" && exit 1
fi

# Detect ARCH
ARCH=""
if [[ "$(getprop ro.product.cpu.abi)" == "arm64-v8a" ]]; then
	ARCH="64"
fi

if [[ "$(getprop ro.product.cpu.abi)" == "armeabi-v7a" ]]; then 
	ARCH="32"
fi

# Change directory to home dir
cd /data/data/com.termux/files/home

# Export Termux's binary path
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

# Check if wget is installed
if ! command -v wget > /dev/null 2>&1; then
    echo "Hint: pkg install -y wget openssl openssh" && exit 1
fi

# Declare module version
MODVER="$(grep 'version=' /data/adb/modules/ngentouch_module/module.prop | cut -f 2 -d '=')"

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
if [[ -f "$KASU" ]]; then 
	MGR="$KASU"
	ARG="module install"
fi

# Apatch
if [[ -f "$APCH" ]]; then
	MGR="$APCH"
	ARG="module install"
fi

# Magisk
if [[ -f "$MAGISK" ]]; then 
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
echo ""

# Download latest.txt - Important
wget -nv "https://github.com/eraselk/ngentouch/raw/main/latest.txt"
[[ "$?" -gt "0" ]] && {
	echo ""
	echo "Failed."
	echo "Try: pkg install -y openssl openssh"
	echo "Not solved?, report to @gudangtoenixzdisc."
	echo ""
	cleanup
	exit 1
}

# Import variables from latest.txt
if [[ -f "./latest.txt" ]]; then
	source "$(pwd)/latest.txt" > /dev/null 2>&1
else
	echo ""
	echo "Couldn't found file 'latest.txt'"
	echo ""
	cleanup
	exit 1
fi

VERSION="$VER"
CL="$CHANGELOG"

# Check if update is available
if [[ "$MODVER" == "$VERSION" ]]; then
	echo ""
    echo "No update available, you're on the latest version."
    cleanup
    exit 0
fi

echo ""
echo "New Update available!"
echo "Version: $VERSION"

if [[ -n "$CL" ]]; then
	echo ""
	echo "--- Changelog ---"
	echo "$CL"
fi

echo ""
echo "Download and Install? [y/n]"
echo -n ": "; read -r pilihan

case "$pilihan" in
 y)
    echo ""
    echo "Downloading the latest module..."
    echo ""
    
    wget -nv "$LINK" -O "$FNAME"
    [[ "$?" -eq "0" ]] && {
    echo ""
    echo "Done"
    } || {
    echo ""
    echo "Failed."
    echo "Report this error to @gudangtoenixzdisc"
    echo ""
    cleanup
    exit 1
    }

    echo ""
    echo "Installing the module..."
    echo ""

    $MGR $ARG "$FNAME"
    [[ "$?" -eq "0" ]] && {
      echo ""
      echo "Cleaning..."
      cleanup
      echo "Done"

      echo ""
      echo "Reboot now? [y/n]"
      echo -n ": "; read -r choice

      case "$choice" in
        y)
            reboot ;;
        n)
            exit 0 ;;
        *)
            echo "Invalid input, use y/n to answer." && exit 1 ;;
      esac
    } || {
      echo ""
      echo "Failed."
      echo "Report this error to @gudangtoenixzdisc"
      echo ""
      cleanup
      exit 1
    }
    ;;
 n)
     cleanup
     exit 0 ;;
 *)
     echo "Invalid input, use y/n to answer."
     cleanup
     exit 1 ;;
esac
}

upload_log() {
if ! [[ -d "/data/data/com.termux" ]]; then
	echo "Termux app required."
	exit 1
fi

export PATH="/data/data/com.termux/files/usr/bin:$PATH"

if ! which curl > /dev/null 2>&1; then
	echo "Operation aborted."
	echo "Hint: pkg install -y curl openssl openssh"
	exit 1
fi

debugger

[ "$?" -eq "0" ] && {
echo "Done"
}
}

option_list=(
"--apply"
"--remove"
"--update-module"
"--upload-log"
"--help"
"help"
)

if [[ "$(whoami)" != "root" ]]; then
echo "Please run as superuser (SU)"
exit 1
fi

case "$1" in
  "--apply")
    run > /data/ngentouch/ngentouch.log 2>&1
    ;;
  "--remove")
    remove
    ;;
  "--update-module")
    update_module
    ;;
  "--help"|"help")
    help_menu
    ;;
  "--upload-log")
  	upload_log
    ;;
  *)
    if [[ -z "$1" ]]; then
      echo "No option provided
Try: 'ntm --help' for more information."
      exit 1
    else
      for i in "${option_list[@]}"; do
        if [[ "$i" == "$1" ]] ; then
          valid=true
        fi
      done
      if [[ "$valid" != true ]] ; then
  		script_name=$(basename "$0")
  		echo "${script_name}: Invalid option '$1'. See '${script_name} --help'."
  		exit 1
      fi
    fi
    ;;
esac