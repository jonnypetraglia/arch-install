#!/bin/bash
set -e
set -o pipefail

TITLE="Installation: Timezone"
MENU="Select a timezone"

# Collect Timezone areas
W=()
while read -r line; do
    W+=($(basename $line) "")
done < <(ls -1d /usr/share/zoneinfo/[A-Z]*/) 
# Get the timezone area 
AREA=$(dialog --title "$TITLE" --menu "Select an area" 0 0 0 "${W[@]}" 3>&2 2>&1 1>&3) || (clear && exit 1)

# Collect the Timezones
W=()
while read -r line; do
    W+=($(basename $line) "")
done < <(ls -1 /usr/share/zoneinfo/$AREA) 
# Get the timezone area 
ZONE=$(dialog --title "$TITLE" --menu "Select a part of $AREA" 0 0 0 "${W[@]}" 3>&2 2>&1 1>&3) || (clear && exit 1)


echo "$AREA/$ZONE"


