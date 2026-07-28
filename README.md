# The Home Tuitions — mobile app

The Flutter app for **parents, teachers and institutes**.

It runs against the same Django backend as [thehometuitions.com](https://www.thehometuitions.com),
so an account created on the website signs in here unchanged — same JWT, same
role, same wallet balance.

Staff tools (counsellor pipelines, team-leader reporting, superadmin) stay on
the website. Signing in with one of those roles lands on an explanation and a
link rather than a half-built dashboard.

## Running it

```bash
flutter pub get
flutter run                       # hits production api.thehometuitions.com
```

Point it somewhere else at build time — no source edits:

```bash
# Android emulator against a local `manage.py runserver`
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS simulator, desktop or web against localhost
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# Chrome, for a quick look at layout changes
flutter run -d chrome --web-port=5000
```

The web target is for previewing UI only. Browsers enforce CORS, which the API
does not open to `localhost`, so calls will fail there — test real flows on a
device or emulator.

## Layout

```
lib/
  core/
    auth/          session state, roles, the signed-in user
    models/        typed API responses
    network/       Dio client, token refresh, base URL
    repositories/  one per backend app; the only place endpoints are named
    theme/         colour, spacing and radius tokens, light + dark
    ui/            THTCard, StatTile, Pill, EmptyState, ErrorView, skeletons
    utils/         defensive JSON readers, error mapping, formatters
  features/
    auth/ parent/ tutor/ institution/ explore/ jobs/ wallet/ notifications/
```

Three conventions worth knowing before adding a screen:

**Repositories return a model or throw `ApiFailure`.** Nothing above that layer
sees a `DioException`, so no screen has to know how to read one. `ApiFailure`
also carries DRF's per-field validation errors, so a form can mark the offending
input instead of showing a banner.

**Models parse through `core/utils/json_x.dart`.** The API is not consistent
about types — `DecimalField` arrives as `"1500.00"`, method fields flip between
int and float, nullable columns are often absent rather than null. A bare cast
crashes a screen on a value that is merely unexpected.

**Every screen renders loading → error → empty → data** via `AsyncView`, with a
skeleton shaped like the real content so the layout does not jump on arrival.

## Platform notes

- Application ID: `com.thehometuitions.app`
- `minSdk 23` — required by Razorpay, `google_sign_in` and
  `flutter_secure_storage`
- Tokens live in Keychain / EncryptedSharedPreferences, never in plain
  preferences
- Typeface is Plus Jakarta Sans, bundled to match the website

Regenerate launcher icons or the native splash after changing
`assets/images/logo.png`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
