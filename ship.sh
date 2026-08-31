#!/usr/bin/env bash
#
# Build and ship a new build to the testers.
#
#   ./ship.sh "fixed the fee showing wrong on job cards"
#
# Bumps the build number, builds a signed release APK, and distributes it via
# Firebase App Distribution. Testers get a notification in the App Tester app.
#
# The bump is the point of this script: App Distribution keys a release on the
# version, so shipping twice on the same number overwrites the first rather
# than creating a new release, and testers are never told.
set -euo pipefail

cd "$(dirname "$0")"

NOTES="${1:-}"
if [ -z "$NOTES" ]; then
    echo "What changed? Pass a note:"
    echo "  ./ship.sh \"fixed the fee on job cards\""
    exit 1
fi

APP_ID="1:113352609030:android:dc79fb00d2c5b8aa062287"
export GOOGLE_APPLICATION_CREDENTIALS="C:/THTAPP/tht-app-60862-firebase-adminsdk-fbsvc-022556110f.json"

if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "Firebase service-account key not found at:"
    echo "  $GOOGLE_APPLICATION_CREDENTIALS"
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
# `flutter analyze` exits non-zero for *any* issue, infos included, and this
# project carries a handful of long-standing ones. Only errors and warnings
# should stop a release.
ANALYSIS=$(flutter analyze lib test 2>&1 || true)
echo "$ANALYSIS" | tail -3
if echo "$ANALYSIS" | grep -qE "^\s+(error|warning) -"; then
    echo
    echo "errors or warnings above - fix before shipping"
    exit 1
fi

echo
echo "── testing ──"
flutter test || { echo "tests failed - fix before shipping"; exit 1; }

# ── Build ────────────────────────────────────────────────────────────────────
echo
echo "── building ──"
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"

# Signed with the real upload key, not the debug one? A debug-signed build
# cannot be installed over a properly signed one, so catching it here saves a
# confusing failure on someone else's phone.
if [ ! -f android/key.properties ]; then
    echo
    echo "WARNING: android/key.properties is missing, so this build is"
    echo "debug-signed and testers will not be able to install it over the"
    echo "previous release. Restore the keystore before shipping."
    exit 1
fi

# ── Ship ─────────────────────────────────────────────────────────────────────
echo
echo "── distributing ──"
firebase appdistribution:distribute "$APK" \
    --app "$APP_ID" \
    --groups testers \
    --release-notes "$NOTES"

echo
echo "shipped $NAME+$NEXT"
echo "remember to commit the pubspec version bump"
