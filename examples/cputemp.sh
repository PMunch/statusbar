#!/bin/bash
# Simple script to create a block and update it with CPU utilization. If
# utilization is above 10% then the highest consumer will be shown in
# parenthesis. Runs 12 times with 5 seconds between each run. If added to
# crontab with the rule '* * * * *' to run the script every minute this means
# it will run constantly every five seconds.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-70}"
mkdir -p "$mountpath/$order-cputemp"
touch /tmp/prevcpu
i=0
while [ $i -lt 12 ]; do
  temp=$(sensors | awk '/^Package id /{sub(/+/,X,$0); print $4}')
  case ${temp:0:2} in
  5[0-9])
    sym=""
    ;;
  6[0-9])
    sym=""
    ;;
  7[0-9])
    sym=""
    ;;
  8[0-9])
    sym=""
    ;;
  *)
    sym=""
    ;;
  esac
  echo "$sym $temp" > "$mountpath/$order-cputemp/content"
  sleep 5
  i=$((i + 1))
done
