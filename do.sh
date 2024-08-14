export CURDIR="$(pwd)"

if ! command -v sudo &>/dev/null; then
(
yes | pkg update
yes | pkg install tsu
) &>/dev/null
fi

case "$1" in
"build") $CURDIR/scripts/build.sh ;;
"install") sudo $CURDIR/scripts/install.sh ;;
"test") $CURDIR/scripts/test_ntm.sh "$2"  ;;
*)
echo "Invalid argument"
exit 1 ;;
esac
