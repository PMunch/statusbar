#!/bin/bash
# Simple script to create a block and update it with the current date and time
# Typically run by the same keybinding which sets volume, and probably as cron
# job with the pattern '* * * * *' to run it every minute just in case something
# else changed the volume. NOTE: For cron to be able to use `pactl` you add
# XDG_RUNTIME_DIR=/run/user/$(id -u) before your command.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-40}"
mkdir -p "$mountpath/$order-volume"
mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '$1 ~ /Mute:/{if ($2 == "no") print "🔊"; else print "🔇"}')
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '$1 ~ /Volume:/{print $5}')
paste -d" " <(echo $mute) <(echo $volume) > "$mountpath/$order-volume/content"
