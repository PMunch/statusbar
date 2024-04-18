#!/bin/bash
# Simple script to create a block and update it with the IP address for all
# interfaces. If no interface has an IP it shows a "No connection" message.
# Typically run by putting it in cron with something like a '* * * * */10' rule,
# making it run once every ten minutes.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-50}"
mkdir -p "$mountpath/$order-ipaddr"
interfaces="$(ip addr | awk '/^    inet /{sub(/\/.*/, X, $0); if ($2 != "127.0.0.1") print interface" "$2}/^[0-9]+:/{interface=$2}')"
ipmsg=$([ "$interfaces" == "" ] && echo " No connection")
while IFS= read -r interface; do
  if [[ "$interface" == "" ]]; then
    continue
  fi
  if [[ "$interface" == *"enp"* ]] || [[ "$interface" == *"eth"* ]]; then
    ipmsg="$ipmsg   $(echo $interface | cut -d" " -f2)"
  else
    ipmsg="$ipmsg   $(echo $interface | cut -d" " -f2)"
  fi
done <<< "$interfaces"
echo $ipmsg > "$mountpath/$order-ipaddr/content"
