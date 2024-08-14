export CURDIR="$(pwd)"
case "$1" in
"build") $CURDIR/scripts/build.sh ;;
"install") $CURDIR/scripts/install.sh ;;
"test") $CURDIR/scripts/test_ntm.sh "$2"  ;;
*)
echo "Invalid argument"
exit 1 ;;
esac
