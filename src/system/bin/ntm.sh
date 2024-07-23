#!/system/bin/sh
#
# Free to use.
# You can steal/modify/copy any codes in this script without any credits.
#

normal_method=0
another_method=0

# put/edit a row.
# usage: setput <DATABASE> <ROW> <VALUE>
setput() {
	if [ $another_method -eq 1 ]; then
		su -lp 2000 -c "settings put $1 $2 $3" # Experimental
	elif [ $normal_method -eq 1 ]; then
		settings put $1 $2 $3
	fi
}

# get a row value.
# usage: setget <DATABASE> <ROW>
setget() {
	if [ $another_method -eq 1 ]; then
		su -lp 2000 -c "settings get $1 $2" # Experimental
	elif [ $normal_method -eq 1 ]; then
		settings get $1 $2
	fi
}

# delete a row.
# usage: setdel <DATABASE> <ROW>
setdel() {
	if [ $another_method -eq 1 ]; then
		su -lp 2000 -c "settings delete $1 $2" # Experimental
	elif [ $normal_method -eq 1 ]; then
		settings delete $1 $2
	fi
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

	# usage: set_prop <PROPERTY> <VALUE>
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

	# InputDispatcher, InputReader, and Android UI Tweaks
	systemserver="$(pidof -s system_server)"
	input_reader="$(ps -A -T -p $systemserver -o tid,cmd | grep 'InputReader' | awk '{print $1}')"
	input_dispatcher="$(ps -A -T -p $systemserver -o tid,cmd | grep 'InputDispatcher' | awk '{print $1}')"

	# Input Reader
	renice -n -20 -p $input_reader
	chrt -r -p 99 $input_reader

	# Input Dispatcher
	renice -n -20 -p $input_dispatcher
	chrt -r -p 99 $input_dispatcher

	# always return success
	true
}

remove() {
	(
		setdel system pointer_speed
		setdel secure multi_press_timeout
		setdel secure long_press_timeout
		setdel global block_untrusted_touches
		edge="$(settings list system | grep "edge_*" | cut -f1 -d '=')"
		for row in ${edge[@]}; do
			setdel system $row
		done
		setdel system high_touch_polling_rate_enable
		setdel system high_touch_sensitivity_enable
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
	if ! cmd package -l | grep 'com.termux' >/dev/null 2>&1 || ! command -v /data/data/com.termux/files/usr/bin/wget >/dev/null 2>&1; then
		echo "Searching BusyBox binary in /data/adb..."
		BB="$(find /data/adb -type f -name busybox | head -n1)"

		if [ -n "$BB" ]; then
			echo "OK"
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

	# Detect architecture
	ARCH=""
	case "$(getprop ro.product.cpu.abi)" in
	arm64-v8a) ARCH="64" ;;
	armeabi-v7a) ARCH="32" ;;
	esac

	# Declare module version
	MODVER="$(grep 'version=' /data/adb/modules/ngentouch_module/module.prop | cut -d '=' -f 2)"
	MODVERCODE="$(grep 'versionCode=' /data/adb/modules/ngentouch_module/module.prop | cut -d '=' -f 2)"

	# Setup daemon's variables
	KASU="/data/adb/ksu/bin/ksud"
	APCH="/data/adb/ap/bin/apd"
	MAGISK="/data/adb/magisk/magisk${ARCH}"

	# Filename variable - zip name
	FNAME="ngentouch.zip"

	# Cleanup function
	cleanup() {
		find . -maxdepth 1 -type f -name "$FNAME" -exec rm -f {} +
		find . -maxdepth 1 -type f -name '*latest*' -exec rm -f {} +
	}

	# Clean unnecessary files
	cleanup

	# Set up $MGR and $ARG variables
	MGR=""
	ARG=""

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
		[ -n "$CL" ] && echo "--- Changelog ---" && echo "$CL" && echo

		echo -n "Download and Install? [y/n]"
		echo -n ": "
		read -r pilihan

		case "$pilihan" in
		y | Y)
			echo
			echo "Downloading the latest module..."
			$WGET "$LINK" -O "$FNAME" >/dev/null 2>&1 && echo "Done" || {
				echo "Failed."
				cleanup
				exit 1
			}

			echo
			echo "Installing the module..."
			echo
			$MGR $ARG "$FNAME" && {
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
				*) echo "Invalid input, use y/n to answer." && exit 1 ;;
				esac
			} || {
				echo
				echo "Failed."
				cleanup
				exit 1
			}
			;;
		n | N)
			cleanup
			exit 0
			;;
		*)
			echo
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

me="$(basename "$0")"
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
