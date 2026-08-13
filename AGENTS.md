# Reglas de revisión de "La granja de Michi"

> **Contexto del proyecto.** El directorio se llama `TFM` por razones
> históricas: el Trabajo Fin de Máster se entregó en 2021 y está cerrado.
> Hoy esto es un proyecto personal, sin entrega, sin tribunal y sin plazos, y
> **sin usuarios en producción**. No justifiques decisiones apelando a
> requisitos académicos. Y donde estas reglas pidan compatibilidad de datos,
> recuerda que no hay colecciones reales que preservar: propón el modelo
> limpio y confirma antes de borrar nada.

## Review scope

- Always inspect `git diff --cached` before deciding. Review the staged delta, not unrelated legacy debt.
- Do not fail solely for a pre-existing issue outside changed lines. Mention it as optional follow-up only when relevant.
- Treat generated files and model binaries as artifacts, not hand-edited source.

## References

- Flutter and Dart rules: `docs/code-review/flutter-dart.md`
- Firebase and on-device ML rules: `docs/code-review/firebase-ml.md`
- Classifier model, contract and how to extend it: `docs/MODELO.md`
- Modernization direction: `ROADMAP_MEJORAS.txt`

## Critical rules

REJECT if the staged change:

- Introduces credentials, private keys, service-account files, signing secrets, or personal data. Firebase client configuration is not a secret, but must remain generated and unedited.
- Weakens authentication, Firestore ownership rules, permission checks, privacy, or release-signing safeguards.
- Performs destructive data changes without an explicit compatibility or migration path.
- Swallows an exception without user feedback, logging, recovery, or a documented best-effort reason.
- Reports success before an asynchronous operation that defines that success has completed.
- Adds network or file I/O to a widget `build` method or blocks the UI isolate with expensive work.
- Adds production `print`, `debugPrint`, dead code, commented-out implementations, or analyzer suppressions without a narrow justification.
- Mixes unrelated refactors with a behavior change in a way that makes review or rollback unsafe.
- Changes user-visible behavior without covering loading, empty, error, retry, and offline states where applicable.

REQUIRE:

- Preserve user data and backward compatibility unless the change explicitly documents a migration.
- Validate untrusted values at Firebase, platform-channel, file, and model-output boundaries.
- Keep error messages actionable and in Spanish for the current product locale.
- Keep deterministic checks green: formatting, `flutter analyze`, tests, and the relevant build.
- Add or update tests for bug fixes, domain behavior, persistence changes, and important UI flows.

## Flutter and Dart

REJECT if:

- New UI code talks directly to Firebase, TFLite, permissions, or platform APIs instead of an injected service/repository boundary.
- A `BuildContext` or `State` is used after `await` without an appropriate mounted/lifecycle guard.
- A controller, subscription, interpreter, or other owned resource is not disposed.
- New business rules are embedded in widgets or duplicated across screens.
- New `dynamic` casts cross a domain boundary without validation and conversion to a typed model.
- Hardcoded colors, radii, spacing, or typography bypass shared design tokens without a local semantic reason.

REQUIRE:

- Use sound null safety, immutable models, `const` where meaningful, and descriptive domain names.
- Keep widgets focused; extract a component when it owns a distinct responsibility or state.
- Make state transitions explicit and prevent duplicate submissions.
- Prefer standard Material 3 components and platform conventions over custom interaction behavior.

PREFER:

- Feature-first folders with presentation, domain, and data boundaries where the feature warrants them.
- Small constructor-injected interfaces that can be replaced in tests.
- Composition over inheritance and pure helpers for transformations.

## UX, accessibility, and responsive behavior

REJECT if:

- A primary action lacks visible loading/disabled feedback or can be triggered twice.
- Navigation, dialogs, forms, or custom controls are inaccessible by semantics, focus, or touch target.
- Text is clipped at 200% scaling or a layout assumes one phone size without a responsive fallback.
- A destructive action has no confirmation when recovery is not immediate.
- New navigation uses a drawer for a small set of primary destinations; use `NavigationBar` on phones and `NavigationRail` on wide layouts.

REQUIRE:

- Minimum 48x48 logical-pixel touch targets and sufficient text/background contrast.
- Semantic labels for non-text controls and meaningful images.
- Consistent design tokens and clear visual hierarchy for primary, secondary, and destructive actions.

## Response format

FIRST LINE must be exactly one of:

`STATUS: PASSED`

`STATUS: FAILED`

If failed, list every blocking finding as:

`file:line - rule - concrete problem and smallest safe correction`

Keep non-blocking suggestions in a separate `SUGGESTIONS` section.
