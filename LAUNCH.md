# Launch checklist — Play Store and App Store

Everything the two consoles ask for, answered once, so nobody has to re-derive
it at upload time. The answers are taken from the code, not from memory — where
a claim needs checking, the file that settles it is named.

Sections 0–6 are Android and Play. Section 7 is iOS and the App Store, which
needs a Mac and a second set of answers.

Build the bundle with [`release.sh`](release.sh). `ship.sh` is the other path:
an APK for the Firebase App Distribution testers. Play will not accept an APK.

---

## 0. What is missing before a build can even run

Five things. Three of them are now done and are recorded below so nobody
repeats them; what is left is **0.4** (one file, from the Firebase console)
and **0.5** (the Play account, which waits on the D-U-N-S in 0.2).

Two of those three took far longer than they should have, because the machine
itself was the obstacle rather than the app. 0.1 therefore ends with four
subsections on the disk, the NDK, the pub cache and Developer Mode. **If a
build fails and the error names a Kotlin compiler, a Guava jar, or a cache
directory, read those four before reading the stack trace.** Of the four, the
only one still needing a human is **Developer Mode**, which is one toggle in
Windows settings and cannot be set without administrator rights.

### 0.1 A working Android toolchain — **done, 14 Nov 2026**

The machine had a bare `%LOCALAPPDATA%/Android/sdk` and no JDK at all, so
neither `flutter build appbundle` nor `keytool` could run. Android Studio was
not needed; three pieces were, and they total about 300 MB rather than 1 GB:

```bash
winget install --id Microsoft.OpenJDK.17 --exact --silent

# cmdline-tools, unzipped to %LOCALAPPDATA%/Android/sdk/cmdline-tools/latest
# from https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip

sdkmanager --licenses                 # accept all
sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"
flutter config --android-sdk "%LOCALAPPDATA%/Android/sdk"
```

Flutter 3.44 wants **compileSdk 36, targetSdk 36, minSdk 24** — the numbers
come from `FlutterExtension.kt` in the SDK, not from this repo, which is why
`android/app/build.gradle.kts` reads `flutter.compileSdkVersion` rather than a
literal. The README's claim of `minSdk 23` is stale.

Set once, at user scope, so a new terminal inherits them:
`JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot`,
`ANDROID_HOME=%LOCALAPPDATA%\Android\sdk`, and both `bin` folders on `PATH`.

`flutter doctor -v` now reports **`[√] Android toolchain … All Android
licenses accepted`**. The Visual Studio warning it also prints is about
building Windows desktop apps and has nothing to do with Android.

One trap, if any of this is ever redone: **unzip cmdline-tools straight into
the SDK folder.** Unzipping it under a long scratch path fails part-way on
Windows' 260-character path limit, and the error names a Guava jar rather than
the real cause.

#### The disk, which is a real prerequisite

The first release build on this machine did not fail on anything in this
document. It ran for 3m43s and died on:

```
java.io.IOException: There is not enough space on the disk
Could not open cache directory ... \.gradle\caches\9.1.0\transforms\...
```

`C:` was **100% full — 17 MB free of 147 GB**, while `D:` had 268 GB free. A
Gradle build wants several GB of room for its transform cache alone, so the
fix was to stop caching on the full drive:

```bash
setx GRADLE_USER_HOME "D:\gradle-home"      # user scope, so new shells inherit it
# then move the existing cache over and delete the original
```

That alone took `C:` from 170 MB to 1.6 GB free. It is enough to build, but it
is not comfortable, and a full system drive will keep producing failures that
look like code problems. Where the space went, measured 14 Nov 2026:

| Location | Size | Safe to reclaim? |
|---|---|---|
| `ProgramData\McAfee` | 15.6 GB reported, 2.9 GB real | **Removed 14 Nov 2026.** See the note below |
| `AppData\Local\Programs` | 11.2 GB | Installed applications — review, do not sweep |
| `AppData\Local\Google` | 10.4 GB | Chrome's cache can be cleared; the profile cannot |
| `hiberfil.sys` | 6.3 GB | `powercfg /h off` removes it, at the cost of hibernate |
| `AppData\Local\npm-cache` | 5.6 GB | Yes — `npm cache clean --force` |
| `.gemini` | 6.3 GB | **No** — despite the name this is Antigravity IDE's data, not a Gemini CLI cache |
| `AppData\Local\Docker` | 3.2 GB | Yes — `docker system prune -a` |
| `ms-playwright`, `pip` | 1.4 GB | Yes — both re-download on demand |

**Check `df -h /c` before blaming a build failure on the build.** This one cost
an hour of looking in the wrong place.

