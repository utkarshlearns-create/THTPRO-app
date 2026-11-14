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

### 0.2 The D-U-N-S number — start this today

Nothing in this document takes longer, and it is the only step whose clock
runs whether or not anyone is working. Both stores want the same number, so
it is applied for once and used twice.

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
| Email | `support@thehometuitions.in` — the domain address, not the Gmail on the signboard. A Gmail does not fail the application, but it is the slowest kind of applicant to verify. |
| Phone | **A number somebody will answer.** See the warning below. |
| Year started | 2026 (the CIN says so: `…UP2026PTC…`) |
| Headcount, rough annual revenue | Approximations are fine |

**Two things about this particular company.**

It was incorporated in **2026**, which means there is almost certainly **no
existing D&B record** to find — search for it anyway, then expect to file a
fresh application and to get the verification call. A company this new is also
the kind D&B checks most carefully.

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
D-U-N-S record ends up holding, that is **character for character** what must
be typed into Apple enrolment and into the Play Console. "Pvt Ltd" versus
"Private Limited" is enough to stall both. Once the number comes through,
screenshot the record and copy from the screenshot, never from memory.

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

### 0.4 `android/app/google-services.json` — **the one thing still blocking a build**

Gitignored and absent. Gradle cannot even start without it, because the
`com.google.gms.google-services` plugin reads it at configure time, so this is
now the only thing between this machine and a signed `.aab`.

Firebase console → project **`tht-app-60862`** → Project settings → Your apps
→ **`com.thehometuitions.app`** → **google-services.json** → download it to
`android/app/google-services.json`. Never commit it.

If no Android app is listed under that project, add one with exactly that
package name. While you are there, paste in the upload key's SHA-1 from 0.3 —
nothing in this app needs it today (there is no Google Sign-In), but it costs
nothing now and is a half-hour of confusion later.

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

Questions: support@thehometuitions.in · WhatsApp +91 6387488141
```

**Category** — Education. **Tags** — Tutoring, Education.
**Contact** — `support@thehometuitions.in`, `https://www.thehometuitions.com`,
phone `+91 6387488141`.
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

```bash
./release.sh                     # preflight, analyze, 217 tests, then the .aab
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
   `tht-app-60862`, add an **iOS app** with whichever bundle id 7.3 settles on,
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
