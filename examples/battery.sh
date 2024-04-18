#!/bin/bash
# Simple script to create a block and update it with the current battery and
# charging state. Typically run by putting it in cron with something like a
# '* * * * */5' rule, making it run once every 5 minutes.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-30}"
mkdir -p "$mountpath/$order-battery"
if [[ "$(head -c -1 -q /sys/class/power_supply/BAT0/status)" != "Discharging" ]]; then
  icon=""
else
  case "$(head -c -1 -q /sys/class/power_supply/BAT0/capacity)" in
    100)
      icon=""
      ;;
    [9-8][0-9])
      icon=""
      ;;
    [7-6][0-9])
      icon=""
      ;;
    [5-4][0-9])
      icon=""
      ;;
    [3-2][0-9])
      icon=""
      ;;
    *)
      icon=""
  esac
fi
echo "$icon $(head -c -1 -q /sys/class/power_supply/BAT0/capacity)%" > "$mountpath/$order-battery/content"