One caveat on that table: it measures logical file size, which is not the same
as space on the disk. McAfee looked like the biggest prize in it — 16 GB,
of which 15.8 GB was a single runaway `ProgramData\McAfee\WPS\log` directory.
Uninstalling both of its products (`wps` and `WebAdvisor`, each of whose
uninstallers exits 0 silently) took that whole tree away and returned **2.9
GB**, not 16. Log files compress well and NTFS was evidently storing them
compressed, so measure a reclaim by `C:`'s free space before and after, never
by what `Measure-Object -Property Length` adds up to.

Windows Defender takes over on its own: `Get-MpComputerStatus` reported
`AntivirusEnabled`, `RealTimeProtectionEnabled` and `AMServiceEnabled` all true
immediately afterwards, with no reboot. A few `*.deleted` stubs stay behind in
`C:\Program Files\McAfee` because removing them needs administrator rights;
Windows clears them at the next restart.

#### Everything a build caches now lives on D:

Moving only the Gradle cache was not enough. The second build got past the
cache and then tried to auto-install the NDK, which Flutter 3.44 pins through
`ndkVersion = flutter.ndkVersion` in `android/app/build.gradle.kts`:

```
Failed to install the following SDK components:
    ndk;28.2.13676358 NDK (Side by side) 28.2.13676358
```

That is a 2.2 GB unpack on top of a ~600 MB download, into an SDK that was
still on the full drive, so it emptied `C:` to zero bytes and left a 1.4 GB
half-finished `sdk/.temp` behind. The whole SDK therefore moved too, and the
three environment variables below are now set at **user scope**:

| Variable | Value | What it stops filling `C:` with |
|---|---|---|
| `GRADLE_USER_HOME` | `D:\gradle-home` | Gradle's dependency and transform caches |
| `ANDROID_HOME`, `ANDROID_SDK_ROOT` | `D:\Android\sdk` | platforms, build-tools, and the NDK |
| `GRADLE_OPTS` | `-Djava.io.tmpdir=D:\gradle-tmp` | the JVM's scratch files during a build |

`flutter config --android-sdk "D:/Android/sdk"` was run to match, and the NDK
was installed with `sdkmanager.bat --sdk_root="D:\Android\sdk"
"ndk;28.2.13676358"` — note `.bat`, since the bare name is not executable from
a POSIX shell on Windows.

Between that and clearing the npm cache, `C:` went from 0 bytes to 8.2 GB free
and stayed there through a build, which is the real test.

#### The pub cache has to live on the same drive as the repo

With the disk and the NDK sorted, the build ran for 8m50s and then failed three
plugins at once — `share_plus`, `image_picker_android` and
`shared_preferences_android`, all on `compileReleaseKotlin`. The headline said
only `A failure occurred while executing BuildToolsApiCompilationWork`, which
is not a cause. The cause was forty lines down a nested stack trace:

```
java.lang.IllegalArgumentException: this and base files have different roots:
  C:\Users\...\AppData\Local\Pub\Cache\hosted\pub.dev\share_plus-10.1.4\...\MethodCallHandler.kt
  and D:\Downloads\THTPRO-app\android
```

Kotlin's incremental compiler makes each source path relative to the module it
belongs to. On Windows there is no relative path between two different drive
letters, so the call throws, the incremental cache cannot be closed, and the
compile daemon dies. The repo is on `D:` and the pub cache was on `C:`, which
is all it took.

```bash
setx PUB_CACHE "D:\pub-cache"     # user scope
flutter pub get                   # re-resolves into the new location
```

That is 146 packages re-downloaded and all 62 Android plugin paths in
`.flutter-plugins-dependencies` moved to `D:`. It frees space on `C:` as a
bonus — the old cache under `AppData\Local\Pub\Cache` can be deleted once a
build has proved the new one works.

#### Developer Mode, which `flutter clean` will teach you about

`flutter pub get` creates symlinks under `.dart_tool`, and Windows only allows
that for an administrator or with **Developer Mode** on. With it off, pub get
prints

```
Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

and **exits 1**, which fails the whole build before Gradle is even invoked.

This is easy to miss, because a build can succeed for a long time without it:
the symlinks survive in `.dart_tool` from whenever they were last created, and
nothing re-checks them. `flutter clean` deletes that directory, and the next
build cannot rebuild it.

Turn it on once — **Settings → System → For developers → Developer Mode** — or,
elevated:

```
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" ^
    /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
