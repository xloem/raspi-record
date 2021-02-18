#!/usr/bin/env bash

macs="MAC--$(ip addr show | sed -ne 's/.*link\/ether \([0-9a-fA-F:]*\).*/\1/p' | tr '\n' -)"
uuids="$(lsblk -o UUID | tr '\n' -)"
name="$(hostname)-${uuids%-}-${macs%-}"
# {
# 	if ! [ -e .git/annex ]
# 	then
# 		name="$(hostname)"-"$IP"
# 		echo $name
# 		git annex init "$name"
# 	fi
# 	git annex add *.mkv
# 	git annex sync
# 	git annex copy --all --to=skynet
# } &
#GST_DEBUG=3 gst-launch-1.0 v4l2src do-timestamp=true ! queue ! videoconvert ! omxh264enc ! h264parse config-interval=-1 ! matroskamux streamable=true ! filesink location=$(date --iso=seconds)-"$(hostname)".mkv
GST_DEBUG=3 gst-launch-1.0 v4l2src ! videoconvert ! avenc_h264_omx ! matroskamux streamable=true ! fdsink | streamtar "$(date +%Y)-${name}.tar" "$(date --iso=seconds).mkv"
#plan is to make a small supporting c program to append to tar files from live streams, and store them in annex repositories

