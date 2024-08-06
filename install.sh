#!/system/bin/sh
# Install from source

if ! command -v su &>/dev/null; then
echo "Are you root user??" >&2
exit 1
fi

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
    echo 'Error: Module ZIP file not found.'
    exit 1
fi

echo 'Installing module: '\$MODULE_NAME
\$CMD \$ARG \$ZIP_FILE
"