```

The escape hatch, if neither is possible, is `flutter build appbundle
--release --no-pub`: pub resolution writes `package_config.json` and
`.flutter-plugins-dependencies` *before* it reaches the symlink step, so those
files are already correct and Gradle has everything it needs. It works, but it
means every dependency change needs a successful `pub get` first, so it is a
workaround and not the fix.

### 0.2 The D-U-N-S number — **issued 16 Nov 2026**

| | |
|---|---|
| **D-U-N-S** | **`311281860`** |
| Issued to | THT EDUCATION TECHNOLOGIES PRIVATE LIMITED |
| Via | Apple's lookup form, `developer.apple.com/enroll/duns-lookup/` |
| Turnaround | **same day** — no verification call, no documents |

Apple Developer Relations mailed the number back within hours of the form
being submitted, which is far faster than the five business days their own
page promises. The rest of this section is kept as written because the same
number now has to be typed into the Play Console and into Apple enrolment,
and the matching rules below are what stall those.

Nothing else in this document takes longer than this step did, and it was the
only one whose clock ran whether or not anyone was working. Both stores want
the same number, so it is applied for once and used twice.

**What it is.** A free nine-digit identifier Dun & Bradstreet issues to a
business. One per legal entity per address. Apple requires it to enrol as an
organisation; Google requires it for an organisation Play account. We have a
registered company, so both stores take the organisation route and both want
this number.

**Where to apply.** Use **Apple's own form**, even though the number is also
for Google: it is free, it searches the existing D&B database first, and it
feeds straight into Apple enrolment.

```
https://developer.apple.com/enroll/duns-lookup/
```

Search the legal entity name there before applying for anything. A company
registered in India often **already has** a D-U-N-S number it never asked for,
and if so you are done in two minutes — just confirm the address and phone on
the record are current, because those are what get verified later.

**What goes in the form.** The entity is a registered private limited
company, so every store takes the organisation route. These are the answers,
and they are the same answers for Apple enrolment and for the Play Console —
copy them from here rather than retyping, because a one-character difference
between the three is what stalls an application:

| Field | Value |
|---|---|
| Legal entity name | **THT EDUCATION TECHNOLOGIES PRIVATE LIMITED** — the registered name, not the brand. "The Home Tuitions" is the brand and belongs only in the store listing. |
| Legal form | Private Limited Company |
| CIN | `U85500UP2026PTC250409` |
| Registered address | Plot No. 310, Khasra No. 73 Min., Aziz Nagar, Madiyaon, Lucknow – 226021, Uttar Pradesh |
| Website | `https://www.thehometuitions.com` |
| Email | A **company-domain** address, not the Gmail on the signboard. `support@thehometuitions.com` is the one to use: it is a live Hostinger mailbox and it is on the same domain as the Website field above, so a verifier sees one organisation rather than two. `thehometuitions.in` is the company's second site and would also pass, but matching the declared website costs nothing. A Gmail does not fail the application; it is simply the slowest kind of applicant to verify. **Whichever is used, confirm somebody can actually open that inbox** — the number arrives there and nowhere else. |
| Phone | **A number somebody will answer.** See the warning below. |
| Year started | 2026 (the CIN says so: `…UP2026PTC…`) |
| Headcount, rough annual revenue | Approximations are fine |

**Two things about this particular company.**

It was incorporated in **2026**, so the expectation here was that no D&B
record existed, that a fresh application would be filed, and that a
verification call would follow. **None of that happened** — the number came
back the same day, unprompted, with no call and no documents asked for. Either
a record already existed against the CIN or D&B matched the registrar data
directly. Worth remembering before anyone budgets a week for this again.

And the registered office above is **not** the address the website publishes
(the footer carries the working office, Verma Complex, A-mart Chauraha). For
anything a registrar can check — D-U-N-S, Apple, Play — use the **registered**
office, because that is what matches the MCA record. Worth deciding separately
which of the two should be the public developer address on the Play listing,
since Play shows it to everyone.

**Keep these to hand** — Apple or Google may ask for any of them: Certificate
of Incorporation, company PAN, GST certificate, and a utility bill or bank
statement in the company's name at the registered address.

**Who enrols.** Apple requires the person enrolling to have **legal authority
to bind the company** — a director, or someone holding written authorisation
from one. Enrol in a director's name from the start; handing it over later is
a support ticket, not a setting.

**The warning.** D&B verifies a new record by **telephoning the number on the
application**, and whoever answers has to confirm the business details. An
unanswered or unrecognised call is the most common reason an application sits
for weeks. Tell the office the call is coming.

**Timeline.** Apple's form usually answers in up to **5 business days**; in
India it can run longer, and a verification call that goes unanswered restarts
the wait. Plan on a week, hope for two days.

**The one thing that causes rejections later.** Whatever name and address the
D-U-N-S record holds is **character for character** what must be typed into
Apple enrolment and into the Play Console — Google's own wording is that the
legal name and address in the payments profile must *exactly* match the Dun &
Bradstreet profile. "Pvt Ltd" versus "Private Limited" is enough to stall
both.

