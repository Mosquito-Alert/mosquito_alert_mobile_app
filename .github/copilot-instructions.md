# Mosquito Alert Mobile App

Mosquito Alert is a Flutter mobile application for citizen science mosquito reporting. The app supports Android and iOS platforms and uses Firebase for backend services. The project uses Flutter Version Manager (FVM) to manage Flutter SDK versions.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Initial Setup and Dependencies
- **CRITICAL**: Install Java 21 for Android development:
  ```bash
  sudo apt-get update && sudo apt-get install -y openjdk-21-jdk
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
  export PATH=$JAVA_HOME/bin:$PATH
  ```
- Install FVM (Flutter Version Manager):
  ```bash
  # Install FVM via pub (requires Dart SDK)
  dart pub global activate fvm
  # OR download FVM from https://fvm.app/install and follow instructions
  ```
- Install Flutter using FVM:
  ```bash
  fvm install
  fvm use
  ```
- **NEVER CANCEL**: Flutter installation takes 5-15 minutes. Set timeout to 20+ minutes.

### Bootstrap and Build Process
- **MANDATORY**: Setup Android configuration:
  ```bash
  # Create android/local.properties if it doesn't exist
  echo 'sdk.dir=/path/to/android/sdk' > android/local.properties
  echo 'googlemaps.Key=' >> android/local.properties
  ```
- Get dependencies:
  ```bash
  fvm flutter pub get
  ```
- **NEVER CANCEL**: Dependency download takes 2-5 minutes. Set timeout to 10+ minutes.

### Static Analysis and Testing
- Run static analysis:
  ```bash
  fvm flutter analyze
  ```
- **NEVER CANCEL**: Analysis takes 1-3 minutes. Set timeout to 5+ minutes.
- Run unit tests:
  ```bash
  fvm flutter test
  ```
- **NEVER CANCEL**: Unit tests take 2-5 minutes. Set timeout to 10+ minutes.
- Run integration tests (requires Android emulator):
  ```bash
  fvm flutter test integration_test
  ```
- **NEVER CANCEL**: Integration tests take 10-20 minutes. Set timeout to 30+ minutes.

### Building the Application

#### Android Build
- **Prerequisites**: Java 21, Android SDK, google-services.json file
- Debug build:
  ```bash
  fvm flutter build appbundle --debug
  ```
- Release build:
  ```bash
  fvm flutter build appbundle --release
  ```
- **NEVER CANCEL**: Android builds take 5-15 minutes. Set timeout to 20+ minutes.

#### iOS Build
- **Prerequisites**: macOS, Xcode, CocoaPods, GoogleService-Info.plist file
- Install CocoaPods dependencies:
  ```bash
  cd ios && pod install && cd ..
  ```
- **NEVER CANCEL**: Pod install takes 3-8 minutes. Set timeout to 15+ minutes.
- Build iOS:
  ```bash
  fvm flutter build ios --release --no-codesign
  ```
- **NEVER CANCEL**: iOS builds take 8-20 minutes. Set timeout to 30+ minutes.

### Running the Application

#### Development Environment
- Run development version:
  ```bash
  fvm flutter run --target lib/main_dev.dart
  ```
- Run production version:
  ```bash
  fvm flutter run --target lib/main.dart
  ```
- **NEVER CANCEL**: First run takes 5-10 minutes for compilation. Set timeout to 15+ minutes.

#### Hot Reload and Development
- After initial run, hot reload works instantly with 'r' in terminal
- Hot restart with 'R' in terminal
- Use development target (main_dev.dart) for development work

## Validation Requirements

### Manual Testing Scenarios
After making changes, ALWAYS test these core scenarios:
1. **App Launch**: Verify app starts and shows main screen
2. **Permission Flow**: Test location permissions (critical for mosquito reporting)
3. **Camera Integration**: Test photo capture functionality for mosquito reports
4. **Map Integration**: Verify Google Maps integration works (requires API key)
5. **Report Submission**: Test creating and submitting a mosquito report
6. **Background Tracking**: Verify background location tracking can be enabled/disabled

### Pre-commit Validation
- **ALWAYS** run before committing:
  ```bash
  fvm dart format .
  fvm flutter analyze
  fvm flutter test
  ```
- Pre-commit hooks automatically format Dart code
- CI will fail if any of these commands fail

### CI/CD Validation Steps
The repository uses GitHub Actions that run:
1. Static analysis (`flutter analyze`) - takes 2-3 minutes
2. Unit tests (`flutter test`) - takes 3-5 minutes
3. Android build with Java 21 - takes 10-15 minutes
4. iOS build on macOS - takes 15-25 minutes
5. Integration tests with Android emulator - takes 15-25 minutes

