# Toolchain & Environment Specifications

This document defines the exact pinned versions of the toolchains, compilers, runtimes, and build tools required to build, test, and verify the Pristie Flutter application.

---

## 1. Core Toolchain

| Tool | Pinned Version | Source / Enforcement |
|---|---|---|
| **Flutter** | `3.47.8` (stable, revision `737ba8f885`) | `.fvmrc`, `scripts/ci_local.sh` |
| **Dart** | `3.13.7` | Bundled with Flutter 3.47.8 SDK |
| **DevTools** | `2.60.0` | Bundled with Dart 3.13.7 |
| **FVM** | >= `3.2.0` | Workspace FVM configuration |

---

## 2. Android Build Toolchain

| Component | Pinned Version | Source File |
|---|---|---|
| **JDK** | OpenJDK `17.0.15` | Required Java runtime for Gradle 8.14 |
| **Gradle** | `8.14` | `android/gradle/wrapper/gradle-wrapper.properties` |
| **Android Gradle Plugin (AGP)** | `8.11.1` | `android/settings.gradle.kts` |
| **Kotlin Gradle Plugin** | `2.2.20` | `android/settings.gradle.kts` |
| **Android minSdk** | `24` (Android 7.0+) | `android/app/build.gradle.kts` |
| **Android compileSdk** | `flutter.compileSdkVersion` | `android/app/build.gradle.kts` |
| **Android targetSdk** | `flutter.targetSdkVersion` | `android/app/build.gradle.kts` |
| **Application ID / Namespace** | `com.bolt.pristie` | `android/app/build.gradle.kts` |

---

## 3. iOS Build Toolchain

| Component | Pinned Version | Source File |
|---|---|---|
| **Xcode** | `27.0` (Build `27A266a`) | Host macOS build toolchain |
| **CocoaPods** | `1.16.2` | Host ruby gem / pod installer |
| **iOS Deployment Target** | `13.0` | `ios/Runner.xcodeproj/project.pbxproj` |
| **Bundle Identifier** | `com.bolt.pristie` | `ios/Runner.xcodeproj/project.pbxproj` |
| **Keychain Accessibility** | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (`unlocked_this_device`) | `flutter_secure_storage` configuration |

---

## 4. Verification Commands

To check local toolchain alignment against these specifications:

```bash
# Verify Flutter & Dart
fvm flutter --version

# Verify Java
java -version

# Verify Xcode & CocoaPods
xcodebuild -version
pod --version
```
