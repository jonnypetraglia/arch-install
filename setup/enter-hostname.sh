#!/bin/bash
set -e
set -o pipefail

TITLE="Installation: Hostname"
MENU="Enter hostname"

#RHOSTNAME=$(dialog --title "$TITLE" --inputbox "$MENU" 8 30 3>&2 2>&1 1>&3) || (clear && exit 1)


RHOSTNAME=$(dialog --inputbox "HELLO" 8 30 --inputbox "THERE" 8 30 3>&2 2>&1 1>&3)


echo $RHOSTNAME
