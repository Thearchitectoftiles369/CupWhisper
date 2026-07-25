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

## Problem: plugin AAR requires compileSdk 36, project compiled against 34

Symptom: Gradle build fails with "Execution failed for task ':app:checkDebugAarMetadata'" (or a specific plugin module like ':image_picker_android:checkDebugAarMetadata'), listing multiple androidx dependencies (activity, core-ktx, core, navigationevent) that "require... compile against version 36 or later of the Android APIs."

Cause: Newer plugin versions (e.g. image_picker 1.2.3) pull in androidx libraries built against Android API 36, but the Flutter-generated Gradle config still resolves compileSdk/targetSdk to 34 via `flutter.compileSdkVersion`/`flutter.targetSdkVersion` (this Flutter version's default lags behind the plugin's requirement).

## Fix 1: Hardcode compileSdk/targetSdk in android/app/build.gradle.kts

Replace:
compileSdk = flutter.compileSdkVersion
targetSdk = flutter.targetSdkVersion

With:
compileSdk = 36
targetSdk = 36

## Fix 2: Force compileSdk on ALL subprojects (including plugin modules)

Fix 1 alone is not enough - individual plugin modules (e.g. image_picker_android) are separate Gradle subprojects and still resolve their own compileSdk to 34 independently of the app module.

In android/build.gradle.kts, add a block that runs BEFORE the existing `evaluationDependsOn(":app")` block (order matters - registering afterEvaluate after evaluationDependsOn causes "Cannot run Project.afterEvaluate(Action) when the project is already evaluated"):

subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let {
            it.compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

Status: Workaround confirmed working on 2026-07-26, tested on Samsung Galaxy S23, Termux, Flutter 3.44.0, when adding image_picker ^1.1.2 (resolved to 1.2.3).
