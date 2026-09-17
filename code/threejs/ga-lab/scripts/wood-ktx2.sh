#!/usr/bin/env bash
# Experiment 6: the wood texture compressed to KTX2 twice with KTX-Software's ktx tool (4.4.2), with mipmaps:
# UASTC (high quality, transcoded to BC7 or ASTC on the GPU) and ETC1S/BasisLZ (smaller files, lower quality).
#   KTX=<folder of KTX-Software, with bin/ and lib/> bash scripts/wood-ktx2.sh
# The author ran it in WSL (Ubuntu), with the Linux x86_64 release extracted in the WSL home folder.
set -euo pipefail
cd "$(dirname "$0")/../public/generated"
export LD_LIBRARY_PATH="$KTX/lib"
"$KTX/bin/ktx" --version
for encode in uastc basis-lz; do
  start=$(date +%s.%N)
  "$KTX/bin/ktx" create --format R8G8B8A8_SRGB --assign-tf srgb --generate-mipmap --encode "$encode" \
    $([ "$encode" = uastc ] && echo --zstd 18) wood-2048.png "wood-2048-$encode.ktx2"
  echo "$encode: $(stat -c %s "wood-2048-$encode.ktx2") bytes in $(echo "$(date +%s.%N) - $start" | bc) s"
done
echo "png: $(stat -c %s wood-2048.png) bytes"
