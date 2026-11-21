# GDUXI Studio iPhone app

A small Swift app that shows https://gduxi.studio full screen, for personal use on your own iPhone (not the App Store).

- `GDUXIStudio/` holds the code: `SiteViewController.swift` (the website view, loading bar, pull to refresh, outside links), `OfflineView.swift` (the "You're offline" screen) and `Assets.xcassets` (app icon, logo, colours).
- `project.yml` is the recipe for the Xcode project. Run `brew install xcodegen && xcodegen generate` on a Mac to make `GDUXIStudio.xcodeproj`.
- GitHub Actions (`.github/workflows/ios-app.yml`) builds it on every change to `ios/` and offers an unsigned `.ipa` plus simulator screenshots under the run's Artifacts.

Putting it on an iPhone: see the step-by-step guide linked from the pull request. In short, sign the unsigned `.ipa` with your Apple ID using Sideloadly (Windows or Mac), or open the project in Xcode on a Mac and press Run. With a free Apple ID the app stops opening after 7 days and has to be re-installed; a paid Apple Developer account (US$99 a year) makes it last a year.

Links to gduxi.studio stay in the app. Everything else (Figma, LinkedIn, email) opens in Safari or the right app. Website changes show up straight away; the app only needs rebuilding if this code changes.
