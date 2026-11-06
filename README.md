# Timetable Studio

An iOS app for producing timetable-app screenshots and screen recordings (ads, store
pages, presentations). It recreates the layout of a school timetable app with dark mode,
a week/day grid, lesson sheet, messages and profile. **Everything is editable** on the
device: periods, exams, cancellations, substitutions, holidays, messages, names and the
clock.

The app is written in SwiftUI and doesn't use any third-party logos or artwork. All
demo content is fictional.

## What you can do in the app

| Where | How |
|---|---|
| Add a period | Tap an empty slot in the timetable, or **⋮ → Add period** |
| Edit / duplicate / delete | Long-press a period, or open it and use **⋮** in the sheet |
| Cancellation | Set *Type → Cancelled*: red frame and crossed-out text |
| Substitution | Set *Type → Substitution*: the original teacher, room or subject is shown crossed out next to the new one |
| Exam | Set *Type → Exam* and give it a name. It also appears under **Home → My events** |
| Additional period / event | *Type → Additional period / Event* |
| Holiday column | **⋮ → Add holiday** |
| Copy a week | **⋮ → Copy this week to… → next N weeks** |
| Day / week view | Tap a day in the header (back: tap the header again) or use **⋮** |
| Names, school, class, language, simulated date & time, time grid, absences, backup | **Studio settings**: timetable **⋮** menu, long-press the school name on Home, or tap the account card in Profile |

*Use custom date & time* in Studio settings controls which day is highlighted orange,
which periods are dimmed as "past", and what the Home card shows ("Tomorrow", "+2
periods"…).

## Building

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen),
so no `.xcodeproj` is committed.

```bash
brew install xcodegen
xcodegen generate
open TimetableStudio.xcodeproj
```

It needs Xcode 26 or later. The iOS 26 SDK gives the Liquid Glass tab bar and buttons.
The app runs on iOS 17 and later.

## GitHub Actions

| Workflow | Trigger | Output |
|---|---|---|
| `Build (unsigned)` (`build.yml`) | every push / PR | `TimetableStudio-unsigned-ipa` artifact. Proves it compiles; can be sideloaded with Sideloadly/AltStore |
| `Release (TestFlight)` (`release.yml`) | **Actions → Release (TestFlight) → Run workflow**, or pushing a tag `v*` | build uploaded to TestFlight + App Store-signed `.ipa` artifact |

### Secrets

The release only needs an App Store Connect API key. It doesn't need certificate or
provisioning-profile files, and you don't need a Mac. The archive is built unsigned and
ad-hoc signed (`scripts/adhoc_sign_archive.sh`). `xcodebuild -exportArchive` then signs
it with a cloud-managed Apple Distribution certificate from your account and uploads it.

| Repository secret | What it is |
|---|---|
| `APPLE_TEAM_ID` | 10-character Team ID: [developer.apple.com/account](https://developer.apple.com/account) → Membership details |
| `ASC_KEY_ID` | Key ID of an App Store Connect API key |
| `ASC_ISSUER_ID` | Issuer ID, shown above the key list |
| `ASC_KEY_P8` | Contents of `AuthKey_<KEY_ID>.p8`: paste the whole file, including the `BEGIN`/`END` lines (base64 also works) |
| `MATCH_PASSWORD` | Not used. Only needed for fastlane match, which also requires a private certificates repo and access token. Cloud signing replaces it |

Optional repository **variables** (*Variables* tab): `BUNDLE_ID` (default
`com.<repo owner>.timetablestudio`) and `XCODE_VERSION` (e.g. `26.6`) to pin Xcode.

**One-time setup in App Store Connect**

1. **API key with the Admin role.** Users and Access → Integrations → App Store Connect API →
   *Team Keys* → **+** → Access: **Admin**. Only Admin keys may use cloud-managed
   distribution certificates; with any other role, signing fails with a permission error.
2. **The app record.** The first workflow run registers the App ID (bundle ID) for you. If no
   App Store Connect app exists yet, the run stops with the exact bundle ID to use. Then go to
   Apps → **+** → *New App* → iOS, any free name, that bundle ID, any SKU, and run the
   workflow again. Nothing is submitted for review; TestFlight internal testing needs no
   review.

Each run uses `run_number.run_attempt` as the build number, so re-runs never collide.
After the upload, the build appears under *TestFlight* in App Store Connect within about
5–15 minutes. Add yourself as an internal tester and install it with the TestFlight app.

Each run's summary page shows the bundle ID, team and build number. The first step also
checks the key and explains 401/403 errors before the slow build starts.

## Project layout

```
project.yml                  XcodeGen spec (bundle id, iOS target, Info.plist keys)
TimetableStudio/
  App/                       App entry + tab bar
  Model/                     Data model, JSON persistence, demo data, EN/DE strings
  Theme/                     Colours & metrics, icons, shared components
  Home/ Timetable/ Messages/ Profile/ Studio/   Screens and editors
.github/workflows/           build.yml (unsigned CI), release.yml (signed / TestFlight)
```
