#!/bin/bash
# Simple script to create a block and update it with the current date and time
# Typically run by putting it in cron with the '* * * * *' rule, making it run
# once every minute.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-90}"
mkdir -p "$mountpath/$order-datetime"
date '+ %a %x   %H:%M' > "$mountpath/$order-datetime/content"
#date '+ %a %x   %I:%M%P' > "$mountpath/$order-datetime/content" # AM/PM variant
