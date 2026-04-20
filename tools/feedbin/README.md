# Installing the Feedbin Safari Extension on macOS

1. Download the [Feedbin app](https://apps.apple.com/us/app/feedbin/id1444961766)
2. The app includes the macOS safari extension ([docs](https://github.com/feedbin/feedbin-extension))

## Why not use a Brewfile?

Installing the Safari extension can't be handled via `mas` in a Brewfile because while the Feedbin
app can run on macOS, it is not actually a native macOS app; it's an iPad app that runs on macOS
via Catalyst.

So `mas "Feedbin", id: 1444961766` will always fail.
