#!/system/bin/sh
# Install from source

pr_err() {
echo -e "[ERROR] $1\a" >&2
exit 1
}

command -v su &>/dev/null || {
pr_err "SU Binary not found on this environment"
}

su -c "

CMD=
ARG=

if command -v ksud &>/dev/null; then
    CMD='ksud'
    ARG='module install'
elif command -v apd &>/dev/null; then
    CMD='apd'
    ARG='module install'
elif command -v magisk &>/dev/null; then
    CMD='magisk'
    ARG='--install-module'
fi

MODULE_NAME='NgenTouch'
ZIP_FILE=\$(find . -maxdepth 1 -type f -name '*.zip' -exec echo {} \;)

if [ -z \$ZIP_FILE ]; then
    pr_err 'Zip file not found in this directory'
fi

echo 'Installing module: '\$MODULE_NAME
\$CMD \$ARG \$ZIP_FILE
"
