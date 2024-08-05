#!/system/bin/sh
while [ -z "$(getprop sys.boot_completed)" ]; do
	sleep 20
done
ntm --apply
