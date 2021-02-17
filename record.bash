#!/usr/bin/env bash

{
	git annex add *.mkv
	git annex sync
	git annex copy --all --to=skynet
} &
gst-launch-1.0 v4l2src ! omxh264enc ! mkvmux ! filesink=$(date --iso=seconds)-"$hostname".mkv
