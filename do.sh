export CURDIR="$(pwd)"
me="$(basename "$0")"
me2="$0"

help_usage() {
    echo -ne "\a"
    cat <<EOF
$me - Do something

$me2 build
$me2 install
$me2 test <ARG>

EOF
    exit 1
}

if ! command -v sudo &>/dev/null; then
    (
        yes | pkg update
        yes | pkg install tsu
    ) &>/dev/null
fi

case "$1" in
"build") $CURDIR/scripts/build.sh ;;
"install") sudo $CURDIR/scripts/install.sh ;;
"test") $CURDIR/scripts/test_ntm.sh "$2" ;;
"--help") help_usage ;;
*)

    if [ -z "$1" ]; then
        help_usage
    fi

    cat <<EOF
Invalid argument '$1'
See $me2 --help
EOF
    exit 1
    ;;
esac
