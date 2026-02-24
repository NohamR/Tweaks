# CreditAgricoleJB

Disables jailbreak detection in Ma Banque.

- **App**: [Ma Banque](https://apps.apple.com/fr/app/ma-banque/id376202925)
- **Latest version**: 47.0.0
- **Tested on**: iOS 15.8.6

## Build

```sh
make clean && make package THEOS_PACKAGE_SCHEME=rootless DEBUG=0
```

## Inject

```sh
cyan -i com.creditagricole.mabanque-47.0.0.ipa \
     -o com.creditagricole.mabanque-47.0.0_patched.ipa \
     -f xyz.nohamr.creditagricolejb_1.0.0-1_iphoneos-arm64.deb \
     -u
```

## Screenshots

![../docs/screens/CreditAgricoleJB/undetected.png](../docs/screens/CreditAgricoleJB/undetected.png)