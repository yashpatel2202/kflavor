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

## Advanced

- Supports both Kotlin (`build.gradle.kts`) and Groovy (`build.gradle`) Android projects
- Handles iOS Info.plist, entitlements
- Customizes Firebase, icons, and manifest per flavor
- Generates and cleans up IDE run/debug configs

## Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## License

[LICENSE](LICENSE)
