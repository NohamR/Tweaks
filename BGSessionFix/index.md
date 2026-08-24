Tweak that redirects background NSURLSession configurations to foreground (default) configurations, for use when developing/debugging apps in the iOS Simulator.

The iOS Simulator does not run `nsurlsessiond`, the system daemon that backs `NSURLSession` background transfers. Any app that uses `backgroundSessionConfigurationWithIdentifier:` to download or upload files (so the transfer can survive app suspension/termination on a real device) will fail in the Simulator with errors such as:

```
No XPC connection in Simulator
BackgroundSession <...> an error occurred on the xpc connection to setup
the background session: ... connection to service named com.apple.nsurlsessiond
BackgroundSession <...> failed to create a background NSURLSessionDownloadTask,
as remote session is unavailable
Task <...> finished with error [-1] "unknown error"
```