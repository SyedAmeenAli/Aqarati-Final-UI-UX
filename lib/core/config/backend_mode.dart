/// DATA SOURCE SWITCH.
///
/// REAL API      : not wired yet. Set [kUseDemoBackend] to false and override
///                 `accountApiProvider` / `authRepositoryProvider` with the
///                 Firebase + Aqarati API implementations.
/// MOCK / DEMO   : `lib/data/demo/*` simulates the documented API contract
///                 (sign-up, OTP, documents, verification) so the UI can be
///                 reviewed. It is NOT a backend and must never ship enabled.
/// DERIVED       : UI-only behaviour (drafts, validation, routing by state).
///
/// While true, screens show a visible DEMO marker where simulated data is used.
const bool kUseDemoBackend = true;

/// Reviewer-only shortcuts (OTP hint, "mark documents received", decision simulator).
/// Off by default so the product looks and behaves as shipped. Enable for QA with
/// `--dart-define=REVIEW_TOOLS=true`.
const bool kShowReviewTools = kUseDemoBackend && bool.fromEnvironment('REVIEW_TOOLS');
