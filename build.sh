set -e

env | grep -q 'com.termux' || {
    echo 'WARN: Build using external terminal, maybe zipping not succeded?'
    echo 'Hint: Run as root, if zipping not succeded.'
    echo
    export PATH="/data/data/com.termux/files/usr/bin:${PATH}"
}

command -v zip &>/dev/null || {
    echo 'Zip is not installed, negro.'
    echo
    exit 1
}

cd $(pwd)/src
VER="$(grep 'version=' ./module.prop | cut -f 2 -d '=' | awk '{print $1}')"
build_date=$(date +"%y%m%d")
stamp=$(date +"%H%M%S")
sed -i "s/version=.*/version=$VER.${build_date}${stamp}/g" ./module.prop

######################################
module_name="NgenTouch"
zip_name="${module_name}-${VER}-${build_date}${stamp}.zip"
# 0 = Disable 1 = Enable
remove_bak=true
#####################################

if $remove_bak; then
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
