#!/bin/bash

if [ "$1" == "-h" ]; then
    echo "Usage: prepare.sh [src_dir] [dst_dir]"
    exit 0
fi

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

SRC_DIR=${1:-$(realpath "$SCRIPTPATH/..")}
DST_DIR=${2:-"$SRC_DIR/out"}
DST_DIR="$DST_DIR/lib/firmware/qcom/qcm6490/SHIFT/otter"

if [ ! -d "$DST_DIR" ]; then
    echo "Creating destination directory: $DST_DIR"
    echo ""
    mkdir -pv "$DST_DIR"
fi

echo "Copying jsn files"
find "$SRC_DIR" -name "*.jsn" -not -path "$DST_DIR/*" -type f -exec cp -v {} "$DST_DIR" \;
echo ""

echo "Copying modem_pr/"
cp -rv "$SRC_DIR/modem_pr" "$DST_DIR"
echo ""

echo "Copying bluetooth firmware"
BT_DIR=$(realpath "$DST_DIR/../../../../qca")
mkdir -pv "$BT_DIR"
cp -v msbtfw11.mbn msnv11.bin "$BT_DIR"
echo ""

echo "Fixing permissions of all files"
find "$DST_DIR" -type f -exec chmod -v 0644 {} \;
echo ""

FILES=("$SRC_DIR"/*.mdt)
mapfile -t FILES < <(basename -a "${FILES[@]}")

echo "Using pil-squasher to pil-squash it all"
for MDT_FILE in "${FILES[@]}"; do
    SRC_FILE="$SRC_DIR/$MDT_FILE"
    if [ -e "$SRC_FILE" ]; then
        echo "Processing $SRC_FILE"
        MBN_FILE="$(basename "$MDT_FILE" .mdt)".mbn
        pil-squasher "$DST_DIR/$MBN_FILE" "$SRC_FILE"
        ln -sv "$MBN_FILE" "$DST_DIR/$MDT_FILE"
    fi
done
echo ""

echo "Preparing ipa firmware"
mv -v "$DST_DIR/yupik_ipa_fws.mbn" "$DST_DIR/ipa_fws.mbn"
rm -v "$DST_DIR/yupik_ipa_fws.mdt"
ln -sv ipa_fws.mbn "$DST_DIR/ipa_fws.mdt"
echo ""

echo "Preparing venus firmware"
cp -v "vpu20_1v.mbn" "$DST_DIR/venus.mbn"
ln -sv venus.mbn "$DST_DIR/venus.mdt"
echo ""
