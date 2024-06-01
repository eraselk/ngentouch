#!/system/bin/sh
while [[ -z "$(getprop sys.boot_completed)" ]]; do
	sleep 45
done
ntm --apply
if [[ -f "/data/ngentouch/first_boot" ]]; then
ntm --upload-log
rm -f /data/ngentouch/first_boot
fi