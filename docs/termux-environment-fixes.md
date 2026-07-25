# Termux Environment Fixes

## Problem: aapt2 x86_64 incompatibility (ARM64 device)

Symptom: Gradle build fails with "AAPT2 Daemon startup failed" and "Syntax error: ) unexpected".

Cause: Gradle downloads a pre-built aapt2 binary from Maven targeting x86_64, incompatible with ARM64 devices running Termux.

## Fix 1: Force Gradle to use Termux ARM64 aapt2

In android/gradle.properties, add this line:

android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2

## Fix 2: aapt wrapper script for manifest extraction

Flutter calls "aapt dump xmltree apk AndroidManifest.xml" using old positional syntax, but aapt2 requires a --file flag instead. A plain symlink is not enough here - need a wrapper script.

Create this file at: PREFIX/opt/android-sdk/build-tools/VERSION/aapt (replace VERSION with the actual build-tools version folder, e.g. 36.0.0)

Wrapper script content:

#!/data/data/com.termux/files/usr/bin/bash
AAPT2=/data/data/com.termux/files/usr/bin/aapt2
if [ "$1" = "dump" ] && [ "$2" = "xmltree" ]; then
    shift 2
    APK="$1"
    shift
    FILE="$1"
    exec "$AAPT2" dump xmltree "$APK" --file "$FILE"
else
    exec "$AAPT2" "$@"
fi

Then run: chmod +x on that file.

Known limitation: even with this wrapper, "flutter run" still fails at the manifest-parsing step with "No application found for TargetPlatform.android_arm64" - the output format from aapt2 does not match what the Flutter tool expects to parse.

## Working workaround: manual install and launch

flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.cupwhisper.cupwhisper/com.cupwhisper.cupwhisper.MainActivity

## Important note

Every time a NEW build-tools version gets installed (for example going from 35.0.0 to 36.0.0), this fix must be reapplied for the new version folder, since Gradle re-downloads fresh x86_64 binaries each time.

Status: Workaround confirmed working on 2026-07-26, tested on Samsung Galaxy S23, Termux, Flutter 3.44.0.
