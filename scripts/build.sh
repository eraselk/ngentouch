#!/data/data/com.termux/files/usr/bin/bash
set -e

pr_err() {
    printf "[ERROR] %s\a\n" "$1" >&2
    exit 1
}

pr_warn() {
    printf "[WARN] %s\n" "$1"
}

env | grep -q 'com.termux' || {
    pr_warn "Build using external terminal, maybe zipping not succeded?"
    echo 'Hint: Run as root, if zipping not succeded.'
    echo
    export PATH="/data/data/com.termux/files/usr/bin:${PATH}"
}

command -v zip &>/dev/null || {
    pr_warn "Zip is not installed"
    sleep 1
    echo "Installing zip..."
    if ping -c 1 8.8.8.8 &>/dev/null; then
        (
        yes | apt update
        yes | apt upgrade
        apt install zip -y
        ) &>/dev/null
        echo "Done"
    else
        pr_err "No internet connection!"
        sleep 1
        exit 1
    fi
}

module_name="NgenTouch"
build_date=$(date +"%y%m%d")
time_stamp=$(date +"%H%M")
remove_bak=true

cd $CURDIR/src || pr_err "Can't cd into $CURDIR/src"

VER="$(grep 'version=' ./module.prop | cut -f 2 -d '=')"
zip_name="${module_name}-${VER}-${build_date}${time_stamp}.zip"

sed -i "s/version=.*/version=$VER.${build_date}${time_stamp}/g" ./module.prop

if $remove_bak; then
    find . -type f -name '*.bak' -exec rm -f {} +
fi

bin="$CURDIR/src/system/bin"

mv -f $bin/ntm.sh $bin/ntm

find $CURDIR -maxdepth 1 -type f -name *$module_name* -exec rm -f {} +
zip -r9 "$zip_name" *
mv -f ./"$zip_name" ..

mv -f $bin/ntm $bin/ntm.sh
sed -i "s/version=.*/version=$VER/g" ./module.prop

cd $CURDIR/src/.. || pr_err "Can't cd into $CURDIR/src/.."
