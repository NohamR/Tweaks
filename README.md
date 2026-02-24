# Tweaks

iOS tweaks built with [Theos](https://theos.dev), injected into IPAs via [cyan](https://github.com/asdfzxcvbn/pyzule-rw).

## Tweaks

| Tweak                                                   | App              | Target     |
| ------------------------------------------------------- | ---------------- | ---------- |
| [ServerCatPremium](ServerCatPremium/index.md)           | ServerCat 1.30.0 | iOS 17+    |
| [ServerCatPremium (legacy)](ServerCatPremium_/index.md) | ServerCat 1.6.4  | iOS 15     |
| [TextasticPro](TextasticPro/index.md)                   | Textastic 10.9.2 | iOS 18+    |
| [BusinessJB](BusinessJB/index.md)                       | Business 2.3.000 | iOS 15     |
| [CreditAgricoleJB](CreditAgricoleJB/index.md)           | Ma Banque 47.0.0 | iOS 15.8.6 |

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
