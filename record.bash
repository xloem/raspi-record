#!/usr/bin/env bash

macs="MAC--$(ip addr show | sed -ne 's/.*link\/ether \([0-9a-fA-F:]*\).*/\1/p' | tr '\n:' -_)"
uuids="$(lsblk -o UUID | tr '\n' -)"
name="$(hostname)-${uuids%-}-${macs%-}"
GIT="$(type -p git)"
git()
{
	# removes error cruft from git-annex's git somehow being unable to open a preloaded library
	"$GIT" "$@" 2>&1 | grep -v libarmmem 1>&2
}
if ! [ -e .git ]
then
	git init .
	git commit --allow-empty -m "$name"
fi
if ! [ -e .git/annex ]
then
	echo $name
	git annex init "$name"
	git config annex.thin true
	git annex adjust --unlock
	git annex initremote skynet chunk=64MiB type=external encryption=none externaltype=siaskynet
fi
git annex add *.tar
git commit -m "$(date +%Y)-${name}"
{
	git annex sync
	git annex copy --all --to=skynet --jobs=2
} &
GST_DEBUG=3 gst-launch-1.0 v4l2src ! videoconvert ! avenc_h264_omx ! matroskamux streamable=true ! fdsink | streamtar "$(date +%Y)-${name}.tar" "$(date --iso=seconds).mkv"
git annex add *.tar
git commit -m "$(date +%Y)-${name}"