**CRITICAL**: All builds and tests must complete successfully. NEVER CANCEL these operations.

## Project Structure

### Key Directories and Files
```
├── lib/
│   ├── main.dart          # Production entry point
│   ├── main_dev.dart      # Development entry point
│   ├── app_config.dart    # Environment configuration
│   ├── api/               # API service layer
│   ├── models/            # Data models
│   ├── pages/             # UI pages/screens
│   ├── providers/         # State management (Provider pattern)
│   ├── services/          # Business logic services
│   └── utils/             # Utility functions and helpers
├── android/
│   ├── app/build.gradle   # Android app configuration (Java 21)
│   ├── local.properties   # Local Android settings (create manually)
│   └── app/google-services.json  # Firebase config (from secrets)
├── ios/
│   ├── Podfile           # CocoaPods dependencies (iOS 16+)
│   └── Runner/GoogleService-Info.plist  # Firebase config (create manually)
├── assets/               # Images, fonts, HTML content
├── integration_test/     # Integration test suite
└── test/                # Unit test suite
```

### Important Configuration Files
- `.fvmrc`: Specifies Flutter version (3.27.4)
- `pubspec.yaml`: Dependencies and project configuration
- `pubspec.lock`: Locked dependency versions (keep in sync)
- `.pre-commit-config.yaml`: Pre-commit hooks for code formatting

### Firebase Integration
- **Android**: Requires `android/app/google-services.json`
- **iOS**: Requires `ios/Runner/GoogleService-Info.plist`
- Both files are created from Firebase secrets in CI/CD
- For local development, create empty files or get them from Firebase Console

### Google Maps Integration
- Requires API key in `android/local.properties`: `googlemaps.Key=YOUR_KEY`
- App will compile with empty key but maps will show errors
- Get API key from Google Cloud Console with Maps SDK enabled

## Localization

### Updating Translations
- **Python scripts available**:
  ```bash
  python3 update_locales.py
  python3 update_locales_html.py
  ```
- Updates translations from Localise.biz API
- Requires API key (check repository secrets)
- **NEVER CANCEL**: Translation updates take 2-5 minutes

### Locale Configuration
- Supported languages defined in `update_locales.py`
- Minimum 80% translation progress required
- Force-included languages: Spanish (Uruguay)
- Auto-fallback enabled for regional variants

## Development Environment Tips

### FVM (Flutter Version Manager)
- **ALWAYS use FVM commands**: `fvm flutter` instead of `flutter`
- Version locked to Flutter 3.27.4 in `.fvmrc`
- Install: `fvm install` then `fvm use`

### State Management
- Uses Provider pattern for state management
- Key providers in `lib/providers/`:
  - `auth_provider.dart`: Authentication state
  - `device_provider.dart`: Device information
  - `user_provider.dart`: User profile data

### Background Tasks
- Uses `workmanager` package for background location tracking
- Custom fork used (ref: 4ce0651) for iOS compatibility
- Background tracking can be easily disabled in settings

### Permissions Used
- **Camera**: Photo capture for mosquito reports
- **Location**: Always/WhenInUse for mosquito location tracking
- **Photos**: Gallery access for selecting images
- **Notifications**: Push notifications from Firebase
- **Media Library**: Access to photo library

## Troubleshooting Common Issues

### Build Failures
- **"pubspec.lock out of date"**: Run `fvm flutter pub get` and commit changes
- **Java version errors**: Ensure Java 21 is installed and JAVA_HOME is set
- **Google services missing**: Create required Firebase configuration files
- **Pod install fails**: Update CocoaPods and retry `pod install`

### Runtime Issues
- **Maps not loading**: Check Google Maps API key configuration
- **Location not working**: Verify device has location services enabled
- **Camera not working**: Check camera permissions in device settings
- **Push notifications not working**: Verify Firebase configuration

### Development Tips
- **Hot reload**: Use 'r' for quick code changes
- **Full restart**: Use 'R' for state reset
- **Debug console**: Check for error messages in Flutter logs
- **Device logs**: Use `adb logcat` for Android debugging

## Performance Notes

### Expected Command Times
- `fvm flutter pub get`: 0-2 minutes
- `fvm flutter analyze`: 0-1 minutes  
- `fvm flutter test`: 0-1 minutes
- `fvm flutter build appbundle`: 3-10 minutes
- `fvm flutter build ios`: 3-10 minutes
- `pod install`: 1-3 minutes
- Integration tests: 3-10 minutes
- Full CI pipeline: 10-20 minutes

**REMEMBER**: NEVER CANCEL any build or test commands. Use appropriate timeouts and wait for completion.