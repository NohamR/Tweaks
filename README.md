# Tweaks

iOS tweaks built with [Theos](https://theos.dev), injected into IPAs via [cyan](https://github.com/asdfzxcvbn/pyzule-rw).

## Tweaks

| Tweak                                           | App              | Target  |
| ----------------------------------------------- | ---------------- | ------- |
| [ServerCatPremium](ServerCatPremium/index.md)      | ServerCat 1.30.0 | iOS 17+ |
| [ServerCatPremium (legacy)](ServerCatPremium_/index.md) | ServerCat 1.6.4  | iOS 15  |

## Build

```sh
# Debug
make clean && make package THEOS_PACKAGE_SCHEME=rootless

# Production
make clean && make package THEOS_PACKAGE_SCHEME=rootless DEBUG=0
```

## Inject

```sh
cyan -i <input.ipa> -o <output_patched.ipa> -f <tweak.deb> -u
```

See each tweak's `index.md` for the specific command.
