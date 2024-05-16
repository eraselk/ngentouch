export PATH="/data/data/com.termux/files/usr/bin:${PATH}"
VER="$(cat ./module.prop | grep 'version=' | cut -f 2 -d '=')"
build_date=$(date +"%Y-%m-%d")
stamp=$(date +"%H%M%S")

######################################
module_name="YourModuleName"
zip_name="${module_name}_${VER}_${build_date}_${stamp}.zip"
# 0 = Disable 1 = Enable
remove_bak="1"
#####################################

[[ "$remove_bak" == "1" ]] && {
	find . -type f -name '*.bak*' -exec rm -f {} +
} 
dir="$(pwd)/system/bin"
mv -f $dir/ntm.sh $dir/ntm

find .. -maxdepth 1 -type f -name '*$module_name*' -exec rm -f {} +
zip -r9 "$zip_name" * -x build.sh*
mv -f ./"$zip_name" ..

mv -f $dir/ntm $dir/ntm.sh