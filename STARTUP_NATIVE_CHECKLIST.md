# Startup foundation: what is verified and what is not

Verified in Flutter Web (Chromium, headless) only. **No iOS or Android device or simulator run has been done.**

## Verified (web)
- Silent, sparkle-free film plays 10.00 s; the completion flag is written only after the film ends (or the reduced-motion bypass).
- Handoff: final logo scales and travels to the entry logo while the entry content fades in (frames recorded and inspected).
- Entry layout at 430x932, 393x852, 390x844, 375x812, 375x700.
- Sign-up (construction path), OTP invalid/verified, active account, documents screen, verification states, resubmission, login error, forgot-password sent state, Arabic RTL.
- Logic tests: `flutter test` (roles/documents config, validation, drafts exclude secrets, file signatures, OTP, upload isolation/retry).

## Must be checked on devices before calling it done
1. **Native splash**: Android launch background and iOS LaunchScreen colour are set to `#EDE1D4`. Android 12+ uses the system splash API and ignores the window background: configure `windowSplashScreenBackground` (values-v31) or `flutter_native_splash`, then confirm no colour jump into the film.
2. **Video codec**: H.264 High, yuv420p, 1080x1920, 24 fps, no audio. Play on a low-end Android (hardware decoder) and on iOS.
3. **Lifecycle**: background at ~6 s then resume (film should continue or restart, flag stays unset); kill at ~4 s (next launch replays); kill after the end (never replays).
4. **System bars / SafeArea**: notch, gesture bar, 3-button nav; keyboard over sign-up fields.
5. **Memory**: controller disposed after the overlay leaves the tree (code does this; confirm with DevTools).
6. **Persistence**: `hasCompletedAqaratiIntro` survives app restarts; cleared on reinstall.
7. **File picker**: PDF/JPG/PNG on iOS (Files, Photos permissions strings) and Android (scoped storage).

## Still open
- **Fonts are not bundled.** Fraunces, Plus Jakarta Sans and IBM Plex Sans Arabic still load through `google_fonts` at runtime. Bundling needs the .ttf files in `assets/fonts/` (download from github.com/google/fonts was not approved yet).
- Arabic copy (`entry_strings.dart`, `flow_strings.dart`) is draft and needs native/business review.
- Demo backend (`lib/data/demo`, `kUseDemoBackend` in `lib/core/config/backend_mode.dart`) must be replaced by Firebase Auth + the Aqarati API. Demo OTP code is `123456`.
- Password minimum (8) is an assumption (`kMinPasswordLength`); reason-code copy (`reason.*`) is placeholder until the API defines codes.
- Google/Apple sign-in: contract only (`AuthRepository.signInWithProvider`), no provider wired.
