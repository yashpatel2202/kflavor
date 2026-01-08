<p align="center">
<img src="https://raw.githubusercontent.com/yashpatel2202/kflavor/main/banner_mini.jpg" alt="kflavor" />
</p>

# kflavor

A Flutter tool to automate and simplify multi-flavor app configuration for Android, iOS, and cross-platform development. kflavor helps you manage build flavors, Firebase configs, icons, Gradle and Xcode settings, and generates IDE run/debug configurations for Android Studio and VSCode.

## Features

- Generate and manage Android/iOS build flavors from a single YAML file
- No need to maintain multiple messy looking `main.dart` entrypoint. uses single `main.dart` entrypoint.
- Automatic configuration of Gradle (Kotlin & Groovy) and Xcode projects
- Firebase integration and configuration per flavor
- Icon generation for each flavor
- Generates Android Studio and VSCode run/debug configurations
- Supports custom arguments for CLI automation
- Easy integration with CI/CD pipelines

## Getting started

1. Add kflavor to your dev dependencies in `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     kflavor:
   ```
2. Run `dart pub get` or `flutter pub get`.
3. Create a `flavors.yaml` file in your project root or use the example provided.
4. Run the CLI tool:
   ```sh
   dart run kflavor
   ```

## Usage

### Basic CLI

```sh
dart run kflavor
```
Alternatively, you can pass path for `flavor.yaml` file
```sh
dart run kflavor --file flavors.yaml
```

### Generate IDE Configurations
To Auto-generate IDE Run/Debug config, use following command-line-arguments
- Android Studio:
  ```sh
  dart run kflavor --configure-android-studio
  # or
  dart run kflavor --cas
  ```
- VSCode:
  ```sh
  dart run kflavor --configure-vscode
  # or
  dart run kflavor --cvs
  ```

### Example `flavors.yaml`

```yaml
flavors:
  dev:
    id: myapp.app.dev
    app_name: MyApp Dev
    icon:
      ios: assets/icon/icon_dev.png
      android:
        path: assets/icon/icon_android.png
        background: "#E0F9FF"
    firebase: firebase-dev-project-id
  prod:
    id: myapp.app
    app_name: MyApp
    icon:
      ios: assets/icon/icon.png
      android:
        path: assets/icon/icon_android.png
        background: "#FFFFFF"
    firebase: firebase-prod-project-id
```

### flavors.yaml reference

Below is a compact 1–2 line reference for every supported key in `flavors.yaml`, with example syntax for each entry. Use these snippets as building blocks — per-flavor values inside `flavors:` override global values.

- `flavors:` — Root mapping containing one or more flavor entries (e.g. `dev`, `qa`, `prod`).

  ```yaml
  flavors:
    dev:
    prod:
  ```

- `name` — Optional global display name for the app; flavors may override it with their own `name`.
  ```yaml
  name: MyApp
  ```

- `id` — Global bundle/application id used by Android (applicationId) and iOS (bundle identifier). Can be a string or a platform map.
  ```yaml
  # single id for both platforms
  id: com.example.myapp
  ```

  ```yaml
  # platform-specific ids
  id:
    android: com.example.myapp.android
    ios: com.example.myapp.ios
  ```

- `firebase` — Optional Firebase project id or label used to pick/copy Firebase config per flavor.
  ```yaml
  firebase: my-firebase-project-id
  ```

- `scheme` — Optional URL scheme for deep links (overrides per-flavor if set there).
  ```yaml
  scheme: myapp
  ```

- `app_link` — Optional App Link / Universal Link domain for the app (e.g. `example.com`).
  ```yaml
  app_link: app.example.com
  ```

- `icon` — Global icon configuration. Use `ios` for iOS icon path and `android` for Android icon config (path and optional adaptive background color).
  ```yaml
  icon:
    ios: assets/icon/icon.png
    android:
      path: assets/icon/icon_android.png
      background: "#FFFFFF"
  ```

  - `icon.ios` — path to the iOS icon source image (relative to project root).
    `ios: assets/icon/icon.png`
  - `icon.android.path` — path to the Android icon source image.
    `path: assets/icon/icon_android.png`
  - `icon.android.background` — optional hex background for Android adaptive icons. Always quote hex strings.
    `background: "#e0f9ff"`

- `ios_development_team` — Optional Apple Team ID used for automatic signing when generating Xcode targets.
  ```yaml
  ios_development_team: ABCD1EFG2H
  ```

- `build_runner` — Optional boolean toggling generated build runner behaviors in the tool.
  ```yaml
  build_runner: true
  ```

