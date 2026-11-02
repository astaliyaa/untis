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
| `Release (signed)` (`release.yml`) | **Actions → Release (signed) → Run workflow**, or pushing a tag `v*` | signed `.ipa` artifact + optional TestFlight upload |

> The *Run workflow* button only shows up once `release.yml` is on the repository's default
> branch, so merge this branch first.

### Secrets for the signed build

Add these in **GitHub → Settings → Secrets and variables → Actions → New repository secret**.

| Secret | What it is |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Your **Apple Distribution** certificate *with private key* as `.p12`, base64 encoded |
| `P12_PASSWORD` | Password you set when exporting the `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | The provisioning profile (`.mobileprovision`), base64 encoded |
| `KEYCHAIN_PASSWORD` | *(optional)* any random string |
| `ASC_KEY_ID` | *(TestFlight)* App Store Connect API key ID |
| `ASC_ISSUER_ID` | *(TestFlight)* Issuer ID shown above the key list |
| `ASC_KEY_P8` | *(TestFlight)* contents of `AuthKey_XXXXXX.p8` (paste as-is or base64) |

Optional **variables** (same page, *Variables* tab): `BUNDLE_ID` (only needed for a
wildcard profile) and `XCODE_VERSION` (e.g. `26.6`) to pin Xcode.

The workflow reads the bundle ID, team ID and profile type straight from the
provisioning profile. An *App Store* profile → TestFlight upload; *Ad Hoc* or
*Development* profile → installable `.ipa` for the devices in that profile.

#### 1. App ID (bundle identifier)
[developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list)
→ **+** → App IDs → App → e.g. `com.yourname.timetablestudio`. No capabilities needed.

#### 2. Distribution certificate (`.p12`)
On a **Mac**: Keychain Access → *Certificate Assistant → Request a Certificate From a
Certificate Authority* → save to disk. In the portal under Certificates → **+** →
*Apple Distribution*, upload the request and download the `.cer`. Double-click it, then
in Keychain Access → *My Certificates* right-click it → *Export…* → `.p12` with a password.

**Without a Mac** (Windows Git Bash, Linux, WSL):

```bash
openssl genrsa -out dist.key 2048
openssl req -new -key dist.key -out dist.csr -subj "/emailAddress=you@example.com/CN=Your Name/C=DE"
# upload dist.csr in the portal (Apple Distribution) and download distribution.cer, then:
openssl x509 -inform DER -in distribution.cer -out dist.pem
openssl pkcs12 -export -legacy -inkey dist.key -in dist.pem -out dist.p12 -passout pass:CHOOSE_A_PASSWORD
```

If your OpenSSL doesn't know `-legacy`, use
`-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1` instead. macOS's keychain
can't import the newer default p12 encryption.

#### 3. Provisioning profile
Profiles → **+** → *App Store Connect* (for TestFlight) or *Ad Hoc* (to install
directly on registered devices) → choose the App ID and the certificate → download.

#### 4. App record + API key (TestFlight only)
* [App Store Connect](https://appstoreconnect.apple.com) → Apps → **+ New App**, using the
  same bundle ID. The name can be anything that's free, and nothing gets submitted for review.
* Users and Access → **Integrations → App Store Connect API** → Team Keys → **+**
  (role *App Manager* or *Admin*). Note the **Key ID** and **Issuer ID** and download the
  `.p8` file. You can only download it once.

#### 5. Base64-encode the files

```bash
# macOS
base64 -i dist.p12 | pbcopy
base64 -i profile.mobileprovision | pbcopy
# Linux / Git Bash
base64 -w0 dist.p12
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("dist.p12")) | Set-Clipboard
```

Then run **Actions → Release (signed) → Run workflow**. Each run uses the run number as
build number, so TestFlight never rejects a duplicate. After the upload finishes, the build
shows up under *TestFlight* in App Store Connect within about 5–15 minutes. Add yourself
as an internal tester and install it with the TestFlight app.

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
