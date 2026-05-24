# OqeePlus tvOS

Block ads initialization on Oqee.

- **App**: [OqeePlus : Streaming, TV en Direct](https://apps.apple.com/fr/app/free-tv/id1542614107)
- **Tested version**: 2.40
- **Target**: tvOS

## Build

```sh
make package FINALPACKAGE=1
```

## Inject

```sh
cyan -i oqeeplus.ipa \
     -o oqeeplus_patched.ipa \
     -f xyz.nohamr.oqeeplus_1.0_appletvos-arm64.deb \
     -u
```
