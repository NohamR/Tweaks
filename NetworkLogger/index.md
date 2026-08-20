# NetworkLogger

Logs every network request and response to the console via `os_log`. Useful for debugging API calls, reverse-engineering endpoints, and understanding how an app communicates with its backend.

## What it hooks

- `NSURLSession` task creation (`dataTaskWithRequest:`, `dataTaskWithURL:`, `uploadTaskWithRequest:fromData:`, `downloadTaskWithRequest:`)
- `NSURLSessionTask resume`
- `NSURLConnection sendAsynchronousRequest:queue:completionHandler:` (legacy)

## Output format

```
[NetworkLogger] ▶ REQUEST GET https://platform.runawayplay.com/dragons/api/mailbox
    Headers:
        Authorization: Bearer <token>
        X-Client-Platform: ios
    Body: (none)
[NetworkLogger] ◀ RESPONSE GET https://platform.runawayplay.com/dragons/api/mailbox
    HTTP 200
    Content-Type: application/json
    ...
    Body: {"mailItems": [...]}
```

## Build

```sh
make clean && make package THEOS_PACKAGE_SCHEME=rootless
```

## Inject

```sh
cyan -i <input.ipa> -o <output_patched.ipa> -f <tweak.deb> -u
```

## Viewing logs

```sh
log stream --predicate 'eventMessage contains "NetworkLogger"' --level debug
```

Or view in Console.app filtering for `NetworkLogger`.