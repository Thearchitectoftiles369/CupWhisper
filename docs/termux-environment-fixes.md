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

## Problem: Flutter "native assets" feature breaks builds when any transitive dependency requires native compilation (jni, objective_c, etc.)

Symptom: Adding audio playback packages (audioplayers, just_audio) or other
plugins that transitively pull in packages using Dart's native-assets /
Dart FFI native-build system (e.g. `jni`, `jni_flutter`, used by
`path_provider_android` 2.3.0+) causes one of:

1. `Oops; flutter has exited unexpectedly: "Null check operator used on a
   null value"` with a stack trace pointing to
   `AndroidSdk.getNdkBinaryPath` / `AndroidSdk.getNdkClangPath` -
   flutter_tools cannot resolve a proper NDK Clang path in the Termux
   environment even when the NDK is installed.
2. If native-assets is disabled (`flutter config --no-enable-native-assets`)
   to work around (1): `Execution failed for task
   ':jni:configureCMakeDebug[arm64-v8a]'` - Gradle still tries to run a
   native CMake build for the `jni` package's own Android module
   regardless of the Dart-level feature flag, and the CMake binary itself
   fails with `Syntax error: ")" unexpected` (the classic ARM64/x86_64
   binary-incompatibility symptom seen before with aapt2).
3. If native-assets is instead force-enabled
   (`flutter config --enable-native-assets`) and a *different* dependency
   graph state removes `jni` but leaves an iOS-only package like
   `objective_c` in the resolved graph: `Target dart_build failed:
   Error: Package(s) objective_c require the dart assets feature to be
   enabled` even when only building for Android.

Cause: This Flutter version's (3.44.0) "native assets" build system
requires a working host C/C++ toolchain (NDK Clang for Android targets)
to satisfy any plugin's native-build hooks, even ones irrelevant to the
current target platform. Termux's Android-hosted toolchain does not
expose this in the shape flutter_tools expects, and downloaded prebuilt
native binaries (cmake, ndk clang, llvm-strip) are frequently
architecture-incompatible (x86_64 vs Termux's aarch64), producing
garbage/shell-parsed output instead of running.

## What did NOT reliably fix it

- Toggling `flutter config --enable-native-assets` on/off only moves the
  failure from one symptom to another (NDK crash vs CMake failure vs
  objective_c requirement) depending on which native-asset-requiring
  package happens to be in the resolved dependency graph at the time.
- `flutter clean` + `flutter pub get` can change which symptom you see
  (since pub's version resolution isn't fully deterministic across
  dependency changes) but does not remove the underlying incompatibility.

## Working workaround (current)

Avoid any package that transitively depends on `jni`/`jni_flutter` (or
any other native-assets-requiring package) entirely. Concretely:

- Do not add `path_provider` as a direct dependency unless you have
  confirmed the resolved `path_provider_android` version does not pull
  in `jni`/`jni_flutter` (run `flutter pub deps --style=list | grep -i
  jni` after adding to check).
- For audio playback specifically: both `audioplayers` (6.x, via
  `jni_flutter`) and `just_audio` (indirectly, when paired with
  `path_provider` for temp-file playback) triggered this. No working
  audio-playback solution was found from within Termux for this Flutter
  version as of 2026-08-01.
- If a package is required for a real feature (e.g. TTS voice playback),
  prefer building/testing that specific package's Android integration
  outside Termux (a real computer, or a Cloud Build / GitHub Actions CI
  pipeline) rather than spending further time working around it on-device.

Status: Confirmed blocking as of 2026-08-01, Flutter 3.44.0, Termux,
Samsung Galaxy S23. Backend TTS functionality (Gemini TTS synthesis) is
fully implemented and tested independently of this - the blocker is
purely in wiring playback into the Flutter/Android client from Termux.
