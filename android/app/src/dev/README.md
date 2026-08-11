# Firebase configuration for the dev flavor

The `dev` flavor builds with applicationId `ceab.movelab.tigatrapp.dev`, so
the Google Services Gradle plugin needs a client entry matching that package
name or `:app:processDevDebugGoogleServices` fails with:

```
No matching client found for package name 'ceab.movelab.tigatrapp.dev'
```

## You probably do not need a file in this directory

A `google-services.json` describes a whole Firebase **project**, not a single
app. Its `client[]` array holds one entry per registered Android app, and the
Gradle plugin picks the entry whose `package_name` matches the applicationId
being built.

So the simplest setup — and the one this repo uses — is a **single**
`android/app/google-services.json` containing every package name, including
`ceab.movelab.tigatrapp.dev`. Add the dev app in Firebase Console under the
existing `mosquitoalert-push-service` project, re-download the file, and
replace `android/app/google-services.json`. Both flavors then resolve from
that one file and this directory needs no `google-services.json` at all.

Seeing several package names in that file is normal, not a misconfiguration.
Entries for apps you no longer ship are harmless — the plugin ignores any
client whose package name is not being built.

## When you *would* put a file here

Only if the dev flavor should talk to a **different Firebase project** from
production — separate analytics, separate push credentials, separate console.
In that case drop that project's `google-services.json` in this directory and
it takes precedence over `android/app/google-services.json` for `dev` builds.

That file is gitignored (see `.gitignore`); in CI, write it from a repository
secret the same way `android/app/google-services.json` is handled.

## Build commands

Once flavors exist Gradle requires one, so `--flavor` is mandatory:

```sh
fvm flutter build appbundle --release --flavor dev  --target lib/main_dev.dart
fvm flutter build appbundle --release --flavor prod --target lib/main.dart
```
