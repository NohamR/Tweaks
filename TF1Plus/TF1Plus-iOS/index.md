# TF1+ iOS

Block ads initialization on TF1+.

- **App**: [TF1+ : Streaming, TV en Direct](https://apps.apple.com/fr/app/tf1-streaming-tv-en-direct/id407248490)
- **Tested version**: 11.36.0
- **Target**: iOS

## Build

```sh
make package FINALPACKAGE=1
```

## Inject

```sh
cyan -i tf1plus.ipa \
     -o tf1plus_patched.ipa \
     -f xyz.nohamr.tf1plus_1.0_iphoneos-arm64.deb \
     -u
```
