# Sandhya

An iOS app that notifies you at the start of each of the three classical
sandhyas (Pratah, Madhyahna, Sayam), computed daily from the sun's real
position at your location — not fixed clock times.

## Opening the project

Open `SandhyaApp.xcodeproj` in Xcode and run on your device or a simulator.
No dependencies to install — everything is native SwiftUI/CoreLocation/
UserNotifications/MapKit, no package manager, no server.

**Before your first run on a real device:** in Xcode, select the `SandhyaApp`
target → Signing & Capabilities → set your own Team, since the checked-in
project has no signing team configured.

## Project layout

```
SandhyaApp/
  App/            SandhyaApp.swift (entry point, background task wiring),
                  AppCoordinator.swift (ties settings + location + notifications together)
  Models/         SolarCalculator.swift (sunrise/sunset/true solar noon math),
                  Sandhya.swift (the three sandhya definitions + fixed windows),
                  DailySandhyaSchedule.swift (today's/tomorrow's windows + current/next lookup)
  Location/       LocationManager.swift (CoreLocation, significant-change monitoring),
                  LocationSearchService.swift (MapKit search + reverse geocoding),
                  SavedLocation.swift
  Notifications/  NotificationScheduler.swift (schedules/reschedules local notifications)
  Settings/       AppSettings.swift (UserDefaults-backed preferences)
  Views/          HomeView.swift, SettingsView.swift, LocationPickerView.swift
  Resources/      Assets.xcassets, PrivacyInfo.xcprivacy
SandhyaAppTests/  SolarCalculatorTests.swift (Swift Testing — validates the solar
                  math against known equation-of-time reference values)
docs/             privacy-policy.md, app-store-submission.md (drafts — see below)
```

## How the solar math works (verify this first)

`SolarCalculator.solarTimes(for:latitude:longitude:timeZone:)` implements the
NOAA Solar Calculator equations (Jean Meeus, *Astronomical Algorithms*),
accurate to roughly ±1 minute. It returns true solar noon (always computable)
plus sunrise/sunset (`nil` on days with no sunrise/sunset at extreme latitudes).

`SandhyaAppTests/SolarCalculatorTests.swift` checks this against real
astronomical facts, not just internal consistency — e.g. that true solar noon
at longitude 0 runs ~16 minutes *ahead* of clock noon in early November and
~14 minutes *behind* in mid-February (the Equation of Time's known extremes).
Run with **Cmd+U** in Xcode, or:

```bash
xcodebuild -project SandhyaApp.xcodeproj -scheme SandhyaApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Notification scheduling

`NotificationScheduler.rescheduleAll` computes the next 7 days of sandhya
windows for the current effective location and schedules a local notification
for each enabled sandhya (cancelling and replacing all previous ones each
time it runs). It's called from three places, so times stay fresh without the
user having to reopen the app daily:
- app launch / foreground,
- a significant-change location update (`LocationManager`),
- a periodic `BGAppRefreshTask` (registered in `SandhyaApp.swift`, re-arms
  itself roughly every 12 hours).

## Regenerating the Xcode project

The project is defined in [`project.yml`](project.yml) and generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen). A prebuilt XcodeGen binary
lives at `.tools/xcodegen` (not committed — see below) for regenerating after
editing `project.yml` directly (e.g. adding a new target or Info.plist key):

```bash
./.tools/xcodegen generate
```

You generally *don't* need this for day-to-day work — adding files via Xcode's
own "New File…" updates the checked-in `.xcodeproj` directly. If `.tools/` is
missing (it's gitignored, since it's just a build tool binary), either rebuild
it from [XcodeGen's source](https://github.com/yonaskolb/XcodeGen) with
`swift build -c release --product xcodegen`, or install it via Homebrew
(`brew install xcodegen`) and use that instead.

## What's intentionally not built yet

- App icon is a placeholder slot (no image) — add real artwork before
  archiving for the App Store.
- Bundle identifier is `com.armytage.sandhya` — change it in `project.yml`
  (and regenerate) if you want a different one before you set up signing.
- See [docs/app-store-submission.md](docs/app-store-submission.md) for the
  submission-time checklist (privacy policy hosting, App Review notes,
  screenshots, etc.) and [docs/privacy-policy.md](docs/privacy-policy.md) for
  the policy draft that needs a couple of blanks filled in before publishing.
