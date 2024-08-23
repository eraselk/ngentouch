#!/data/data/com.termux/files/usr/bin/bash
export CURDIR="$(pwd)"
me="$(basename "$0")"
me2="$0"

help_usage() {
printf "%s - Do something\n\n%s build\n%s install\n%s test <ARG>\n%s clean\n\n" "$me" "$me2" "$me2" "$me2" "$me2"
exit 1
}

pr_err() {
printf "[ERROR] %s\n\a" "$1" >&2
}

if ! command -v sudo &>/dev/null; then
    pr_err "sudo (tsu) is not installed"
fi

case "$1" in
"build") $CURDIR/scripts/build.sh ;;
"install") sudo $CURDIR/scripts/install.sh ;;
"test") $CURDIR/scripts/test_ntm.sh "$2" ;;
"clean") $CURDIR/scripts/clean.sh ;;
"--help") help_usage ;;
*)

    if [ -z "$1" ]; then
        help_usage
    fi

printf "Invalid argument '%s'\nSee %s --help\n\a" "$1" "$me2"
exit 1
    ;;
esac
