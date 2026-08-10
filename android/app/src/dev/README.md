# Firebase configuration for the dev flavor

Place the `google-services.json` file for the Android app
`ceab.movelab.tigatrapp.dev` here (download it from Firebase Console after
adding a new Android app to the project with that package name).

This file is gitignored (see `.gitignore`); in CI it should be written from
a repository secret, mirroring how `android/app/google-services.json` is
handled for the production flavor.

Build commands:

```sh
fvm flutter build appbundle --flavor dev --target lib/main_dev.dart --release
fvm flutter build appbundle --flavor prod --target lib/main.dart --release
```
