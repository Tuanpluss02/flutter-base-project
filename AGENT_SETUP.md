# Set up a new app with a coding agent

This repository is a reusable Flutter base for Android and iOS. It ships with Dev, UAT, and Prod flavors, plus Login, Home, and Settings demo screens that illustrate the architecture. The demo screens remain in place during setup unless the user asks to remove them.

Give your coding agent this prompt:

> Read `AGENT_SETUP.md` and set up this base as my app. Use your question tool to ask me for the app name, base bundle ID, environments, and API endpoints. Then make the changes, run the repository checks and native flavor builds, and report the resulting IDs and any checks you could not run.

## Instructions for the agent

1. Read `README.md`, `pubspec.yaml`, `config/`, the Android and iOS identity files, and the nearest tests before editing. Check `git status` and preserve unrelated user files. Use the repository's pinned Flutter SDK through FVM.
2. Ask one grouped set of questions with your available user-input tool. If no such tool exists, ask in chat. Collect:
   - App display name for Prod. Derive `<name> Dev` and `<name> UAT` unless the user gives different labels.
   - Base bundle ID, for example `com.company.myapp`. Derive `.dev` and `.uat` IDs unless the user specifies different IDs.
   - Which environments to keep. The default is Dev, UAT, and Prod.
   - HTTPS API base URL for each retained environment. If an endpoint is not ready, keep an explicit `.example` placeholder and report that the app cannot connect to a real API yet. Never put credentials in these files.
3. Validate the answers before editing. Use an ID valid on both Android and iOS; each dot-separated segment must start with a lowercase letter and then contain only lowercase letters or digits. Ensure all retained IDs are distinct and all supplied endpoints use HTTPS. Derive the Dart package name from the final segment of the base ID, and ask for a Dart-compatible name only if that segment is unsuitable or the user requests an override. For this untouched base, the package name is `base`.
4. Update identity consistently:
   - `pubspec.yaml`, non-generated `package:base/` imports, active tests, and the architecture boundary checker.
   - `android/app/build.gradle.kts`, Android launcher labels, and the Kotlin `MainActivity` package declaration and directory.
   - iOS build configurations, xcconfigs, schemes, `Info.plist`, Podfile mapping, and RunnerTests IDs.
   - The backup-exclusion MethodChannel name in Dart, Kotlin, and Swift. All three strings must match.
   - `config/env_<env>.env`, launch configurations, Makefile, CI, and active documentation. The native flavor and `APP_ENV` must refer to the same environment.
   - If the user changes the environment set, update every Android flavor, iOS scheme/configuration, env validator, build command, CI job, and test that assumes the default three. Do not leave a half-configured flavor.
5. Edit sources, then regenerate tracked generated Dart files with `fvm dart run build_runner build -d`. Do not hand-edit generated files. Keep the existing dependency versions and architecture unless the user separately asks to change them.
6. Run `make test-scripts`, `make config-check`, `make boundary-check`, `make analyze`, `make test`, and `make format`. On a clean committed worktree, run `make ci`; it intentionally fails when unrelated untracked files or uncommitted generated changes exist. Build each retained Android and iOS flavor using matching `--flavor` and `--dart-define-from-file` arguments. Inspect the resulting native IDs and display names; never infer them from Dart config alone. Report every command's actual result.

The committed base has no Apple signing team or Android release signing key. Ask for signing details only if the user needs a signed device build or release. Keep keystores, passwords, certificates, and provisioning files out of Git. Never use a debug key to sign an app for distribution.

## Demo screens

Login, Home, and Settings are working examples, not required product features. Keep them during identity setup. If the user later asks to remove them, first replace their routes in `lib/src/app/app_router.dart` and registrations in `lib/src/app/injection.dart`. Check `AuthGuard`, the settings cubit used by `App`, localization keys, and tests that exercise the demo flow before deleting feature folders. Regenerate routes and dependency injection, then rerun the checks above.
