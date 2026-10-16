#!/usr/bin/env bash
#
# Copyright (c) 2026 Daaf Wassenaar
# License: MIT
#

set -u

# Get touchscreen device input device
DEV=$(
    libinput list-devices |
    awk '
        /Device:/ && /Goodix/ { goodix = 1; next }
        goodix && /Kernel:/ { print $2; exit }
        /Device:/ { goodix = 0 }
    '
)

if [[ -z $DEV || ! -e $DEV ]]; then
    echo "Could not find a Goodix input device." >&2
    exit 1
fi

# Get configured udev matrix
CALIBRATION_MATRIX=$(
    udevadm info --query=property --name="$DEV" |
    sed -n 's/^LIBINPUT_CALIBRATION_MATRIX=//p'
)

if [[ -z $CALIBRATION_MATRIX ]]; then
    echo "No LIBINPUT_CALIBRATION_MATRIX property for $DEV" >&2
    exit 1
fi

if [[ ! -t 1 || ! -t 0 ]]; then
    echo "Run this from a terminal." >&2
    exit 1
fi

read -r rows cols < <(stty size < /dev/tty)

marker_row=1

printf '\033[%d;1HTerminal Touchscreen Test - start by touching the screen' "$marker_row"

while IFS= read -r line; do
    if [[ $line =~ [[:space:]]([0-9]+[.][0-9]+)/[[:space:]]*([0-9]+[.][0-9]+)[[:space:]] ]]; then
        x=${BASH_REMATCH[1]%%.*}
        y=${BASH_REMATCH[2]%%.*}

        col=$(( x * cols / 100 + 1 ))
        row=$(( y * rows / 100 + 1 ))

        (( col < 1 )) && col=1
        (( col > cols )) && col=$cols
        (( row < 1 )) && row=1
        (( row > rows )) && row=$rows

        # Erase the previous marker row, except before the first marker.
        if (( marker_row > 0 )); then
            printf '\033[%d;1H\033[2K' "$marker_row"
        fi

        printf '\033[1;1H\033[2KPosition: <%d,%d>' "$x" "$y"
        printf '\033[%d;%dH●' "$row" "$col"

        marker_row=$row
    fi
done < <(
    timeout 10s stdbuf -oL \
        libinput debug-events \
        --set-calibration "$CALIBRATION_MATRIX" \
        --device "$DEV" 2>/dev/null
)

# Should clear after running
clear