The name on the issued record is confirmed: **THT EDUCATION TECHNOLOGIES
PRIVATE LIMITED**, exactly as Apple's mail spelled it. The **address** on the
record has not been seen and is the one remaining unknown. Look it up at
D&B's free lookup before filling the Play payments profile, and if it differs
from the registered office above, correct it at D&B **first** — changing it
after Play has verified is the slower repair.

**What the organisation route buys.** Enrolling as the company rather than as
a person is not only about the name on the listing:

| | Organisation (this is us) | Individual |
|---|---|---|
| D-U-N-S | required | not needed |
| Play 12-tester rule | **exempt** | 12 testers, 14 continuous days, before production |
| Store shows | THT Education Technologies Private Limited | a person's name |
| If the founder leaves | the account belongs to the company | the account belongs to them |

The exemption is the part worth noticing: as an individual, Play would hold the
app in closed testing for a **fortnight** before it could even apply to go
live. As the company, there is no such wait — which is most of the reason the
D-U-N-S is worth starting today rather than after the build works.

### 0.3 A fresh upload keystore — **made, 14 Nov 2026**

The old one is gone; `C:/THTAPP/` no longer exists and there was no `.jks`
anywhere on the machine. A new one was generated, which is free and correct
**so long as nothing has ever been published to Play under the old key** — see
the caveat at the end of this section.

```
Keystore   C:/keys/tht-upload.jks        (JKS, RSA 2048, valid to 2054)
Alias      upload
SHA-1      C1:C9:83:41:83:9D:D2:77:EE:01:C0:4F:50:89:C7:76:23:4B:90:BF
Password   C:/keys/KEYSTORE-BACKUP-README.txt
```

`android/key.properties` is written and points at it, so `release.sh` will
sign with it. Neither that file nor the `.jks` is committed — `.gitignore`
refuses both, and `git check-ignore` confirms it.

**Two things still to do by hand, and they are not optional:**

1. **Copy `tht-upload.jks` somewhere off this machine** — a company Drive
   folder and a pen drive, say. This is the one item in this whole document
   that cannot be regenerated: every future update to the published app must
   be signed with this exact key, and a dead hard disk means the app can never
   be updated again.
2. **Move the password into a password manager, then delete the README.** A
   signing password in plain text next to the key it unlocks is a stopgap, not
   a home.

The SHA-1 above is worth keeping: it is what identifies this key to Google
Play and to Firebase, and it is the quickest way to confirm later that a build
was signed with the right one.

**The caveat.** If the app *was* ever published under the lost key, a new key
is useless — Play will reject the upload. The only route is Play Console →
**App integrity → Request upload key reset**, which Google takes a few days
over. Worth confirming in the Play Console before the first upload; it costs a
minute to check and several days to get wrong.

### 0.4 `android/app/google-services.json` — **done, 16 Nov 2026**

Gitignored, and now present. An earlier draft of this document said Gradle
"cannot even start" without it; that was wrong, and worth correcting because it
sent an hour of debugging in the wrong direction. A release build with the file
still missing configured cleanly and ran for 8m50s, compiling plugin after
plugin before dying on something else entirely. The
`com.google.gms.google-services` plugin reads the file in its own task,
`processReleaseGoogleServices`, which sits well into the execution phase —
so a build fails *late* without it, not early, and every other failure has to
be cleared before the file is even reached.

It is required all the same, because push notifications are a shipped feature
of the app and Firebase Messaging will not initialise without it. With the file
in place the very next build produced the bundle on the first attempt:
`bundleRelease` in 272.8s, `app-release.aab`, 61.0 MB, signed by the upload key
from 0.3.

**The Firebase project changed.** The app used to belong to `tht-app-60862` and
nobody here can sign in to it any more — the account that owns it is not ours
to reach. Rather than chase it, a new project was created on 16 Nov 2026:

| | |
|---|---|
| Project id | `tht-app-8009` |
| Project number | `672816783019` |
| Android app id | `1:672816783019:android:8c657d7d0d99b5fdfde1ee` |
| Package | `com.thehometuitions.app` |

Three things were coupled to the old project and all three had to move with it:
`ship.sh`'s `APP_ID`, `ship.sh`'s service-account path, and the backend's
`FIREBASE_CREDENTIALS` on the Render env group. **Miss the third and nothing
breaks loudly** — the server keeps accepting pushes and keeps sending them to a
project the app no longer belongs to, so every notification is dropped in
silence. Whoever changes the Firebase project next should change that env var
in the same sitting, and remember that a Render env write restarts nothing
until a deploy is triggered by hand, for the web service *and* for the three
crons.

Analytics was left off deliberately at project creation: the app ships no
analytics SDK, so turning it on only adds another account to link. No SHA-1 was
registered either. `pubspec.yaml` pulls `firebase_core` and
`firebase_messaging` and nothing else, and a SHA-1 matters for Google Sign-In,
phone auth and Dynamic Links — none of which this app uses. Adding one later
costs nothing if that ever changes.

