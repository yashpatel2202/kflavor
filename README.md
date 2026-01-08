![](banner_mini.jpg)

# kflavor

A Flutter tool to automate and simplify multi-flavor app configuration for Android, iOS, and cross-platform development. kflavor helps you manage build flavors, Firebase configs, icons, Gradle and Xcode settings, and generates IDE run/debug configurations for Android Studio and VSCode.

## Features

- Generate and manage Android/iOS build flavors from a single YAML file
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

## flavors.yaml reference

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

For a full, annotated example and detailed reference, see the project's example `flavors.yaml`: [example/flavors.yaml](example/flavors.yaml)

## Advanced

- Supports both Kotlin (`build.gradle.kts`) and Groovy (`build.gradle`) Android projects
- Handles iOS Info.plist, entitlements
- Customizes Firebase, icons, and manifest per flavor
- Generates and cleans up IDE run/debug configs

## Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## License

[LICENSE](LICENSE)
