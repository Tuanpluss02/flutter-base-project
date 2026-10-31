.PHONY: all ci gen analyze test format config-check boundary-check secret-check run-dev run-stg build-apk-dev build-prod test-scripts

all: ci

ci:
	scripts/ci_local.sh

gen:
	fvm dart run build_runner build -d

analyze:
	fvm flutter analyze --fatal-infos --fatal-warnings

test:
	fvm flutter test

format:
	fvm dart format --output=none --set-exit-if-changed .

config-check:
	scripts/check_config.sh

boundary-check:
	scripts/check_boundaries.sh

secret-check:
	scripts/check_secrets.sh

run-dev:
	fvm flutter run --dart-define-from-file=config/env_dev.json

run-stg:
	fvm flutter run --dart-define-from-file=config/env_stg.json

build-apk-dev:
	fvm flutter build apk --debug --dart-define-from-file=config/env_dev.json

build-prod:
	fvm flutter build appbundle --release --dart-define-from-file=config/env_prod.json

test-scripts:
	bash test/scripts/run_all_tests.sh
