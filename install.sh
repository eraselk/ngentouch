#!/system/bin/sh
# Install from source

su -c "
ABI=\$(getprop ro.product.cpu.abi)

case \$ABI in
    arm64-v8a) BIT=64 ;;
    armeabi-v7a) BIT=32 ;;
esac

KSU=/data/adb/ksu/ksud
AP=/data/adb/ap/apd
MAGISK=/data/adb/magisk/magisk\$BIT

CMD=
ARG=

if [ -f \$KSU ]; then
    CMD=\$KSU
    ARG='module install'
elif [ -f \$AP ]; then
    CMD=\$AP
    ARG='module install'
elif [ -f \$MAGISK ]; then
    CMD=\$MAGISK
    ARG='--install-module'
fi

if [ -z \$CMD ]; then
    echo 'Error: No supported installation tool found.'
    exit 1
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
