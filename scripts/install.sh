#!/system/bin/sh
# Install from source

pr_err() {
    printf "[ERROR] %s\a\n" "$1" >&2
    exit 1
}

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
ZIP_FILE="$(find $CURDIR -maxdepth 1 -type f -name '*.zip' -exec echo {} \;)"

if [ -z "$ZIP_FILE" ]; then
    pr_err 'Zip file not found in this directory'
fi

echo "Installing module: $MODULE_NAME"
$CMD $ARG $ZIP_FILE
