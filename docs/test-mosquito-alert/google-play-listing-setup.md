# Google Play setup for Test Mosquito Alert (Android `dev` flavor)

This is a one-time setup. Once finished, every future Test Mosquito Alert AAB
just gets uploaded to the same Internal testing track of this listing.

The flavor is defined in `android/app/build.gradle` and produces an APK/AAB
with:

- **applicationId**: `ceab.movelab.tigatrapp.dev` (production is
  `ceab.movelab.tigatrapp`)
- **App label**: *Test Mosquito Alert* (production is *Mosquito Alert*)
- **Adaptive icon**: distinct grey-background version using the iOS DevTF
  artwork at `ios/Runner/Assets.xcassets/AppIconDev.appiconset/`
- **Backend**: `apidev.mosquitoalert.com` (configured via `lib/main_dev.dart`
  → `AppConfig` loading `assets/config/dev.json`)

Because the `applicationId` is different, this is a **separate app** in
Google Play, completely independent of the production *Mosquito Alert*
listing. The two can coexist on the same device. There is no risk to the
production listing while configuring or distributing this one.

---

## 1. Firebase: create the second Android app

The dev flavor needs its own `google-services.json`, because Firebase keys
its config by `applicationId`.

1. Go to the Firebase Console → the existing Mosquito Alert project.
2. **Project settings → Your apps → Add app → Android**.
3. **Android package name**: `ceab.movelab.tigatrapp.dev`
4. **App nickname**: `Test Mosquito Alert (Android dev)`
5. **Debug signing certificate SHA-1**: optional for now; add later if you
   want Firebase Auth phone/Google Sign-in to work in this build.
6. Download the generated `google-services.json`.
7. Place it locally at: `android/app/src/dev/google-services.json`
   (already gitignored — see `.gitignore`).
8. Base64-encode it and add it as a new GitHub Actions secret:
   ```bash
   base64 -i android/app/src/dev/google-services.json | pbcopy
   ```
   Then in the repo → Settings → Secrets and variables → Actions → New
   repository secret:
   - **Name**: `GOOGLE_SERVICES_JSON_ANDROID_DEV_BASE64`
   - **Value**: paste from clipboard.
9. Add a corresponding "write dev google-services.json" step to
   `.github/workflows/build_app.yml` and `integration_tests.yml`, mirroring
   the existing prod step but writing to `android/app/src/dev/` and using
   the new secret. (Skip this until CI is needed — the local build works
   without it once the file is in place.)

---

## 2. Build the first AAB locally

From the `feature/vietnamese-beta` branch (which includes the Android flavor
+ the Vietnamese restoration + the iOS DevTF config):

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build appbundle --release --flavor dev --target lib/main_dev.dart
```

The output AAB will be at:

```
build/app/outputs/bundle/devRelease/app-dev-release.aab
```

> **Signing**: the dev flavor uses the same `signingConfigs.release` block as
> prod (the JRBP keystore in `android/`). That's fine — Play key management
> only requires consistency *within* a single Play listing, and this is a
> brand-new listing so whatever key you upload first becomes its app
> signing key.

If you'd rather have a separate keystore for this listing, generate one
before the first upload (Play will lock it in as soon as the first AAB is
uploaded).

---

## 3. Create the Play Console listing

In **Google Play Console**:

1. **All apps → Create app**.
2. **App name**: `Test Mosquito Alert`
3. **Default language**: English (United States) — Vietnamese added later as
   an additional store-listing language.
4. **App or game**: App.
5. **Free or paid**: Free.
6. Accept Play declarations and **Create app**.

You'll land on the new app's Dashboard. Play forces you to complete a
"Setup" checklist before the first internal release. Walk through it:

### 3a. Set up — App access
- *All functionality is available without restrictions.* (Same as the prod
  app, unless your testers need account-gated review instructions.)

### 3b. Ads
- *No, my app does not contain ads.*

### 3c. Content rating
- Start the questionnaire. Use the same answers as the production
  *Mosquito Alert* listing (no violence, no user-generated content visible
  to other users in-app, references location data, etc.).

### 3d. Target audience and content
- Same age bands as production (13+ typical).
- Confirm the app is not directed primarily at children.

### 3e. News app, COVID-19 contact tracing, Government app
- All *No*.

### 3f. Data safety
- Mirror the production *Mosquito Alert* answers exactly. The data
  categories collected are identical because this is the same app code
  pointing at a different server. Reference the production listing in
  another browser tab and copy each answer across.

### 3g. Privacy policy
- Use the same URL as the production listing
  (e.g. `https://www.mosquitoalert.com/.../privacy-policy/`). Add a note
  in the listing description that this is a developer test build.

### 3h. App category
- **Category**: Education or Health & Fitness — whichever production uses.
- **Tags**: copy from production.

### 3i. Store settings — Store listing assets

