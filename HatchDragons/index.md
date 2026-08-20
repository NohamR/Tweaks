# HatchDragons

Logs HTTP requests and negates currency deductions in HatchDragons so spending hard/soft currency instead adds it to the player's balance.

- **App**: [HatchDragons](https://apps.apple.com/us/app/hatch-dragons/id6746389113)
- **Latest version**: 1.2.1
- **Tested on**: iOS 18.3

## Build

```sh
make clean && make package THEOS_PACKAGE_SCHEME=rootless DEBUG=0
```

## Inject

```sh
cyan -i com.runawayplay.dragons_1.2.1.ipa \
     -o com.runawayplay.dragons_1.2.1_patched.ipa \
     -f xyz.nohamr.hatchdragons_1.0.0_iphoneos-arm.deb \
     -u
```