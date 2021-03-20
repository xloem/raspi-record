#!/usr/bin/env bash

macs="MAC--$(ip addr show | sed -ne 's/.*link\/ether \([0-9a-fA-F:]*\).*/\1/p' | tr '\n:' -_)"
uuids="$(lsblk -o UUID | sort -ur | grep . | tr '\n' -)"
name="$(hostname)-${uuids%-}-${macs%-}"
GIT="$(type -p git)"

# this helps my cam
sudo rmmod gspca_ov534
sudo modprobe gspca_ov534

rm .git/index.lock ../.git/index.lock ../../.git/index.lock ../../../.git/index.lock ../../../../.git/index.lock 2>/dev/null

show_exitcode()
{
	"$@"
	echo "$1 exited with code $?"
}
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
move_bytes()
{
	tarfile="$1"
	(
		flock 9
		if [ -e raspi_record_offset ]
		then
			offset=$(<raspi_record_offset)
			dd if="$tarfile".live iflag=skip_bytes skip="$offset" of="$tarfile" oflag=seek_bytes seek="$offset" count=1 bs=$((1024*1024)) conv=notrunc 
		fi
		offset=$(stat -Lc %s "$tarfile")
		dd if="$tarfile".live iflag=skip_bytes skip="$offset" of="$tarfile" oflag=append conv=notrunc 
	) 9<"$tarfile".live
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
tarfile="$(date +%Y)-${name}.tar"
move_bytes "$tarfile"
stat -Lc %s "$tarfile" > raspi_record_offset
while ps $$ >/dev/null 2>&1
do
	sleep 60
	move_bytes "$tarfile"
	git annex add "$tarfile"
	while git annex dropunused 1; do sleep 1; done
	git commit -m "$(date +%Y)-${name}"
	git annex copy --all --to=skynet --jobs=2 --debug
	git annex sync
done 2>&1 | absorb_raspiweirdness &
GST_DEBUG=2 show_exitcode gst-launch-1.0 v4l2src blocksize=$((1024*1024)) ! queue ! videoconvert ! avenc_h264_omx ! matroskamux streamable=true ! fdsink | show_exitcode streamtar "$tarfile".live "$(date --iso=seconds).mkv"
