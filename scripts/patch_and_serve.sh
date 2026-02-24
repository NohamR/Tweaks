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
cyan -i "$IPA" -o "$OUTPUT_IPA" -f "$DEB" -u --overwrite
echo "[+] Patch complete."

LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null)

if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

if [ -z "$LOCAL_IP" ]; then
    echo "Could not detect local IP automatically."
    LOCAL_IP="YOUR_IP"
fi

DOWNLOAD_LINK="http://$LOCAL_IP:8000/$IPA_NAME"

cd "$OUT_DIR"

echo ""
echo "=========================================="
echo "Download link:"
echo "$DOWNLOAD_LINK"
echo "=========================================="
echo ""
echo -n "$DOWNLOAD_LINK" | pbcopy
echo "[+] Download link copied to clipboard."
echo "[+] Starting HTTP server..."
echo "Press Ctrl+C to stop."
echo ""

python3 -m http.server 8000