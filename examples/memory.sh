#!/bin/bash
# Simple script to create a block and update it with memory usage. Runs 6
# times with 10 seconds between each run. If added to crontab with the rule
# '* * * * *' to run the script every minute this means it will run constantly
# every ten seconds.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-60}"
mkdir -p "$mountpath/$order-memory"
i=0
while [ $i -lt 6 ]; do
  MEM=$(awk '(NR == 2) {print $3}' <(free -h))
  #MEMPERC=$(awk '(NR == 2) {print ($3 * 100) / $2}' <(free)) # Memory as percentage
  echo " $MEM" > "$mountpath/$order-memory/content"
  sleep 10
  i=$((i + 1))
done
