#!/bin/bash
# Simple script to create a block and update it with the current date and time
# Typically run by the same keybinding which sets volume, and probably as cron
# job with the pattern '* * * * *' to run it every minute just in case something
# else changed the volume.
mountpath="${MOUNTPATH:-/tmp/statusbar}"
order="${ORDER:-40}"
mkdir -p "$mountpath/$order-volume"
mute=$(pactl list sinks | awk '$1 ~ /Mute:/{if ($2 == "no") print "🔊"; else print "🔇"}')
volume=$(pactl list sinks | awk '$1 ~ /Volume:/{print $5}')
paste -d" " <(echo $mute) <(echo $volume) > "$mountpath/$order-volume/content"
# Technically the mute and volume awk scripts could both be placed in one
# statement and not require the paste. But this requires the order of 'pactl
# list sinks' to always list mute status before volume, which I wasn't sure
# would always be the case.
