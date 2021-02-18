#!/usr/bin/env bash

macs="MAC--$(ip addr show | sed -ne 's/.*link\/ether \([0-9a-fA-F:]*\).*/\1/p' | tr '\n:' -_)"
uuids="$(lsblk -o UUID | sort -ur | grep . | tr '\n' -)"
name="$(hostname)-${uuids%-}-${macs%-}"
GIT="$(type -p git)"
absorb_raspiweirdness()
{
	grep -v libarmmem 1>&2
}
git()
{
	# removes error cruft from git-annex's git somehow being unable to open a preloaded library
	set -o pipefail
	"$GIT" "$@" 2>&1 | absorb_raspiweirdness
}
if ! git describe --all >/dev/null 2>&1
then
	git init
	git commit --allow-empty -m "$name"
fi
if ! git annex numcopies >/dev/null 2>&1
then
	echo $name
	git annex init "$name"
	git annex adjust --unlock
	git annex initremote skynet chunk=64MiB type=external encryption=none externaltype=siaskynet
fi
git annex add *.tar
git commit -m "$(date +%Y)-${name}"
tarfile="$(date +%Y)-${name}.tar"
while ps $$ >/dev/null 2>&1
do
	git annex copy --all --to=skynet --jobs=2
	git annex sync
	while git annex dropunused 1; do sleep 1; done
	sleep 10
	(
		flock 9 || exit 1
		git annex add "$tarfile"
		git commit -m "$(date +%Y)-${name}"
	) 9<"$tarfile"
done 2>&1 | absorb_raspiweirdness &
GST_DEBUG=3 gst-launch-1.0 v4l2src ! videoconvert ! avenc_h264_omx ! matroskamux streamable=true ! fdsink | streamtar "$tarfile" "$(date --iso=seconds).mkv"
git annex add *.tar
git commit -m "$(date +%Y)-${name}"
