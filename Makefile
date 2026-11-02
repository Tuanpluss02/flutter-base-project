.PHONY: all ci get gen analyze test format config-check boundary-check secret-check run-dev build-prod

all: ci

ci:
	cd pristie && bash scripts/ci_local.sh

get:
	cd pristie && fvm flutter pub get

gen:
	cd pristie && fvm dart run build_runner build -d

analyze:
	cd pristie && fvm flutter analyze --fatal-infos --fatal-warnings

test:
	cd pristie && fvm flutter test

format:
	cd pristie && fvm dart format --output=none --set-exit-if-changed .

config-check:
	cd pristie && scripts/check_config.sh

boundary-check:
	cd pristie && scripts/check_boundaries.sh

secret-check:
	cd pristie && scripts/check_secrets.sh

run-dev:
	cd pristie && fvm flutter run --dart-define-from-file=config/env_dev.env

build-prod:
	cd pristie && fvm flutter build appbundle --release --dart-define-from-file=config/env_prod.env
