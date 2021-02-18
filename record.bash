#!/usr/bin/env bash

# {
# 	if ! [ -e .git/annex ]
# 	then
# 		IP="$(ip addr show | grep inet\  | sed -ne 's/.*inet \([0-9\.]*\)\/.*global.*/\1/p')"
# 		name="$(hostname)"-"$IP"
# 		echo $name
# 		git annex init "$name"
# 	fi
# 	git annex add *.mkv
# 	git annex sync
# 	git annex copy --all --to=skynet
# } &
#GST_DEBUG=3 gst-launch-1.0 v4l2src do-timestamp=true ! queue ! videoconvert ! omxh264enc ! h264parse config-interval=-1 ! matroskamux ! filesink location=$(date --iso=seconds)-"$(hostname)".mkv
GST_DEBUG=3 gst-launch-1.0 v4l2src ! videoconvert ! avenc_h264_omx ! matroskamux ! filesink location=$(date --iso=seconds)-"$(hostname)".mkv
#plan is to make a small supporting c program to append to tar files from live streams, and store them in annex repositories

