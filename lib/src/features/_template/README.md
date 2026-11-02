# Feature template

Create only the directories a feature needs:

```text
<feature_name>/
  feature_name.dart
  data/datasources/ dto/ mappers/ repositories/
  domain/entities/ repositories/ usecases/
  presentation/cubit/ pages/ widgets/ routes/
```

Keep dependencies flowing from presentation to domain to data contracts. A feature may import `core/` and `shared/`, but must not import another feature. Register routes and dependencies through `app/` composition and add strings to both `l10n/` catalogs. Do not edit `core/` for a feature.

## Before implementation

- Feature: `<feature_name>`; owner: `<team/person>`; mode: `online-only` or approved `offline-first` policy.
- Routes and auth policy: `<routes>`; shared domain types: `<none or owner and meaning>`.
- Localization namespace: `<prefix>`; acceptance cases: `<tests>`.
- Confirm no existing core/shared capability or feature can be reused.

## Registration checklist

Copy this block into the pull request or task when the feature lands:

```text
Feature: <feature_name>
Owner: <team/person>
Mode: online-only | offline-first (link approved policy)
Routes: <route names and auth policy>
Shared domain types: <none or type + shared meaning/owner>
Localization namespace: <feature key prefix>
Acceptance cases: <links or test names>

[ ] Confirmed no existing core/shared capability or feature to reuse
[ ] Created only required feature-first layers
[ ] Kept DTO/entity/UI state ownership within the correct layer
[ ] Added route declaration and app route aggregation
[ ] Added Injectable bindings and app DI aggregation
[ ] Added locale keys/translations and regenerated Slang output
[ ] Added behavior tests and required failure/state cases
[ ] Ran generators; generated diff is clean
[ ] Ran format, analyze, localization analysis, and feature/full tests
[ ] Confirmed feature can be composed without edits to src/core/
[ ] Reviewed privacy, logs, accessibility, and offline policy where applicable
```

## Definition of done

- Create only required layers and keep DTO, entity, and UI state in their owning layer.
- Add app route and DI registration, locale keys and translations, and behavior tests under `test/src/features/<feature_name>/`.
- Cover loading, empty, error, retry, and cancellation when applicable. Verify UI semantics and text scaling.
- Run these commands from the repository root:

```bash
fvm dart run slang
fvm dart run build_runner build -d
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter analyze --fatal-infos --fatal-warnings
fvm flutter test
bash scripts/check_boundaries.sh
```

- Confirm generated files are stable after a second generation run and the `core/` diff is empty.
