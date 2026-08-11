# Flutter and Dart review details

Apply these rules when staged files affect Flutter/Dart source, tests, assets, or platform integration.

## Architecture

REQUIRE:

- Presentation depends on domain interfaces; data/platform implementations stay behind services or repositories.
- Authentication, classifier, collection, and preferences remain independently testable.
- A screen coordinates UI state but does not own persistence schemas or model preprocessing rules.
- Public state has one clear source of truth. Derived values are computed rather than stored twice.
- Navigation state survives ordinary tab changes without recreating expensive resources unnecessarily.

REJECT if:

- A new screen combines navigation, persistence, platform permissions, model inference, and large widget trees in one state class.
- A repository exposes Firestore snapshots or `Map<String, dynamic>` beyond its data boundary.
- UI widgets depend on singleton Firebase instances when constructor injection is practical.
- A refactor changes behavior accidentally because responsibilities were moved without characterization tests.

## Async and lifecycle

REQUIRE:

- Guard state/context access after asynchronous gaps.
- Use `try/finally` for busy flags and guarantee that duplicate actions are disabled.
- Surface actionable failures and preserve a valid previous state when retry is possible.
- Cancel subscriptions and dispose owned controllers/resources.

REJECT if:

- An async callback can update disposed state.
- Errors are converted into success feedback.
- Fire-and-forget work can corrupt state or produce an unhandled asynchronous error.

## UI system

REQUIRE:

- Colors, typography, radii, elevations, motion durations, and common spacing come from the theme or design tokens.
- Use Material 3 navigation and controls with adaptive phone/tablet behavior.
- Forms support autofill, keyboard actions, inline validation, password visibility, loading, and recovery paths.
- Images define fit, loading/error behavior, semantic meaning, and a bounded decoded/display size.
- Lists use lazy builders when content can grow.

PREFER:

- `NavigationBar` below 840 logical pixels and `NavigationRail` at or above that breakpoint.
- `AnimatedSwitcher`, shared-axis, fade, or subtle scale transitions lasting roughly 150-300 ms.
- Tonal surfaces and restrained elevation instead of large saturated gradients and uniform outlined cards.
- Skeletons or stable placeholders instead of layout jumps.

## Performance

REJECT if:

- Large image bytes, model files, or collections are repeatedly decoded/loaded during rebuilds.
- A list creates every potentially unbounded child eagerly.
- Expensive synchronous transformations run on the UI isolate without measurement or justification.

REQUIRE:

- Keep the TFLite interpreter lifecycle explicit and avoid repeated model loading.
- Bound preview resolution separately from model preprocessing.
- Measure release artifact size and startup/inference time after model or native dependency changes.

## Tests

REQUIRE:

- Unit tests for parsers, migrations, confidence rules, and repository transformations.
- Widget tests for authentication, primary navigation, classifier states, and collection states.
- A regression test for every fixed bug when the behavior can be reproduced deterministically.
- Test doubles instead of real Firebase, camera, gallery, or TFLite calls in widget tests.

PREFER:

- Golden tests for stable key screens at phone and tablet widths after the design system settles.
- One Android integration smoke flow for sign-in, image selection, confirmation, collection, and sign-out.
