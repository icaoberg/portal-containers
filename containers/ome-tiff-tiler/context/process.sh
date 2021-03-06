#!/usr/bin/env bash
set -o errexit
set -o pipefail

die() { set +v; echo "$*" 1>&2 ; exit 1; }

# Default parameter is number of available processors.
WORKERS=$(nproc)
# Default is no RGB.
RGB=""
while getopts "o:i:w:r" opt
do
   case "$opt" in
      i ) INPUT_DIR="$OPTARG" ;;
      o ) OUTPUT_DIR="$OPTARG" ;;
      w ) WORKERS="$OPTARG" ;;
      r ) RGB="--rgb"
   esac
done

for FILE in $INPUT_DIR/*ome.tif*
do
  # Handle both ways tiffs are named
  BASE_FILE_NAME=$(basename $FILE .ome.tif)
  BASE_FILE_NAME=$(basename $BASE_FILE_NAME .ome.tiff)

  N5_FILE=$OUTPUT_DIR/$BASE_FILE_NAME.n5/

  /opt/bioformats2raw/bin/bioformats2raw $FILE $N5_FILE  --tile_width 512 --tile_height 512 --max_workers $WORKERS\
    || die "TIFF-to-n5 failed."
  echo "Wrote n5 pyramid from $FILE to $N5_FILE"

  /opt/raw2ometiff/bin/raw2ometiff $N5_FILE $OUTPUT_DIR/$BASE_FILE_NAME.ome.tif --compression=zlib  $RGB \
    || die "n5-to-pyramid failed."
  echo "Wrote OMETIFF pyramid from $N5_FILE to $OUTPUT_DIR/$BASE_FILE_NAME.ome.tif"
  
done