To re-download the file: Firebase console → project **`tht-app-8009`** →
Project settings → Your apps → **`com.thehometuitions.app`** →
**google-services.json** → save it at `android/app/google-services.json`.
Never commit it.

One consequence worth expecting: FCM tokens are issued per project, so every
install that registered against the old project is unreachable. That cost
nothing here, because the app has never been on Play.

### 0.5 A Play Console developer account

$25, once, ever. Two things about it decide the calendar more than anything in
this document:

- **Identity verification.** An organisation account needs the **D-U-N-S
  number from section 0.2** plus the company's legal name and registered
  address, verified against them. Google also wants a contact email and phone
  it can reach. The same details, character for character, as Apple's.
- **The 12-tester rule — does not apply to us.** A **personal** developer
  account created after November 2023 must run a closed test with 12 testers
  who stay opted in for 14 continuous days before it may even apply for
  production access. **Organisation accounts are exempt**, and we enrol as
  THT Education Technologies Private Limited, so the app can go to production
  as soon as it is ready and reviewed. Internal testing first is still the
  right call (section 6) — but that is our choice about quality, not Google's
  two-week gate.

---

## 1. Store listing

**App name** (≤30 chars) — 17 used:

```
The Home Tuitions
```

Not "THTPRO". That was the internal codename and it was sitting in
`android:label` and `CFBundleDisplayName` until now.

**Short description** (≤80 chars) — 72 used:

```
Verified home tutors in Lucknow and one-to-one online tuition across India.
```

**Full description** (≤4000 chars):

```
The Home Tuitions connects families with verified home tutors in Lucknow, and
with one-to-one online tutors anywhere in India.

FOR PARENTS
• Post what your child needs — class, board, subjects, and your area — and we
  shortlist teachers who actually teach it, nearby.
• See each teacher's qualifications, subjects, experience and fee before you
  decide anything.
• Book a free demo class. Meet the teacher, watch them teach your child, and
  only then commit.
• Track the tuition after it starts: demo status, hiring, and your own record
  of every teacher who has taught your child.
• Nothing is charged to a parent for finding a teacher.

FOR TEACHERS
• Browse real, open home-tuition and online-tuition requirements in your own
  area and your own subjects.
• Apply to the ones that fit. No bidding, no auction.
• One profile, verified once: qualifications, subjects, classes and documents.
• Credits unlock a parent's contact details. You are shown the fee, the area
  and the requirement before you spend anything.
• Demo schedule, applications and earnings history in one place.

FOR SCHOOLS AND COACHING CENTRES
• Post faculty vacancies, or simply tell us the requirement and our
  institutional team shortlists for you and calls back — no account needed for
  that.

WHY FAMILIES USE US
Every teacher is interviewed and document-verified before a single parent sees
the profile. Demo classes are free. A teacher who does not suit the child is
replaced rather than argued about.

We work across Lucknow — Gomti Nagar, Indira Nagar, Aliganj, Jankipuram,
Hazratganj, Alambagh, Chinhat, Vikas Nagar, Mahanagar and the rest — and
online across India.

Questions: support@thehometuitions.com · WhatsApp +91 6387488141
```

**Category** — Education. **Tags** — Tutoring, Education.
**Contact** — `support@thehometuitions.com`, `https://www.thehometuitions.com`,
phone `+91 6387488141`.

> **`.com`, not `.in`.** This block said `.in` while section 0.2 said
> `.com`; they are now both `.com`, which is the domain of the website
> declared one line above, so a reviewer sees one organisation. But the
> address has to be *readable*, and right now nobody can open it: the
> Hostinger mailbox `support@thehometuitions.com` is live with 2FA on and
> an unknown password, and the panel offers no password reset. **Before
> this listing goes up, either recover it through Hostinger support or
> set a forwarder to a Gmail somebody reads daily.** An unreachable
> support address on a store listing is how an app loses an appeal it
> would otherwise have won.
**Privacy policy URL** — `https://www.thehometuitions.com/privacy-policy`
(live, 200; note `/privacy` is a 404 — do not paste that one).

---

## 2. Graphics

| Asset | Size | Status |
|---|---|---|
| App icon | 512×512 PNG, no transparency | **done** — [`store/play/icon-512.png`](store/play/icon-512.png) |
| Feature graphic | 1024×500 PNG, no transparency | **done** — [`store/play/feature-graphic-1024x500.png`](store/play/feature-graphic-1024x500.png) |
| Phone screenshots | ≥2, 1080px+ on the short side, 16:9 or 9:16 | capture from a device |
| Tablet screenshots | optional | — |

