# VolkswagenJB

Disables jailbreak detection in Volkswagen.

- **App**: [Volkswagen](https://apps.apple.com/fr/app/volkswagen/id1517566572)
- **Latest version**: 2.72.0
- **Tested on**: iOS 16.7.15

## Build

```sh
make clean && make package THEOS_PACKAGE_SCHEME=rootless DEBUG=0
```

## Inject

```sh
cyan -i com.volkswagen.WeConnect.production_2.72.0.ipa \
     -o com.volkswagen.WeConnect.production_2.72.0_patched.ipa \
     -f xyz.nohamr.volkswagenjb_1.0.0-1_iphoneos-arm64.deb \
     -u
```

## Screenshots

![../docs/screens/VolkswagenJB/undetected.png](../docs/screens/VolkswagenJB/undetected.png)