#!/bin/bash

if [ "$1" == "-h" ]; then
    echo "Usage: prepare.sh [src_dir] [dst_dir]"
    exit 0
fi

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

SRC_DIR=${1:-$(realpath "$SCRIPTPATH/..")}
DST_DIR=${2:-"$SRC_DIR/out"}
FW_DIR="$DST_DIR/usr/lib/firmware/qcom/qcm6490/SHIFT/otter"
HEXAGON_DIR="$DST_DIR/usr/share/qcom/qcm6490/SHIFT/otter"

if [ ! -d "$FW_DIR" ]; then
    echo "Creating firmware directory: $FW_DIR"
    echo ""
    mkdir -pv "$FW_DIR"
fi

if [ ! -d "$HEXAGON_DIR" ]; then
    echo "Creating hexagonfs directory: $HEXAGON_DIR"
    echo ""
    mkdir -pv "$HEXAGON_DIR"
fi

echo "Copying jsn files"
find "$SRC_DIR" -name "*.jsn" -not -path "$FW_DIR/*" -type f -exec cp -v {} "$FW_DIR" \;
echo ""

echo "Copying modem_pr/"
cp -rv "$SRC_DIR/modem_pr" "$FW_DIR"
echo ""

echo "Copying bluetooth firmware"
BT_DIR=$(realpath "$FW_DIR/../../../../qca")
mkdir -pv "$BT_DIR"
cp -v msbtfw11.mbn msnv11.bin "$BT_DIR"
echo ""

echo "Copying hexagonfs"
cp -v -r "$SRC_DIR/hexagonfs/" "$HEXAGON_DIR"
echo ""

echo "Fixing permissions of all files"
find "$FW_DIR" -type f -exec chmod -v 0644 {} \;
find "$HEXAGON_DIR" -type f -exec chmod -v 0644 {} \;
echo ""

FILES=("$SRC_DIR"/*.mdt)
mapfile -t FILES < <(basename -a "${FILES[@]}")

echo "Using pil-squasher to pil-squash it all"
for MDT_FILE in "${FILES[@]}"; do
    SRC_FILE="$SRC_DIR/$MDT_FILE"
    if [ -e "$SRC_FILE" ]; then
        echo "Processing $SRC_FILE"
        MBN_FILE="$(basename "$MDT_FILE" .mdt)".mbn
        pil-squasher "$FW_DIR/$MBN_FILE" "$SRC_FILE"
        ln -sv "$MBN_FILE" "$FW_DIR/$MDT_FILE"
    fi
done
echo ""

echo "Preparing ipa firmware"
mv -v "$FW_DIR/yupik_ipa_fws.mbn" "$FW_DIR/ipa_fws.mbn"
rm -v "$FW_DIR/yupik_ipa_fws.mdt"
ln -sv ipa_fws.mbn "$FW_DIR/ipa_fws.mdt"
echo ""

echo "Preparing venus firmware"
cp -v "vpu20_1v.mbn" "$FW_DIR/venus.mbn"
ln -sv venus.mbn "$FW_DIR/venus.mdt"
echo ""
