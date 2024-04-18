#!/bin/bash
# Simple script to create a block and update it with the amount of packages
# currently awaiting an update. Typically run by putting it in crontab with a
# filter like '* * * * */10' to run every ten minutes.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-20}"
mkdir -p "$mountpath/$order-updates"
echo " $(checkupdates | wc -l)" > "$mountpath/$order-updates/content"