Reuse the iOS DevTF artwork as much as possible (the user explicitly asked
for this). All of the following live under
`ios/Runner/Assets.xcassets/AppIconDev.appiconset/` or in the existing
DevTF screenshots folder if you have one.

- **App icon (512×512 PNG)**: resize from the 1024×1024 DevTF icon:
  ```bash
  sips -Z 512 -s format png \
    ios/Runner/Assets.xcassets/AppIconDev.appiconset/Icon-App-1024x1024@1x.png \
    --out /tmp/test-mosquito-alert-play-icon-512.png
  ```
  Upload that file.
- **Feature graphic (1024×500 PNG)**: required. If you don't have a DevTF
  feature graphic, take the production *Mosquito Alert* feature graphic,
  overlay a "TEST" badge or change the wordmark to "Test Mosquito Alert",
  and upload. (Can iterate later.)
- **Phone screenshots (min 2)**: take 2–3 screenshots from a device running
  the new build (clearly showing the "Test Mosquito Alert" name and the
  Vietnamese UI for at least one of them, so reviewers know what they're
  looking at). 1080×1920 or 1080×2400 works.
- **Short description (80 chars)**:
  > Developer test build of Mosquito Alert. Reports go to the dev server only.
- **Full description**: copy the production listing's full description and
  prepend:
  > **This is the developer test build of Mosquito Alert.** It connects to
  > our development server and is distributed only to internal testers and
  > translation collaborators. Reports submitted in this build do not enter
  > the public dataset. For the public app, search for "Mosquito Alert".

### 3j. App content — Government app, financial features, etc.
- All *No*.

---

## 4. Configure Internal testing (the only distribution track)

Per the user's preference, do **not** push this app to Closed / Open / Production
tracks. Internal testing is the right channel because:

- It bypasses Play review for each release (typically goes live in minutes).
- Testers join via a link or by Google account on a closed list.
- The listing is **not publicly searchable** as long as the app stays in
  Internal testing only.

Steps:

1. **Testing → Internal testing → Create new release**.
2. Upload `app-dev-release.aab`.
3. **Release name**: e.g. `1.0.0+200000 (vi beta)` — Play will auto-fill from
   the AAB's versionName/versionCode.
4. **Release notes**: paste the *Internal release notes* block from
   `release-notes-vietnamese-beta.md`.
5. **Save → Review release → Start rollout to Internal testing**.

Then on the same Internal testing page:

6. **Testers** tab → **Create email list**:
   - **List name**: `Mosquito Alert internal testers`
   - **Email addresses**: paste the Vietnamese collaborators' Google
     account emails (one per line). They must be Google accounts (Gmail or
     Google Workspace) — personal email aliases won't work.
   - Save.
   - Tick the list to add it to this track.
7. Copy the **Join on Android** opt-in URL and send it to each tester. They
   must:
   - Open the URL on their Android device while signed in with the matching
     Google account.
   - Tap *Become a tester*.
   - Then either follow the link to the Play Store entry, or wait a few
     minutes and search for "Test Mosquito Alert" while signed in with the
     same account.

---

## 5. Versioning convention for the dev listing

Because the `applicationId` is different from production, Play tracks
versionCodes independently. There is no risk of dev releases blocking prod
releases or vice versa.

Suggested convention: keep `versionName` aligned with the matching prod
release that the test build derives from, and use a `versionCode` offset
(e.g. prod `1.0.0+200000` → dev `1.0.0+200001`). This is automatic via
Flutter's version flag — no Gradle change needed.

---

## 6. After every Test Mosquito Alert release

1. Build: `fvm flutter build appbundle --release --flavor dev --target lib/main_dev.dart`
2. Play Console → Test Mosquito Alert → Internal testing → Create new release.
3. Upload the AAB.
4. Paste the release notes.
5. Save → Review → Start rollout.

That's it. The testers already opted-in in step 4.7 above get the update
automatically through the Play Store.

---

## Quick checklist

- [ ] Firebase: add Android app `ceab.movelab.tigatrapp.dev`.
- [ ] Save `google-services.json` to `android/app/src/dev/`.
- [ ] Add CI secret `GOOGLE_SERVICES_JSON_ANDROID_DEV_BASE64` (optional, defer
      until CI builds the dev flavor).
- [ ] Build first AAB locally with `--flavor dev --target lib/main_dev.dart`.
- [ ] Play Console: create app "Test Mosquito Alert".
- [ ] Complete setup checklist (Data safety, content rating, target audience,
      privacy policy, category).
- [ ] Upload store assets (512px icon from DevTF iOS source, feature
      graphic, ≥2 phone screenshots).
- [ ] Create Internal testing release; upload AAB; paste release notes.
- [ ] Create internal-tester email list; add Vietnamese collaborators.
- [ ] Send opt-in URL to testers.