Both graphics are generated from the app's own artwork by
[`store/play/make_graphics.py`](store/play/make_graphics.py), so they cannot
drift from `assets/images/`. Re-run it if the icon or logo changes.

The store icon is **not** a plain downscale of the launcher icon: the launcher
artwork carries a wide margin, which is right on a home screen and wrong on a
listing where the tile is already small, so the script trims to the artwork's
own edges and re-pads to 8%.

Screenshots worth taking, in this order — they are the four screens that
explain the product without a caption:

1. Parent home with open requirements / the role picker on first launch
2. A teacher profile (qualifications, subjects, fee)
3. The teacher's job feed — real tuitions in their area
4. Demo / application tracking

Avoid a real parent's name, phone number or address in any screenshot. Use a
test account.

---

## 3. Data safety form

Answers follow the actual code. Permissions declared in
`android/app/src/main/AndroidManifest.xml` are only `INTERNET`,
`ACCESS_NETWORK_STATE` and `POST_NOTIFICATIONS` — **no location permission at
all**, so every area in the app is typed by the user, never read from the
device. There is no analytics SDK, no Crashlytics and no ad SDK.

**Does your app collect or share any of the required user data types?** Yes.

| Data type | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| Name | Yes | No | Yes | Account management, app functionality |
| Email address | Yes | No | Yes | Account management |
| Phone number | Yes | No | Yes | Account management, app functionality |
| Address (approximate, typed) | Yes | No | Optional | App functionality — matching a tutor to an area |
| Photos | Yes | No | Optional | App functionality — profile photo and KYC documents (`image_picker`) |
| Purchase history | Yes | No | Optional | App functionality — credit purchases via Razorpay |
| Device or other IDs | Yes | No | Yes | App functionality — the FCM push token (`firebase_messaging`) |
| App interactions | Yes | No | Yes | App functionality — applications, demos, tuition records |

- **Location** — not collected. The permission is not declared.
- **Financial info** — card and UPI details are entered inside Razorpay's own
  flow and never reach our app or servers. Declare purchase history only.
- **Shared with third parties** — No. Razorpay and Firebase are processors
  acting on our instruction, which Play's definition of "shared" excludes.
- **Encrypted in transit** — Yes. Every call is HTTPS
  (`lib/core/network/api_config.dart`). Tokens are stored in Keychain /
  EncryptedSharedPreferences.
- **Users can request data deletion** — Yes, both in-app and on the web.
  Deletion URL: `https://www.thehometuitions.com/delete-account`
  In-app path: **Profile → Sign-in and security → Delete my account**
  (backend: `DeleteMyAccountView`, `users/views.py`).
- **Committed to the Play Families policy** — No. Not a Families app.

---

## 4. Content rating & audience

- Questionnaire category: **Reference, News or Educational**
- No violence, no sexual content, no gambling, no drugs or alcohol references
- **Does the app allow users to interact or exchange information?** Yes —
  parents and teachers exchange contact details through it
- **Does it share the user's location with other users?** No
- Expected outcome: rated **3+ / Everyone**
- Target audience: **18 and over**. Account holders are adults — parents,
  teachers, institute staff. Children are discussed in the app, never users of
  it. Do not tick any under-18 age band, or the Families policy applies.
- Ads: **No ads**
- News app: **No**
- COVID-19 contact tracing: **No**
- Government app: **No**
- Financial features: **No** (credit top-ups are a purchase, not a financial
  product). Razorpay is the payment processor.

---

## 5. App access — review credentials

The app is login-gated past the explore screens, so Play review **will** reject
it without test credentials. Under **App content → App access**, add:

- *All or some functionality is restricted*
- One entry per role the reviewer should see: a **parent** login and a
  **teacher** login (phone + password, or the number and its OTP route — say in
  the notes which).
- In the instructions field, name the two tabs worth opening per role, and say
  that `/explore` and the tutor list work with no login at all.

Make these two accounts fresh, with no real tuition data on them, and leave
them alive. A disabled test account is the single most common reason an update
gets held.

---

## 6. Release steps

### 6.0 Before the first upload: Razorpay or Play Billing

**This is the one item that can fail the app after everything else has
passed, and it has not been decided.** Settle it before the `.aab` goes up,
not after a rejection.

The app ships `razorpay_flutter` ([`pubspec.yaml:37`](pubspec.yaml)) and takes
money inside the app for credits and plans
([`lib/features/wallet/services/checkout_service.dart`](lib/features/wallet/services/checkout_service.dart)).
Play's Payments policy requires **Google Play Billing** — and its 15–30% cut —
for purchases of *digital* goods and content consumed in the app. Taking that
money through Razorpay instead is the thing being judged.

