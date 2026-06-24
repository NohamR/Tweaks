#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file.ipa> <file.deb>"
    exit 1
fi

IPA=""
DEB=""

for arg in "$@"; do
    case "$arg" in
        *.ipa)
            IPA="$arg"
            ;;
        *.deb)
            DEB="$arg"
            ;;
        *)
            echo "Unknown file type: $arg"
            exit 1
            ;;
    esac
done

if [ -z "$IPA" ] || [ -z "$DEB" ]; then
    echo "You must provide one .ipa and one .deb file."
    exit 1
fi

# ---- Prepare output folder ----
OUT_DIR="/tmp/ipa_patched"
mkdir -p "$OUT_DIR"

IPA_NAME=$(basename "$IPA")
OUTPUT_IPA="$OUT_DIR/$IPA_NAME"

echo "[+] Patching IPA with cyan..."
# cyan -i "$IPA" -o "$OUTPUT_IPA" -f "$DEB" -u --overwrite -c 0
cyan -i "$IPA" -o "$OUTPUT_IPA" -f "$DEB" -u --overwrite -c 9 --tv
echo "[+] Patch complete."

# Copy patched IPA next to the original with _patched suffix
ORIG_DIR=$(dirname "$IPA")
ORIG_BASENAME=$(basename "$IPA" .ipa)
PATCHED_IPA="$ORIG_DIR/${ORIG_BASENAME}_patched.ipa"
cp "$OUTPUT_IPA" "$PATCHED_IPA"
echo "[+] Patched IPA saved as: $PATCHED_IPA"