Per-flavor keys (inside `flavors:`)
- Each flavor is a mapping that can include the same keys as the global config; values here override the global values.

  ```yaml
  flavors:
    dev:
      name: MyApp Dev
      id: com.example.myapp.dev
      firebase: my-firebase-dev
      scheme: myapp-dev
      app_link: dev.app.example.com
      icon:
        ios: assets/icon/icon_dev.png
        android:
          path: assets/icon/icon_android_dev.png
          background: "#e0f9ff"
  ```

Notes & quick tips
- Quote hex colors (e.g. `"#e0f9ff"`) so YAML doesn't treat `#` as a comment.
- Paths are relative to the repository root (where `pubspec.yaml` lives).
- Use platform-specific `id` mappings when Android and iOS identifiers must differ.
- Validate YAML with an editor linter or `yamllint` if you see parsing errors.

For a full, annotated example and detailed reference, see the project's example `flavors.yaml`: [example/flavors.yaml](https://github.com/yashpatel2202/kflavor/blob/main/example/flavors.yaml)

### Icon preparation

kflavor includes template icons you can use as a visual guide and to ensure all flavors have consistent icon boundaries and spacing. The templates are located in the example app:

- [example/assets/icon/](https://github.com/yashpatel2202/kflavor/tree/main/example/assets/icon)

Preparation checklist and recommendations:

- Create one set of icons per flavor. If you have three flavors (e.g. `dev`, `qa`, `prod`), prepare three icon sets.
- Use the template icons in `example/assets/icon/` as the exact visual boundary and spacing guide. Keep the transparent margins / blank space the same as the templates for both Android and iOS icons so generated adaptive icons and platform icons align visually across flavors.
- Keep source images at the same pixel dimensions as the template files. This avoids unexpected cropping or scaling when kflavor or platform tooling generates resized assets.
- For Android adaptive icons, prepare a foreground image (main artwork) and a background image/color if you want an adaptive icon with a separate background. If the template uses a single PNG, match its layout and blank space.
- For iOS, provide a high-resolution square PNG (the template preserves the safe area and margins). Using the same visual boundary ensures icons look consistent when iOS masks/rounds them.

### Manually run/build/archive from terminal (per flavor)

Below are common terminal commands and patterns for running, building, and archiving your app for a specific flavor. Replace `<flavor>` with your flavor name.

- Flutter (run on device/emulator):
  ```
  flutter run --flavor <flavor>
  ```
  - If you have a single-flavor project, you can often run `flutter run` without `--flavor` (use your default entrypoint as appropriate).

- Flutter (build Android APK / AAB):
  ```
  flutter build apk --flavor <flavor>
  flutter build appbundle --flavor <flavor>
  ```

- Flutter (build iOS / create an .ipa):
  ```
  flutter build ipa --flavor <flavor>
  ```
  - Alternatively archive with Xcode:
    - Open `ios/Runner.xcworkspace`, select the scheme for your flavor and Archive via Xcode's Product → Archive.
    
#### Single-flavor behavior

If your `flavors.yaml` defines exactly one flavor, kflavor treats the project as a "no-flavor" configuration. That means you do not need to pass a `--flavor` to kflavor's CLI or to Flutter build/run commands — the single flavor is used as the default. If you add additional flavors later, pass the desired flavor name to the commands shown below.

### Safely git-ignorable files

The following files and directories are typically generated per-flavor or contain machine-specific configuration and can be safely added to your project's `.gitignore` (they are environment/build artifacts or local config files that should not be committed):
```
/android/app/src/{any_flavor}          # generated Android flavor source directories
/android/app/kflavor.gradle.kts        # generated Gradle Kotlin script for kflavor
/lib/kflavor                           # generated Dart helper library
/firebase.json                         # local Firebase emulator or config file
/lib/firebase_options.dart             # generated FlutterFire options file
/android/app/src/google-services.json  # Android Firebase config
/ios/Configs/                          # generated iOS configuration directory
/ios/Runner/GoogleService-Info.plist   # iOS Firebase config
/lib/kflavor/                          # generated with firebase options
```
Add these entries to `.gitignore` in your project root to avoid committing local/generated config files.

## Advanced

- Supports both Kotlin (`build.gradle.kts`) and Groovy (`build.gradle`) Android projects
- Handles iOS Info.plist, entitlements
- Customizes Firebase, icons, and manifest per flavor
- Generates and cleans up IDE run/debug configs

## Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## License

[LICENSE](LICENSE)
