# Toolchain & Environment Specifications

This document defines the pinned toolchain and native identity for this Flutter base.

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
| **JDK** | OpenJDK `17.0.15` | Required Java runtime for AGP 9.0.1 |
| **Gradle** | `9.1.0` | `android/gradle/wrapper/gradle-wrapper.properties` |
| **Android Gradle Plugin (AGP)** | `9.0.1` | `android/settings.gradle.kts` |
| **Kotlin Gradle Plugin** | `2.4.10` (version declared for Flutter validation; app uses built-in Kotlin) | `android/settings.gradle.kts`, `android/gradle.properties` |
| **Android minSdk** | `24` (Android 7.0+) | `android/app/build.gradle.kts` |
| **Android compileSdk** | `flutter.compileSdkVersion` | `android/app/build.gradle.kts` |
| **Android targetSdk** | `flutter.targetSdkVersion` | `android/app/build.gradle.kts` |
| **Namespace / Production Application ID** | `com.stormx.base` | `android/app/build.gradle.kts` |
| **Dev / UAT Application IDs** | `com.stormx.base.dev` / `com.stormx.base.uat` | `android/app/build.gradle.kts` |

---

## 3. iOS Build Toolchain

| Component | Pinned Version | Source File |
|---|---|---|
| **Xcode** | `27.0` (Build `27A266a`) | Host macOS build toolchain |
| **CocoaPods** | `1.16.2` | Host ruby gem / pod installer |
| **iOS Deployment Target** | `13.0` | `ios/Runner.xcodeproj/project.pbxproj` |
| **Production Bundle Identifier** | `com.stormx.base` | `ios/Runner.xcodeproj/project.pbxproj` |
| **Dev / UAT Bundle Identifiers** | `com.stormx.base.dev` / `com.stormx.base.uat` | `ios/Flutter/` xcconfigs |
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
