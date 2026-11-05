# 08 — Routing, DI, i18n, Theming, Accessibility

## 1. Routing (auto_route)

- `core/router/app_router.dart` composes routes; each feature exports its route list from `features/<f>/presentation/<f>_routes.dart`. The feature list in `AppRouter` is a **merge hotspot** (alphabetical).
- Pages are `@RoutePage()` classes named `<Name>Page`. Route names are auto-generated; do not hand-name unless needed for deep links.
- **Pass ids/primitives, never entities, through routes.** The destination Bloc loads from the DB.
- Guards: `AuthGuard` (requires session), `OnboardingGuard`, `ForceUpdateGuard`. Guards read `SessionBloc`/stores through DI, never UI state.
- Tabs/nested navigation via `AutoTabsRouter`; each tab keeps its own stack.
- **Deep links / universal links** (listing share links): one `DeepLinkResolver` in `core/router` maps URL → route; validates and sanitizes all params; unknown links open home with a non-blocking message. Domains/paths documented in `docs/` when defined.
- Never use `Navigator.push*`; never navigate from a Bloc. Navigation happens in `BlocListener` / page code.
- Dialogs/bottom sheets use auto_route's dialog/bottom-sheet routes or a shared `showAppDialog` helper.

## 2. Dependency injection (injectable + get_it)

| Annotation | Use for |
|---|---|
| `@lazySingleton(as: X)` | repositories, DAOs, API wrappers, services, SyncCoordinator |
| `@singleton` | only objects that must exist at startup (DB, logger) |
| `@injectable` | **page Blocs/Cubits**, use cases |
| `@module` | third-party objects (Dio, Retrofit APIs, Drift DB, SecureStorage, Clock) in `core/di/modules/` |
| `@Environment('dev'/'staging'/'prod'/'test')` | alternate implementations (fakes in `test`) |

Rules:
- **Constructor injection only.** `getIt<T>()` is allowed in exactly two places: DI modules and composition roots (`BlocProvider(create: ...)` in pages, `bootstrap`). Never inside domain, data, or widgets' `build`.
- Bind interfaces, not implementations (`@LazySingleton(as: ListingRepository)`).
- A feature registers only its own classes; cross-feature dependencies are domain interfaces.
- `configureDependencies(environment)` runs once in `bootstrap`; tests call `getIt.reset()` and register fakes through the `test` environment.
- Generated `lib/generated/core/di/injection.config.dart` is not committed.

## 3. Internationalization (slang)

- Source files: `lib/i18n/<locale>.i18n.json` (generated output goes to `lib/generated/i18n/`), split by feature namespace (`listing`, `auth`, `errors`, `common`). **ASSUMPTION:** base locale `vi`, secondary `en` — confirm with product.
- Access via `context.t.feature.section.key` (typed). No string literals in widgets, Blocs, or mappers. No concatenated sentences: use parameters and pluralization/gender features of slang.
- Keys: `lowerCamel` dotted by feature → section → element. Adding a key requires adding **all locales** in the same PR (CI fails on missing keys).
- Dates, numbers, currency, and area units are formatted through `core/utils/formatters` using `intl` with the active locale. Currency/area format rules for the luxury market (VND, USD display, m²/ft²) are centralized there.
- Locale changes at runtime through `LocaleBloc`; persisted in preferences.

## 4. Theming and design system (`packages/design_system`)

- Tokens: colors (semantic: `surface`, `onSurface`, `primary`, `accent`, `danger`, ...), typography scale, spacing scale (4-pt), radii, elevations, durations, breakpoints. Light and dark themes; no raw `Color(0x...)`/`TextStyle(...)`/magic numbers in features.
- Components live in `design_system` only if feature-agnostic (buttons, inputs, cards shells, skeletons, banners, empty/error states, chips, image with placeholder, sync/offline banner). Feature-specific widgets stay in the feature.
- Fonts and assets are declared once in `design_system`; asset references are generated into `packages/design_system/lib/generated/` (`flutter_gen` or equivalent), no string paths in features.
- Every design-system component has: a golden test (light/dark, text scale 1.0/1.5), a widget test for interaction/semantics, and a gallery entry in a dev-only catalog page.
- Skeletons/shimmer respect "reduce motion".

## 5. Standard UI states (shared components)

`AppEmptyState`, `AppErrorState(failure, onRetry)`, `AppSkeleton`, `AppOfflineBanner`, `AppStaleIndicator(lastSyncedAt)`, `AppPendingBadge(syncStatus)`, `NewItemsPill`. Features compose these; they do not re-implement them.

## 6. Accessibility

- Semantic labels for icons, images, and custom controls; `ExcludeSemantics` for decorative items.
- Minimum tap target 48×48 dp; focus order logical; visible focus.
- Supports text scale ≥ 1.5× without overflow (test with goldens); no fixed-height text containers.
- Contrast ≥ WCAG AA for text and essential icons.
- Motion: honor `MediaQuery.disableAnimations`.
- Screen-reader announcements for sync-relevant changes that matter (e.g. "3 new listings").

## 7. Responsiveness

Phone first; tablets supported via breakpoints from the design system (`compact < 600`, `medium 600–839`, `expanded ≥ 840`). Use `LayoutBuilder`/breakpoint helpers, no device-type sniffing. Orientation is locked to portrait on phones unless a screen declares otherwise.
