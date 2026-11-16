#!/usr/bin/env bash
#
# Build the Play Store bundle.
#
#   ./release.sh
#
# Bumps the build number, checks the project, and produces a signed .aab for
# the Play Console. Nothing is uploaded — Play takes the file by hand, and a
# release that goes live should be a decision somebody makes in the console
# rather than a side effect of running a script.
#
# Not the same job as ship.sh. That one builds an APK and pushes it to the
# Firebase App Distribution testers; Play will not take an APK at all. The two
# share a build number counter on purpose: a versionCode Play has already seen
# is rejected forever, even on a build it never published, so every build from
# either script has to move it on.
set -euo pipefail

cd "$(dirname "$0")"

# ── The two files that are not in the repo ───────────────────────────────────
#
# Both are gitignored, and deliberately: a service key or a keystore in the app
# repo is a key handed to anyone who ever clones it. They have to be put back on
# each machine that builds a release.

if [ ! -f android/app/google-services.json ]; then
    cat <<'MSG'
android/app/google-services.json is missing, and the Gradle build cannot even
start without it (the com.google.gms.google-services plugin reads it).

Get it from the Firebase console:
  console.firebase.google.com -> project tht-app-8009
  -> Project settings -> Your apps -> com.thehometuitions.app
  -> google-services.json

Save it at android/app/google-services.json. Never commit it.
MSG
    exit 1
fi

if [ ! -f android/key.properties ]; then
    cat <<'MSG'
android/key.properties is missing, so this build would be DEBUG-SIGNED and
Play would reject it (and a debug build can never be installed over a real
one). It needs to read:

  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=C:/path/to/upload-keystore.jks

If the upload keystore is genuinely lost and a release already exists on Play,
it cannot be recreated: ask Google to reset the upload key from the Play
Console (App integrity -> Request upload key reset). That takes a few days.

If nothing has ever been published, a fresh key is harmless:
  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
      -keysize 2048 -validity 10000 -alias upload

Keep the .jks and this file OUT of the repo, and keep a backup somewhere you
will still have in three years. Losing it costs days, every time.
MSG
    exit 1
fi

# ── Bump the build number ────────────────────────────────────────────────────
CURRENT=$(grep '^version:' pubspec.yaml | sed 's/version: //')
NAME="${CURRENT%%+*}"
CODE="${CURRENT##*+}"
NEXT=$((CODE + 1))

echo "  version  $NAME+$CODE  ->  $NAME+$NEXT"
sed -i "s/^version: .*/version: $NAME+$NEXT/" pubspec.yaml

# ── Check before spending four minutes on a build ────────────────────────────
echo
echo "── analyzing ──"
# `flutter analyze` exits non-zero for *any* issue, infos included. Only errors
# and warnings should stop a release.
ANALYSIS=$(flutter analyze lib test 2>&1 || true)
echo "$ANALYSIS" | tail -3
if echo "$ANALYSIS" | grep -qE "^\s+(error|warning) -"; then
    echo
    echo "errors or warnings above - fix before releasing"
    exit 1
fi

echo
echo "── testing ──"
flutter test || { echo "tests failed - fix before releasing"; exit 1; }

# ── Build ────────────────────────────────────────────────────────────────────
echo
echo "── building the bundle ──"
flutter build appbundle --release

AAB="build/app/outputs/bundle/release/app-release.aab"
[ -f "$AAB" ] || { echo "expected a bundle at $AAB and found none"; exit 1; }

echo
echo "built $NAME+$NEXT"
echo "  $AAB"
echo
cat <<'MSG'
Next, in the Play Console:
  1. Testing -> Internal testing -> Create new release -> upload the .aab
     (internal testing first, always: it is the only way to find out that a
     release build behaves differently from a debug one before strangers do)
  2. Install it from the tester link on a real phone and sign in. R8 strips
     code that only a release build strips, so login, payments and push are
     the three things worth re-checking by hand.
  3. Promote to Production when it holds up.

Remember to commit the pubspec version bump.
MSG
