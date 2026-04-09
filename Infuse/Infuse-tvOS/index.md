# Infuse tvOS

Unlock pro features in Infuse.

- **App**: [Infuse](https://apps.apple.com/fr/app/infuse/id1136220934)
- **Tested version**: 8.2.4
- **Target**: tvOS 18.3 (tested on tvOS 18.3)

## Build

```sh
make package FINALPACKAGE=1
```

## Inject

```sh
cyan -i infuse-8.2.4.ipa \
     -o infuse-8.2.4_patched.ipa \
     -f io.infuseteam.infuserootless_2.0_tvos-arm64.deb \
     -u
```

## Screenshots

![../docs/screens/Infuse/settings.png](../docs/screens/Infuse/settings.png)
