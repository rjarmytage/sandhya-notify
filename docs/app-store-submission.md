# App Store Submission Checklist — Sandhya Notify

Tracks the non-code requirements from the original brief. Nothing here blocks
development; it matters at submission time.

## 1. Privacy policy URL
Live at **https://rjarmytage.github.io/sandhya-notify/privacy-policy.html**
(hosted via GitHub Pages from this repo's `/docs` folder). Contact address:
sandhyanotifysupport@gmail.com. Enter this URL in App Store Connect at
submission time.

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

> Sandhya Notify requests "Always" location access because its core feature — automatically
> recalculating today's sandhya (prayer) times as the user travels to a new city or
> region — needs to keep working even when the app isn't open. We use CoreLocation's
> significant-change location service (not continuous GPS tracking) specifically to
> minimize battery impact and background access. Location is used only to compute
> local sunrise/sunset/solar-noon times on-device; it is never stored, transmitted,
> or used for tracking. Users can also opt out of automatic location entirely and
> pick a fixed location manually in Settings.

## 5. Screenshots
Three captured so far in [screenshots/](screenshots/), at native 6.9" resolution
(1320×2868, iPhone 17 Pro Max) — the current largest iPhone class:
- `01-home.png` — today's times with the "Next" banner
- `02-settings.png` — toggles, advance-notice wheel, location mode
- `03-location-picker.png` — manual location search/map picker

3–6 is standard practice; these three cover the core flows. Re-verify the
exact required pixel dimensions in App Store Connect at submission time, in
case they've changed.

## 6. Xcode/SDK version
No action needed — build with whatever current Xcode is at submission time.

## 7. Apple Developer Program enrollment
Required and active before submission (not yet confirmed as part of this build).
