# GoodnotesPro

Unlocks GoodNotes Pro features — port of [BadNotes](https://github.com/c22dev/badnotes) by [c22dev (Constantin Clerc)](https://github.com/c22dev).

- **App**: [Goodnotes: AI Notes, Docs, PDF](https://apps.apple.com/fr/app/goodnotes-ai-notes-docs-pdf/id1444383602)
- **Bundle**: `com.goodnotesapp.x` (also filters `com.goodnotesapp.goodnotes`, `com.TimeBase.TimeBase` for legacy)
- **Tested on**: GoodNotes 7.1.18 (iOS 18+)
- **Original source**: [`c22dev/badnotes/Tweak.m`](https://github.com/c22dev/badnotes/blob/main/Tweak.m) (v0.2)

## How it works

GoodNotes uses RevenueCat (proxied via `*/v1/subscribers/<user_id>`) to check subscription status. The tweak hooks `NSURLSession -dataTaskWithRequest:completionHandler:` at runtime, strips cache headers (`If-None-Match`, `X-RevenueCat-ETag`), and replaces the JSON response with a crafted payload that grants:

- `entitlements.apple_access` + `crossplatform_access` → `com.goodnotes.pro_7dt_1y_3599` (expires `2099-12-31`)
- `subscriptions` → both `com.goodnotes.pro_7dt_1y_3599` and legacy `com.goodnotes.gn6_one_time_unlock_3999`
- `quotas.ai` → 525/month
- `current_plans.base` → `pro`

It also patches `NSBundle -localizedStringForKey:value:table:` to show `BadNotes` labels (yearly period + subtitle).

> Some server-side features (AI, collaboration) may still not work.

```sh
make clean && make package THEOS_PACKAGE_SCHEME=rootless DEBUG=0
```

```sh
cyan -i com.goodnotesapp.x-7.1.18.ipa \
     -o com.goodnotesapp.x-7.1.18_patched.ipa \
     -f packages/xyz.nohamr.goodnotespro_1.0.0_iphoneos-arm64.deb \
     -u
```