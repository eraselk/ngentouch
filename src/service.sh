#!/system/bin/sh
until [ "$(getprop sys.boot_completed)" = "1" ]; do
	sleep 1
done

# exec main script
ntm --apply
