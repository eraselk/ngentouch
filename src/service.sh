#!/system/bin/sh
while [ -z "$(getprop sys.boot_completed)" ]; do
	sleep 15
done

# exec main script
ntm --apply
