set -e

if ! env | grep -q 'com.termux'; then
    echo 'WARN: Build using external terminal, maybe zipping not succeded?'
    echo 'Hint: Run as root, if zipping not succeded.'
    echo
    export PATH="/data/data/com.termux/files/usr/bin:${PATH}"
fi

if ! command -v zip >/dev/null 2>&1; then
    echo 'Zip is not installed, negro.'
    echo
    exit 1
fi
cd $(pwd)/src
VER="$(cat ./module.prop | grep 'version=' | cut -f 2 -d '=' | awk '{print $1}')"
build_date=$(date +"%y%m%d")
stamp=$(date +"%H%M%S")
sed -i "s/version=.*/version=$VER.${build_date}${stamp}/g" ./module.prop

######################################
module_name="NgenTouch"
zip_name="${module_name}-${VER}-${build_date}${stamp}.zip"
# 0 = Disable 1 = Enable
remove_bak="1"
#####################################

if [ "$remove_bak" = "1" ]; then
    find . -type f -name '*.bak*' -exec rm -f {} +
fi

dir="$(pwd)/system/bin"
mv -f $dir/ntm.sh $dir/ntm

find .. -maxdepth 1 -type f -name *$module_name* -exec rm -f {} +
zip -r9 "$zip_name" * -x build.sh*
mv -f ./"$zip_name" ..

mv -f $dir/ntm $dir/ntm.sh
sed -i "s/version=.*/version=$VER/g" ./module.prop

cd ..
