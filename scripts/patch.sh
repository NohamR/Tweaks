#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [--tv] [-o <output.ipa> | --output <output.ipa>] <file.ipa> <file.deb>"
    exit 1
}

TV=0
IPA=""
DEB=""
OUTPUT_IPA=""
OUTPUT_SPECIFIED=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        -o|--output)
            if [ -z "$2" ]; then
                echo "Error: $1 requires an argument."
                exit 1
            fi
            OUTPUT_IPA="$2"
            OUTPUT_SPECIFIED=1
            shift 2
            ;;
        -o=*|--output=*)
            OUTPUT_IPA="${1#*=}"
            OUTPUT_SPECIFIED=1
            shift
            ;;
        --tv)
            TV=1
            shift
            ;;
        *.ipa)
            IPA="$1"
            shift
            ;;
        *.deb)
            DEB="$1"
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

if [ -z "$IPA" ] || [ -z "$DEB" ]; then
    echo "You must provide one .ipa and one .deb file."
    exit 1
fi

if [ -z "$OUTPUT_IPA" ]; then
    OUTPUT_IPA="/tmp/ipa_patched/$(basename "$IPA")"
    mkdir -p "$(dirname "$OUTPUT_IPA")"
fi

CYAN_ARGS=(-i "$IPA" -o "$OUTPUT_IPA" -f "$DEB" -u --overwrite -c 9)
if [ "$TV" -eq 1 ]; then
    CYAN_ARGS+=(--tv)
fi

echo "[+] Patching IPA with cyan..."
cyan "${CYAN_ARGS[@]}"
echo "[+] Patch complete."

if [ "$OUTPUT_SPECIFIED" -eq 0 ]; then
    PATCHED_IPA="$(dirname "$IPA")/$(basename "$IPA" .ipa)_patched.ipa"
    cp "$OUTPUT_IPA" "$PATCHED_IPA"
    echo "[+] Patched IPA saved as: $PATCHED_IPA"
fi
