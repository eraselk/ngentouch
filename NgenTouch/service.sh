#!/system/bin/sh
while [[ -z "$(getprop sys.boot_completed)" ]]; do
	sleep 45
done
ntm --apply