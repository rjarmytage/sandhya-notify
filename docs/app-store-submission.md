# App Store Submission Checklist — Sandhya

Tracks the non-code requirements from the original brief. Nothing here blocks
development; it matters at submission time.

## 1. Privacy policy URL
Draft text is at [privacy-policy.md](privacy-policy.md). Needs to be published
at a live, stable URL before submission (e.g. a simple GitHub Pages page or a
one-page site) and that URL entered in App Store Connect. Fill in `[DATE]` and
`[YOUR CONTACT EMAIL]` before publishing.

## 2. App Privacy "nutrition label" (App Store Connect → App Privacy)
Declare:
- **Data collected:** Location (Precise).
- **Used for:** App Functionality only.
- **Linked to identity:** No.
- **Used for tracking:** No.

This matches [`PrivacyInfo.xcprivacy`](../SandhyaApp/SandhyaApp/Resources/PrivacyInfo.xcprivacy)
in the app bundle and the privacy policy text — keep all three in sync if
anything changes. **If any analytics, crash reporting, or third-party SDK is
ever added, this declaration (and the privacy policy) must be revisited.**

## 3. Info.plist location usage strings
Already set in [`project.yml`](../project.yml) (XcodeGen writes them into the
generated Info.plist):
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationWhenInUseUsageDescription`

Wording is plain-language and matches the privacy policy's framing ("only to
calculate local sunrise/sunset/solar noon times... never stored or transmitted").

## 4. App Review Notes (App Store Connect → Version → App Review Information)
Suggested draft:

> Sandhya requests "Always" location access because its core feature — automatically
> recalculating today's sandhya (prayer) times as the user travels to a new city or
> region — needs to keep working even when the app isn't open. We use CoreLocation's
> significant-change location service (not continuous GPS tracking) specifically to
> minimize battery impact and background access. Location is used only to compute
> local sunrise/sunset/solar-noon times on-device; it is never stored, transmitted,
> or used for tracking. Users can also opt out of automatic location entirely and
> pick a fixed location manually in Settings.

## 5. Screenshots
3–6 recommended, showing: Home screen (times + current/next indicator), Settings
screen (toggles), and the manual location picker. Capture at the current
required device size per App Store Connect at submission time.

## 6. Xcode/SDK version
No action needed — build with whatever current Xcode is at submission time.

## 7. Apple Developer Program enrollment
Required and active before submission (not yet confirmed as part of this build).
