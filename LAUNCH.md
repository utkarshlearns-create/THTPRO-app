# Play Store launch checklist

Everything the Play Console asks for, answered once, so nobody has to re-derive
it at upload time. The answers below are taken from the code, not from memory —
where a claim needs checking, the file that settles it is named.

Build the bundle with [`release.sh`](release.sh). `ship.sh` is the other path:
an APK for the Firebase App Distribution testers. Play will not accept an APK.

---

## 0. Two things only you can do

**The upload keystore.** `android/key.properties` and the `.jks` it points at
are gitignored and not on this machine (`C:/THTAPP/` no longer exists). Without
them the build is debug-signed: Play rejects it outright, and a debug build
cannot be installed over a properly signed one. If the key is genuinely lost
*and* something has already been published under it, only Google can fix that —
Play Console → **App integrity → Request upload key reset**, a few days. If
nothing has ever shipped, make a fresh one; `release.sh` prints the `keytool`
line. Then back it up somewhere you will still have in three years.

**`android/app/google-services.json`.** Also gitignored, also absent. The
Gradle build cannot even start without it, because the
`com.google.gms.google-services` plugin reads it. Firebase console → project
**`tht-app-60862`** → Project settings → Your apps → `com.thehometuitions.app`
→ download. Never commit either file.

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

| Asset | Size | Source |
|---|---|---|
| App icon | 512×512 PNG, no transparency | `assets/images/icon.png` (1024², downscale) |
| Feature graphic | 1024×500 PNG/JPG, no transparency | needs making — `logo.png` on the brand orange |
| Phone screenshots | ≥2, 1080px+ on the short side, 16:9 or 9:16 | capture from a device |
| Tablet screenshots | optional | — |

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
