#!/bin/bash
set -e
set -o pipefail

SUBJECT="$1"
TITLE="Installation: $SUBJECT"
LABEL="Enter password for $SUBJECT"

ROOT_PASS=$(dialog --title "$TITLE" --inputbox "$LABEL" 8 30 3>&2 2>&1 1>&3) || (clear && exit 1)

ENC_ROOT_PASS=$(openssl passwd -6 "$ROOT_PASS")

echo $ENC_ROOT_PASS
