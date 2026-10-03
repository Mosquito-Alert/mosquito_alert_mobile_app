# Google Play setup for Test Mosquito Alert (Android `dev` flavor)

This is a one-time setup. Once finished, every future Test Mosquito Alert AAB
just gets uploaded to the same Internal testing track of this listing.

For the production listing, see
[Mosquito Alert Play listing reference](../mosquito-alert/google-play-listing.md).

The flavor is defined in `android/app/build.gradle.kts` and produces an APK/AAB
with:

- **applicationId**: `ceab.movelab.tigatrapp.test` (production is
  `ceab.movelab.tigatrapp`)
- **Gradle flavor name**: `dev` — *not* `test`, because AGP rejects product
  flavor names starting with "test". The flavor is `dev`, the applicationId
  suffix is `.test`; that mismatch is deliberate.
- **App label**: *Test Mosquito Alert* (production is *Mosquito Alert*)
- **Adaptive icon**: distinct grey-background version using the iOS DevTF
  artwork at `ios/Runner/Assets.xcassets/AppIconDev.appiconset/`
- **Backend**: `apidev.mosquitoalert.com` (configured via `lib/main_dev.dart`
  → `AppConfig` loading `assets/config/dev.json`)

Because the `applicationId` is different, this is a **separate app** in
Google Play, completely independent of the production *Mosquito Alert*
listing. The two can coexist on the same device. There is no risk to the
production listing while configuring or distributing this one.

> **The package name is locked.** A Play listing's package name is fixed by
> its first accepted upload and can never be changed. The Test Mosquito Alert
> listing is locked to `ceab.movelab.tigatrapp.test`, which is why the flavor
> uses that suffix rather than the `.dev` originally planned. If you ever need
> a different package name, that means a different Play listing.

---

## 1. Firebase: the second Android app

The dev flavor needs a Firebase client entry matching its applicationId, or
the build fails at `:app:processDevReleaseGoogleServices` with
`No matching client found for package name 'ceab.movelab.tigatrapp.test'`.

1. Go to the Firebase Console → the existing `mosquitoalert-push-service`
   project → **Project settings → Your apps → Add app → Android**.
2. **Android package name**: `ceab.movelab.tigatrapp.test`
3. **App nickname**: `Test Mosquito Alert (Android test)`
4. **Debug signing certificate SHA-1**: leave blank. FCM does not need it.
   Only add one if this build ever needs Firebase Auth phone/Google Sign-in.
5. Download the generated `google-services.json` and use it to **replace**
   `android/app/google-services.json`.

Step 5 is the part that trips people up: `google-services.json` describes a
whole Firebase **project**, not one app. The downloaded file already contains
every registered package — `ceab.movelab.tigatrapp`, `ceab.movelab.tigabib`,
and `ceab.movelab.tigatrapp.test` — so replacing the single top-level file is
correct and does not break prod. There is no need for a per-flavor file in
`android/app/src/dev/`. See `android/app/src/dev/README.md` for when you
*would* want one (only if the test build should talk to a different Firebase
project entirely).

After replacing it, confirm all three clients survived:

```bash
python3 -c "
import json
d = json.load(open('android/app/google-services.json'))
for c in d['client']:
    print(c['client_info']['android_client_info']['package_name'],
          c['client_info']['mobilesdk_app_id'])
"
```

The `.test` entry should be `1:960892168613:android:ed6903aefaf7251608a04c`.

CI note: if the dev flavor is ever built in CI, add the file as a base64
GitHub Actions secret (`GOOGLE_SERVICES_JSON_ANDROID_DEV_BASE64`) and write it
to `android/app/google-services.json` in the workflow, mirroring the existing
prod step. Not needed for local builds.

---

## 2. Signing: the test listing has its own upload key

**This listing must not be signed with the production keystore.** The
`JRBP_Keystore` key is registered with Play as the *app signing key* for the
live Mosquito Alert listing — the key Google itself uses to sign what ships to
users. Play refuses to accept an app signing key as an *upload* key for any
app, and rejects the upload with:

> You uploaded an APK or Android App Bundle that is signed with a key that is
> also used to sign APKs that are delivered to users. Because you are enrolled
> in Play App Signing, you should sign your APK or Android App Bundle with a
> new key before you upload it.

So the two flavors sign with two different keys:

| Flavor | applicationId | Keystore | Alias | SHA-1 |
|---|---|---|---|---|
| `prod` | `ceab.movelab.tigatrapp` | `android/JRBP_Keystore` | `jrbpandroidkey` | `6B:7F:0B:19:2F:97:BD:55:3A:B7:13:29:31:A7:51:FE:6E:63:15:36` |
| `dev` | `ceab.movelab.tigatrapp.test` | `android/MA_Test_Upload_Keystore.jks` | `matestupload` | `4A:FF:55:FA:F1:3A:D9:78:98:28:B3:88:20:FA:90:E0:A6:A8:4B:9A` |

Both are wired through `android/key.properties` (prod keys unprefixed, test
keys under `dev*` names) and selected per-flavor in `android/app/build.gradle.kts`.

> **Do not set `signingConfig` on the `release` build type.** A build type's
> signing config overrides the per-flavor one, which silently collapses both
> flavors back onto a single key. The `release` block deliberately leaves it
> unset so the flavor's config wins.

Verify at any time with:

```bash
cd android && ./gradlew :app:signingReport | grep -A3 "Variant: devRelease"
```

**Back up `android/MA_Test_Upload_Keystore.jks` and `android/key.properties`.**
Both are gitignored and exist only on the machine that created them. If the
upload key is lost, the listing needs a Play upload key reset (Play Console →
Setup → App integrity), which goes through Google support.

Note also that Play re-signs the delivered bundle with its own Google-generated
app signing key, so the certificate on a tester's device is *neither* of the
two above. That matters for API key restrictions — see section 6.

---

## 3. Build the AAB locally

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build appbundle --release --flavor dev --target lib/main_dev.dart
```

Once flavors exist Gradle requires one, so `--flavor` is mandatory. The output
AAB lands at:

```
build/app/outputs/bundle/devRelease/app-dev-release.aab
```

Before uploading, verify the three things that have each caused a rejected
upload at least once:

```bash
AAB=build/app/outputs/bundle/devRelease/app-dev-release.aab

# 1. package name -> must be ceab.movelab.tigatrapp.test
unzip -p "$AAB" base/manifest/AndroidManifest.xml | strings \
  | grep -oE "ceab\.movelab\.tigatrapp[a-z.]*" | sort -u | head -1

# 2. signing cert -> must be the 4A:FF:55:... upload key, not 6B:7F:0B:...
unzip -p "$AAB" 'META-INF/*.RSA' | keytool -printcert | grep "SHA1:"

# 3. maps key -> must be non-empty and equal to googlemaps.KeyTest
unzip -p "$AAB" base/manifest/AndroidManifest.xml | strings \
  | grep -oE "AIza[A-Za-z0-9_-]{35}"
```

All three have caused a broken or rejected release at least once: the package
name and the signing key are rejected loudly by Play, the Maps key is not.

---

## 4. The Play Console listing

The listing already exists and its package name is locked (see the note at the
top). Its default store language is **es-ES**; EN and CA translations have to
be added under Store presence → Main store listing → Manage translations before
you can supply release notes in those languages.

If you are ever setting up a *new* listing from scratch, Play does not ask for
a package name at creation — it is taken from the first accepted upload. Choose
"Free" carefully, as free/paid cannot be changed after publishing.

Play forces a "Setup" checklist before the first internal release:

### 4a. App access
- *All functionality is available without restrictions.* (Same as the prod
  app, unless testers need account-gated review instructions.)

### 4b. Ads
- *No, my app does not contain ads.*

### 4c. Content rating
- Start the questionnaire. Use the same answers as the production
  *Mosquito Alert* listing (no violence, no user-generated content visible
  to other users in-app, references location data, etc.).

### 4d. Target audience and content
- Same age bands as production (13+ typical).
- Confirm the app is not directed primarily at children.

### 4e. News app, COVID-19 contact tracing, Government app
- All *No*.

### 4f. Data safety
- Mirror the production *Mosquito Alert* answers exactly. The data
  categories collected are identical because this is the same app code
  pointing at a different server. Reference the production listing in
  another browser tab and copy each answer across.

### 4g. Privacy policy
- Use the same URL as the production listing
  (e.g. `https://www.mosquitoalert.com/.../privacy-policy/`). Add a note
  in the listing description that this is a developer test build.