**The defence is the real-world-services exemption.** Play exempts payments for
physical goods and for **services performed outside the app**. THT is a
marketplace: a credit buys a teacher the contact details of a family who wants
in-person tuition, and the tuition itself — the thing actually being paid for —
happens in somebody's home. That is the same shape as a tradesperson or
job-lead marketplace, and those bill outside Play legitimately.

**Why it is not automatic.** What the credit unlocks *is* a piece of data
inside the app, and a reviewer reading the purchase screen in isolation can
see a digital unlock rather than a lead fee. Two things decide which way that
reading goes:

1. **The purchase copy.** The lead sheet currently says *"You are buying the
   contact, not the job"*
   ([`lib/features/jobs/widgets/lead_terms_sheet.dart:88`](lib/features/jobs/widgets/lead_terms_sheet.dart)).
   That sentence exists to stop teachers thinking a credit guarantees work, and
   it is honest — but it also describes the purchase in exactly the digital
   terms the policy catches. Wording that leads with the real-world service
   ("a fee to be connected with a family for home tuition") says the same true
   thing and reads as the exemption rather than against it. **This is a product
   decision, not a code fix — it is not changed here.**
2. **The Play Console declaration.** The account currently answers *Earning
   money → Yes → in-app purchases*. If the decision is Razorpay under the
   exemption, that answer and the store listing have to describe the money
   the same way the app does, or the mismatch is itself the flag.

**The three ways out, cheapest first:**

| Option | What it costs | What it risks |
| --- | --- | --- |
| **Ship on Razorpay, claim the exemption** | Nothing. Revisit the purchase copy first. | A rejection on first review. Recoverable — Play lets you reply and appeal — but it adds days, and a second rejection on the same point is worse. |
| **Ask Play first** | A Play Console policy-support ticket, a few days, and a written answer to keep. | Only time. This is the answer to pick if the first submission must land clean. |
| **Add Play Billing for in-app credit top-ups** | Real work, and 15–30% of every in-app sale. | Nothing, policy-wise. Note the web checkout on `thehometuitions.com` is unaffected either way — Play's cut applies to purchases made *in the Android app*. |

**Recommendation:** open the policy ticket. It costs days, not money, and a
written answer from Play is worth more at review time than any reading of the
policy text here.

---

```bash
./release.sh                     # preflight, analyze, 237 tests, then the .aab
```

1. **Internal testing** first — upload the `.aab`, add yourself as a tester,
   install from the tester link on a real phone.
2. Re-check **login, a credit purchase and a push notification** by hand. R8
   shrinks and renames only in release builds, so those three are where a
   release-only break shows up, and no test catches it.
3. Promote to **Closed → Open → Production**, or straight to production once
   internal testing holds.
4. Commit the `pubspec.yaml` build-number bump that `release.sh` made. A
   versionCode Play has already seen is rejected forever.

First submission review takes longer than updates — allow a few days, and for a
brand-new developer account Google may also ask to verify the business.

---

## 7. The App Store (iOS)

The code is ready; the surrounding machinery is not. Nothing below is a change
to how the app behaves — it is an account, a Mac, and five iOS-only answers.

### 7.1 You cannot build it on Windows

An iOS release has to be compiled and signed by Xcode on macOS. There is no
flag, no SDK and no cross-compiler that removes that. Three real options:

1. **A Mac** (any Apple-silicon Mac will do) — `flutter build ipa`, upload with
   Transporter or Xcode. Simplest, if one is available.
2. **A cloud Mac CI** — Codemagic is the usual choice for Flutter and is driven
   entirely from a browser, so it works from this Windows machine. It signs and
   uploads to App Store Connect for you. Paid once past the free tier.
3. **A rented Mac by the hour** (MacStadium, MacinCloud) if it is a one-off.

Whichever it is, the first iOS build also runs `pod install` — there is no
`Podfile` in the repo yet because the iOS side has never been built. That is
expected, and Flutter generates it.

### 7.2 Apple Developer Program

**$99 a year**, and it must be renewed or the apps come down. An
**organisation** enrolment needs the **D-U-N-S number from section 0.2** —
the same one Play wants, applied for once — and is slower; an **individual**
enrolment needs no D-U-N-S and is usually approved in a day or two, but puts a
personal name on the store page. Decide which name should sit under
"Developer" on the listing before enrolling — changing it later means a new
account, not a setting.

### 7.3 Decide the bundle identifier

The two platforms currently disagree:

| | identifier |
|---|---|
| Android | `com.thehometuitions.app` |
| iOS | `com.thehometuitions.thtApp` |

Nothing is broken by that — they are separate namespaces — but one identifier
across both is worth having while nothing is published: it keeps the Firebase
project, the push certificates and every support conversation on one name.
Changing it is an Xcode step (**Runner → General → Bundle Identifier**, and the
`RunnerTests` target alongside it), so do it before the App Store Connect
record is created. After the record exists, the identifier is permanent.

