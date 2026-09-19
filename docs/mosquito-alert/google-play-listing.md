# Google Play listing reference — Mosquito Alert (production, `prod` flavor)

Unlike `docs/test-mosquito-alert/google-play-listing-setup.md`, this is **not**
a setup guide — the production listing has been live for years. It is a
reference for the facts that are permanent, easy to get wrong, and currently
recorded nowhere else.

See also: [Test Mosquito Alert listing setup](../test-mosquito-alert/google-play-listing-setup.md).

---

## 1. App identity

| | Value |
|---|---|
| Play listing name | Mosquito Alert |
| Android applicationId | `ceab.movelab.tigatrapp` |
| Gradle flavor | `prod` |
| Dart entrypoint | `lib/main.dart` → `assets/config/prod.json` |
| iOS bundle id | `cat.ibeji.tigatrapp` |
| Firebase project | `mosquitoalert-push-service` (project number `960892168613`) |
| Firebase Android app id | `1:960892168613:android:3b19a908c8f94830` |

A third package, `ceab.movelab.tigabib`, is also registered in the Firebase
project. It is a legacy app, not built from this repo.

---

## 2. Signing — read this before touching any keystore

Production signs with:

| | Value |
|---|---|
| Keystore | `android/JRBP_Keystore` (gitignored) |
| Alias | `jrbpandroidkey` |
| SHA-1 | `6B:7F:0B:19:2F:97:BD:55:3A:B7:13:29:31:A7:51:FE:6E:63:15:36` |
| SHA-256 | `76:91:DE:6F:5A:77:1C:F9:4C:97:B2:0D:8B:55:23:B9:44:50:B0:40:2D:1E:00:65:82:96:8B:88:43:8A:7D:5C` |
| Created | 2012-07-11, valid until 2042-07-04 |

**This key is the Play App Signing key for the production listing** — the key
Google uses to sign the APKs delivered to users, not merely a local keystore.
Production was enrolled in Play App Signing by handing Google this existing
key, so for *this listing* it serves as both the app signing key and the upload
key, which is why prod uploads signed with it are accepted.

The consequence, learned the hard way in August 2026: **this key cannot be used
as the upload key for any other Play listing.** Play rejects such uploads with
"signed with a key that is also used to sign APKs that are delivered to users."
Any new listing (like Test Mosquito Alert) needs a freshly generated upload
key. See section 2 of the test listing doc.

Losing `JRBP_Keystore` would be considerably worse than losing a normal upload
key, since Google holds the app signing key but the upload path depends on this
one. Confirm it is backed up somewhere other than a single laptop.

---

## 3. Build

```bash
fvm flutter build appbundle --release --flavor prod --target lib/main.dart
# -> build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

`--flavor` is mandatory since flavors were introduced. Verify signing with:

```bash
cd android && ./gradlew :app:signingReport | grep -A3 "Variant: prodRelease"
```

Per-flavor signing is configured in `android/app/build.gradle.kts`. Note the
warning there: do not set `signingConfig` on the `release` build type, or both
flavors collapse onto one key.

---

## 4. Firebase and API keys

- `android/app/google-services.json` is gitignored and covers the whole
  project (all three packages). CI writes it from the base64 secret
  `GOOGLE_SERVICES_JSON_ANDROID_BASE64` — see `.github/workflows/build_app.yml`.
- The production Google Maps key comes from `googlemaps.Key` in
  `android/local.properties` (or the `GOOGLE_MAPS_KEY` env var) and is injected
  as a per-flavor manifest placeholder. The test flavor uses a **different**
  key, `googlemaps.KeyTest` — see the test listing doc. Neither is the iOS key
  hardcoded in `ios/Runner/AppDelegate.swift`; keys restricted to iOS bundle
  ids do not work on Android.
- Maps key restrictions in Cloud Console must pair `ceab.movelab.tigatrapp`
  with the **Play app signing key** SHA-1 (`6B:7F:0B:19:...`, since for this
  listing the app signing key is the JRBP key). The oauth client entries in
  `google-services.json` list several additional certificate hashes, including
  historical ones — leave them alone unless you know which is which.
- A wrong or missing Maps key fails silently — blank map, no build error and no
  crash. `android/app/build.gradle.kts` logs a Gradle warning when a key is
  empty, but nothing catches a key that is present and wrongly restricted.

---

## 5. Backend wiring guard

The production app must talk to `https://api.mosquitoalert.com/v1` and Test
Mosquito Alert to `https://apidev.mosquitoalert.com/v1`. Two mechanisms keep
that true, because a regression here is silent:

- `test/unit/environment_config_test.dart` runs in CI on every push/PR and
  pins the resolved URL for each environment from the real config assets, the
  entrypoint wiring (`lib/main.dart` defaults to `prod`; `main_dev.dart` passes
  `dev`), and the package-to-environment table below against both the Gradle
  flavors and the Xcode bundle ids.
- `AppConfig.assertMatchesPackage()` runs at startup and throws if the
  binary's package/bundle id disagrees with its loaded environment, so a build
  made with the wrong `--flavor` / `--target` pairing crashes on launch instead
  of misrouting data for a whole release.

| Identity | Env |
|---|---|
| `ceab.movelab.tigatrapp`, `cat.ibeji.tigatrapp` | `prod` |
| `ceab.movelab.tigatrapp.test`, `com.mosquitoalert.devtest` | `dev` |

Note `prod.json` carries no `baseUrl`: production inherits the SDK's
`MosquitoAlert.basePath`. The test pins the resolved value, so an SDK bump
that moved it would fail CI rather than redirect production.

---

## 6. Not yet recorded

Deliberately left blank rather than guessed at. Worth filling in next time
someone does a production release:

- [ ] Who holds Play Console access, and at what permission level.
- [ ] Which tracks are in use (production only, or is there a closed/open
      testing track?) and the staged-rollout percentage convention.
- [ ] Store listing languages currently configured.
- [ ] Release cadence and who approves a rollout.
- [ ] Whether the App Store side of a release is documented anywhere.
- [ ] Where `JRBP_Keystore` and its password are backed up.
- [ ] Which Google Cloud project owns the production Maps key (the key the
      shipping APK embeds ends `…muV0`; as of Sep 2026 the console our IT lead
      uses holds a *different* "production" key, so that console is likely a
      stale or parallel project — Maps keys only work when their own project
      has billing + Maps SDK for Android enabled).
