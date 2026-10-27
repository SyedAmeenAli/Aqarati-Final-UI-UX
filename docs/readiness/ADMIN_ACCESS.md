# Admin Console access and demo mode

## Where the link is
Login screen (`/login`, both User to Shop and Real Estate Agent variants): a small text link **Admin Console →** under the Login button (`lib/features/entry/admin_link.dart`, used in `auth_screens.dart`). It is not a signup role, not a tab, and not a role switch. It only opens the console's own sign-in page; admin sign-in and the one-time-code step are enforced there, unchanged (`lib/admin_main.dart`, `lib/admin/`).

## Which address it opens (`lib/core/config/demo_mode.dart`)
1. `AQARATI_ADMIN_URL` if set at build time.
2. Otherwise, when the customer app itself runs on `localhost` or `127.0.0.1`: `http://<same host>:8081/`.
3. Otherwise no address is known: the link opens a sheet that says the console is separate and how to run it. No dead link.

## Run the console locally
```bash
flutter run -d chrome -t lib/admin_main.dart --web-port 8081
```
Open http://localhost:8081 (or use the customer app's link on localhost). Demo reviewer accounts are listed on the console sign-in screen; the demo one-time code is shown there.

## Build and host the console separately
```bash
flutter build web --release --pwa-strategy=none -t lib/admin_main.dart --output build/web_admin
```
Host `build/web_admin` on its own site. Build the customer app with its address:
```bash
flutter build web --release --pwa-strategy=none --dart-define=AQARATI_ADMIN_URL=https://<admin-host>/
```
No admin site is deployed from this repository today; none is claimed. Stop any static server whose folder is `build/web_admin` before rebuilding (Windows leaves out AssetManifest otherwise).

## Troubleshooting
- Sheet says "Admin Console is separate": no `AQARATI_ADMIN_URL` and not on localhost. Set the define or run locally.
- New tab shows a connection error on localhost: nothing is running on port 8081. Start the command above.
- Blank page on the admin host: the build was made while a server held the output folder; rebuild and check `assets/AssetManifest.bin` exists.

## Demo mode ("Skip for Demo")
Off by default. A normal or production build has no skip buttons anywhere (signup screens or purpose screen).
Enable for a presentation build only:
```bash
flutter run -d chrome --dart-define=AQARATI_DEMO_MODE=true
flutter build web --release --pwa-strategy=none --dart-define=AQARATI_DEMO_MODE=true --output build/web_demo
```
With it on: User to Shop and Real Estate Agent signup show **Skip for Demo**, and the purpose screen shows per-role Skip chips. They only replace the simulated session (`demoEnterAs`), then show "Demo mode: no account was created, registered or verified." They never create an account, never change real permissions, and never bypass the Admin Console sign-in. Customer builds keep the simulated backend (`kUseDemoBackend`) regardless; real services are not wired yet.
