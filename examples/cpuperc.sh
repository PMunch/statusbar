#!/bin/bash
# Simple script to create a block and update it with CPU utilization. If
# utilization is above 10% then the highest consumer will be shown in
# parenthesis. Runs 12 times with 5 seconds between each run. If added to
# crontab with the rule '* * * * *' to run the script every minute this means
# it will run constantly every five seconds.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-80}"
mkdir -p "$mountpath/$order-cpu"
touch /tmp/prevcpu
i=0
while [ $i -lt 12 ]; do
  eval $(awk '{print "previdle=" $1 "; prevtotal=" $2}' /tmp/prevcpu)
  eval $(awk '/^cpu /{print "idle=" $5 "; total=" $2+$3+$4+$5 }' /proc/stat)
  intervaltotal=$((total-${prevtotal:-0}))
  cpu=$((100*( (intervaltotal) - ($idle-${previdle:-0}) ) / (intervaltotal) ))
  topconsumer=$(basename $(ps -eo pcpu,args | tail +2 | sort -k1 -r -n | head -1 | awk '{print $2}'))
  hog=$([ "$cpu" -gt "10" ] && echo " ($topconsumer)")
  echo " $cpu%$hog" > "$mountpath/$order-cpu/content"
  echo "$idle $total" > /tmp/prevcpu
  sleep 5
  i=$((i + 1))
done