### 7.4 Firebase and push on iOS

Push does not work on iOS the way it does on Android, and three pieces are
missing:

1. **`ios/Runner/GoogleService-Info.plist`** — Firebase console, project
   `tht-app-8009`, add an **iOS app** with whichever bundle id 7.3 settles on,
   download the plist, and drag it into the Runner target in Xcode. Gitignored,
   like its Android counterpart; never commit it.
2. **An APNs auth key** — Apple Developer portal → Keys → new key with **Apple
   Push Notifications service** ticked → download the `.p8` **once** (Apple
   will not give it twice) → upload it to Firebase under Project settings →
   Cloud Messaging → iOS app configuration. Without this, `getToken()` returns
   nothing and no notification ever arrives.
3. **The Push Notifications capability** — Xcode → Runner → Signing &
   Capabilities → **+ Capability → Push Notifications**. That writes a
   `Runner.entitlements` file, which the repo does not have yet because this
   has never been done. The `remote-notification` background mode it pairs with
   is already declared in `Info.plist`.

### 7.5 The privacy manifest

[`ios/Runner/PrivacyInfo.xcprivacy`](ios/Runner/PrivacyInfo.xcprivacy) is
written and matches the Play data-safety table in section 3. It is **not yet a
member of the Runner target**, because that is a change only Xcode can make:
drag it into the Runner group and check it appears under **Build Phases → Copy
Bundle Resources**. A missing or incomplete manifest is rejected at upload,
with no hint as to which API caused it.

### 7.6 Where Apple reviews differently from Google

Four things, and the first one is the only one that could cost money:

- **Payments — Apple's 3.1 rules.** Teachers buy credits inside the app. If
  Apple reads those credits as *digital content consumed in the app*, Guideline
  **3.1.1** applies and the purchase must go through **In-App Purchase**, at
  Apple's 30% (15% on the small-business programme) — Razorpay would be
  rejected outright. The argument against that reading is Guideline
  **3.1.3(e), "goods and services outside of the app"**: a credit unlocks a
  parent's contact details so a human being can teach a child in their home,
  which is a real-world service, the same exemption contractor-lead and
  home-services marketplaces run on. That is a defensible position and worth
  arguing in the review notes, but **it is the reviewer's call, not ours**.
  Have a fallback decided before submitting: either add IAP for iOS only, or
  hide the purchase screen in the iOS build and let teachers top up on the
  website. Do not discover this question on the day of the first rejection.
- **Account deletion in the app.** Mandatory since 2022, and **already done** —
  Profile → Sign-in and security → Delete my account.
- **Sign in with Apple.** Only required where a third-party social login is
  offered. The app has none (no `google_sign_in` dependency — the comment in
  `android/app/build.gradle.kts:38` that mentions it is stale), so this does
  not apply.
- **Demo account.** Same as Play: App Store Connect → App Review Information →
  a working parent login and a working teacher login, left alive.

### 7.7 iPhone only, or iPad too?

`TARGETED_DEVICE_FAMILY = "1,2"` — the project claims **iPhone and iPad**. The
App Store then demands iPad screenshots and a reviewer will open it on a 13"
iPad, where a layout built for a phone usually looks stretched rather than
wrong. For a first release, **iPhone only** is the smaller surface: Xcode →
Runner → General → Supported Destinations, remove iPad. Set it back once
somebody has actually sat with the app on an iPad.

### 7.8 Store assets iOS needs that Play does not

- **Screenshots per device size** — 6.9" iPhone (1320×2868) and 6.5"
  (1242×2688) at minimum, plus 13" iPad if 7.7 keeps iPad.
- **A 1024×1024 icon, no alpha channel.** Already generated and already
  opaque: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`.
- **Export compliance** — answered in `Info.plist`
  (`ITSAppUsesNonExemptEncryption = false`), so Connect stops asking on every
  upload.
- The same privacy-policy and support URLs as Play, plus a **marketing URL**
  if you want one (`https://www.thehometuitions.com`).

### 7.9 The order to do it in

```
D-U-N-S (if publishing as the company)  ──┐   weeks, start first
Apple Developer enrolment ($99)         ──┤
Mac or Codemagic access                 ──┘
        ↓
bundle id decided (7.3)
        ↓
Firebase iOS app + APNs key + capability (7.4)
        ↓
PrivacyInfo into the target (7.5), iPad decision (7.7)
        ↓
flutter build ipa  →  TestFlight  →  test login, payment, push by hand
        ↓
submit for review (expect 24-48h, longer for a first app)
```

Android and iOS can run in parallel; nothing in one blocks the other.
