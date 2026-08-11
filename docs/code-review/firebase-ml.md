# Firebase and on-device ML review details

## Firebase Authentication and Firestore

REJECT if:

- Reads or writes are not scoped to the authenticated UID.
- A client can write fields outside the documented collection schema without rules validation.
- Multiple documents representing one user action are updated non-atomically when a batch or transaction is required.
- A schema change drops or double-counts existing collection data.
- Authentication errors leak implementation details or fail without a recovery action.

REQUIRE:

- Keep Firestore conversion inside a repository and return typed domain models.
- Preserve offline behavior deliberately and distinguish pending, failed, and confirmed writes in the UX.
- Add emulator/repository tests for schema migrations and count correction logic before changing persistence.
- Update and test `firestore.rules` when the writable schema changes.

## Privacy

REJECT if:

- Photos leave the device without explicit, informed consent and a documented retention policy.
- Logs, analytics, or error reports include image bytes, email addresses, UIDs, tokens, or credentials unnecessarily.

REQUIRE:

- Request a platform permission only at the moment its feature needs it.
- Explain why a denied permission is needed and provide a settings/retry path.

## TensorFlow Lite

REJECT if:

- `labels.txt` order/count does not match the model output tensor.
- Runtime normalization, input size, channel order, or quantization differs from training/export settings.
- A low-confidence or unsupported input is silently presented as a reliable identification.
- Model replacement increases release size or inference latency without measurement and rationale.

REQUIRE:

- Validate the plugin result before constructing a prediction.
- Document model version, classes, preprocessing, validation metrics, artifact size, and license.
- Test inference with representative real mobile photos, not only training/example assets.
- Keep classification local unless a future remote service is explicitly approved.
