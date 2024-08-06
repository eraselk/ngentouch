su -c "find . -type f -name ntm.sh | while read -r ntm; do \$ntm \"$1\"; done"
