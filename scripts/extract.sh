#!/bin/bash

# Based on: https://raw.githubusercontent.com/FairBlobs/FP5-firmware/381c9da98197f495a142a817b7173949280f7b9e/extract.sh
# Requirements:
#   - https://github.com/tchebb/parse-android-dynparts

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-factory-image.zip>"
    exit 1
fi

tmpdir=$(mktemp -d)
mount=$(mktemp -d)

cleanup() {
    set +e
    sudo umount "$mount"

    sudo dmsetup remove /dev/mapper/dynpart-*
    sudo losetup -d "$loopdev"

    sudo rmdir "$mount"
    sudo rm -r "$tmpdir"
}
trap cleanup EXIT

unzip -d "$tmpdir" "$1" images/BTFM.bin images/NON-HLOS.bin images/super.img

### NON-HLOS.bin ###
sudo mount -o ro "$tmpdir"/images/NON-HLOS.bin "$mount"
cp "$mount"/image/adsp* .
cp "$mount"/image/battmgr.jsn .
cp "$mount"/image/cdsp* .
cp -r "$mount"/image/modem* .
cp "$mount"/image/wpss* .
sudo umount "$mount"

### BTFM.bin ###
sudo mount -o ro "$tmpdir"/images/BTFM.bin "$mount"
cp "$mount"/image/msbtfw11.mbn .
cp "$mount"/image/msnv11.bin .
sudo umount "$mount"

### super.img ###
simg2img "$tmpdir"/images/super.img "$tmpdir"/super.raw.img
rm "$tmpdir"/images/super.img

loopdev=$(sudo losetup --read-only --find --show "$tmpdir"/super.raw.img)
sudo dmsetup create --concise "$(sudo parse-android-dynparts "$loopdev")"

sudo mount -o ro /dev/mapper/dynpart-vendor_a "$mount"
cp "$mount"/firmware/a660_zap.b* .
cp "$mount"/firmware/a660_zap.mdt .
cp "$mount"/firmware/yupik_ipa_fws.* .
cp "$mount"/firmware/vpu20_1v.mbn .

# cleanup happens on exit with the signal handler at the top
