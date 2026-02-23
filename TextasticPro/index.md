# TextasticPro

Unlocks premium features in Textastic.

- **App**: [Textastic](https://apps.apple.com/fr/app/textastic/id572491815?l=en-GB&mt=12)
- **Tested on**: Textastic 10.9.2, iOS iOS 18.3

## Build

```sh
make clean && make package THEOS_PACKAGE_SCHEME=rootless DEBUG=0
```

## Inject

```sh
cyan -i com.textasticapp.textastic-universal-10.9.2.ipa \
     -o com.textasticapp.textastic-universal-10.9.2_patched.ipa \
     -f xxyz.nohamr.textasticpro_1.0.0-1_iphoneos-arm64.deb \
     -u
```

## Screenshots

![../docs/screens/TextasticPro/pro.png](../docs/screens/TextasticPro/pro.png)
![../docs/screens/TextasticPro/search.png](../docs/screens/TextasticPro/search.png)
![../docs/screens/TextasticPro/shh1.png](../docs/screens/TextasticPro/ssh1.png)
![../docs/screens/TextasticPro/ssh2.png](../docs/screens/TextasticPro/ssh2.png)