### 4h. App category
- **Category**: Education or Health & Fitness — whichever production uses.
- **Tags**: copy from production.

### 4i. Store listing assets

Reuse the iOS DevTF artwork as much as possible. Most of it lives under
`ios/Runner/Assets.xcassets/AppIconDev.appiconset/`.

- **App icon (512×512 PNG)**: resize from the 1024×1024 DevTF icon:
  ```bash
  sips -Z 512 -s format png \
    ios/Runner/Assets.xcassets/AppIconDev.appiconset/Icon-App-1024x1024@1x.png \
    --out /tmp/test-mosquito-alert-play-icon-512.png
  ```
- **Feature graphic (1024×500 PNG)**: required. If there is no DevTF feature
  graphic, take the production one and overlay a "TEST" badge.
- **Phone screenshots (min 2)**: from a device running the new build, clearly
  showing the "Test Mosquito Alert" name. 1080×1920 or 1080×2400 works.
- **Short description (80 chars)**:
  > Developer test build of Mosquito Alert. Reports go to the dev server only.
- **Full description**: copy the production listing's full description and
  prepend:
  > **This is the developer test build of Mosquito Alert.** It connects to
  > our development server and is distributed only to internal testers and
  > translation collaborators. Reports submitted in this build do not enter
  > the public dataset. For the public app, search for "Mosquito Alert".

### 4j. App content — Government app, financial features, etc.
- All *No*.

---

## 5. Configure Internal testing (the only distribution track)

Do **not** push this app to Closed / Open / Production tracks. Internal testing
is the right channel because:

- It bypasses Play review for each release (typically live in minutes).
- Testers join via a link or by Google account on a closed list.
- The listing is **not publicly searchable** while the app stays in
  Internal testing only.

Steps:

1. **Test and release → Testing → Internal testing → Create new release**.
2. Upload `app-dev-release.aab`.
3. **Release name**: Play auto-fills from the AAB's versionName/versionCode,
   e.g. `2935 (4.3.1)`.
4. **Release notes**: see section 7.
5. **Save → Review release → Start rollout to Internal testing**.

Then on the same Internal testing page:

6. **Testers** tab → **Create email list**:
   - **List name**: `Mosquito Alert internal testers`
   - **Email addresses**: one Google account per line. They must be Google
     accounts (Gmail or Workspace) — personal email aliases won't work.
   - Save, then tick the list to add it to this track.
7. Copy the **Join on Android** opt-in URL and send it to each tester. They
   must open it on their Android device while signed in with the matching
   Google account, tap *Become a tester*, then follow the link to the Play
   Store entry.

If a tester was previously given a sideloaded APK, have them **uninstall it
first**. A sideloaded build is signed with the upload key while the Play build
is signed with Google's app signing key, so if the package names match the
install fails on signature mismatch; if they differ, they end up with two
identically-named apps on the device.

---

## 6. Google Maps API key restrictions

Easy to forget and it fails silently — the map just renders blank.

The test build uses **its own Maps API key**, separate from production's. Set
it as `googlemaps.KeyTest` in `android/local.properties` (prod's lives in
`googlemaps.Key`); the two are injected per-flavor as a manifest placeholder in
`android/app/build.gradle.kts`. Env var equivalents are `GOOGLE_MAPS_KEY_TEST`
and `GOOGLE_MAPS_KEY`.

Keys are restricted per package name + SHA-1 in Google Cloud Console, so the
prod key returns a blank map under the `.test` package and vice versa. The
failure is silent: the build succeeds, the app runs, only the map is empty.
Verify which key actually landed in a built bundle with:

```bash
unzip -p build/app/outputs/bundle/devRelease/app-dev-release.aab \
  base/manifest/AndroidManifest.xml | strings | grep -oE "AIza[A-Za-z0-9_-]{35}"
```

An empty result means no key was baked in at all — the most common cause of a
blank map, and not something Play or the build will warn you about.

Use the **app signing key** SHA-1 from Play Console → Setup → App integrity →
App signing — *not* the upload key — because that is what Play uses to sign the
bundle it delivers to testers. Add the pair:

- Package name: `ceab.movelab.tigatrapp.test`
- SHA-1: the app signing key fingerprint from Play Console

Keep any sideload entry (upload key `4A:FF:55:...`) alongside it if you also
distribute APKs directly.

Restriction changes take a few minutes to propagate, so a blank map immediately
after editing them is not necessarily a misconfiguration.

---

## 7. Release notes

Play rejects language tags for any language without a store listing
translation. The listing's default and currently only language is **es-ES**, so
only that block is valid until EN and CA translations are added.

```
<es-ES>
Primera versión de prueba de la aplicación Mosquito Alert.

Esta versión se conecta a un servidor de pruebas, no al servidor de producción que alimenta nuestro mapa web público y nuestros modelos. Los datos enviados desde esta aplicación no se incluirán en los resultados públicos de Mosquito Alert.
</es-ES>
```

Once EN and CA translations exist, the full block:

```
<es-ES>
Primera versión de prueba de la aplicación Mosquito Alert.

Esta versión se conecta a un servidor de pruebas, no al servidor de producción que alimenta nuestro mapa web público y nuestros modelos. Los datos enviados desde esta aplicación no se incluirán en los resultados públicos de Mosquito Alert.
</es-ES>
<en-US>
First release of a testing version of the Mosquito Alert app.

This version connects to a testing server, not to the production server that feeds our public webmap and models. Data sent from this app will not appear in Mosquito Alert's public results.
</en-US>
<ca>
Primera versió de prova de l'aplicació Mosquito Alert.

Aquesta versió es connecta a un servidor de proves, no al servidor de producció que alimenta el nostre mapa web públic i els nostres models. Les dades enviades des d'aquesta aplicació no s'inclouran als resultats públics de Mosquito Alert.
</ca>
```

Limit is 500 characters per language. The data sentence is phrased
impersonally to avoid the tú/usted and tu/vostè choice.

---

## 8. Versioning convention

Because the `applicationId` differs from production, Play tracks versionCodes
independently. Dev releases cannot block prod releases or vice versa. Play does
require each upload to this listing to have a versionCode higher than the last
one it accepted.

Suggested convention: keep `versionName` aligned with the prod release the test
build derives from, and bump the versionCode in `pubspec.yaml`. No Gradle
change needed.

---

## 9. After every Test Mosquito Alert release

1. Build: `fvm flutter build appbundle --release --flavor dev --target lib/main_dev.dart`
2. Verify package name and signing cert (section 3).
3. Play Console → Test Mosquito Alert → Internal testing → Create new release.
4. Upload the AAB, paste release notes, Save → Review → Start rollout.

Testers who already opted in get the update automatically.

---

## Quick checklist

- [x] Firebase: add Android app `ceab.movelab.tigatrapp.test`.
- [x] Replace `android/app/google-services.json` with the re-downloaded file.
- [x] Generate a separate upload keystore for this listing.
- [x] Wire per-flavor signing configs in `android/app/build.gradle.kts`.
- [x] Build AAB with `--flavor dev --target lib/main_dev.dart`.
- [ ] **Back up `MA_Test_Upload_Keystore.jks` + `key.properties` off-machine.**
- [ ] Complete Play setup checklist (data safety, content rating, target
      audience, privacy policy, category).
- [ ] Upload store assets (512px icon, feature graphic, ≥2 screenshots).
- [ ] Create Internal testing release; upload AAB; paste release notes.
- [ ] Create internal-tester email list; add testers; send opt-in URL.
- [ ] Add `.test` + Play app signing SHA-1 to the Maps API key restrictions.
- [ ] Add CI secret for the dev `google-services.json` (only if CI builds dev).
