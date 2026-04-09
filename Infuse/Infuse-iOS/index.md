# Infuse (iOS)

Unlock the full potential of Infuse.

- **App**: [Infuse](https://apps.apple.com/fr/app/infuse/id1136220934)
- **Tested version**: 8.4.2
- **Target**: iOS 18+ (tested on iOS 18.7.1 using LiveContainer)

## Build

```sh
make package FINALPACKAGE=1
```

## Inject

```sh
cyan -i infuse-8.4.2.ipa \
     -o infuse-8.4.2_patched.ipa \
     -f io.infuseteam.infuserootless_2.0_iphoneos-arm.deb \
     -u
```

## Screenshots

![mobile.png](../../docs/screens/Infuse/mobile.png)