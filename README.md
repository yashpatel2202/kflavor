<div align="center">
  <a href="https://kflavor.iamyash.in/">
    <img src="https://kflavor.iamyash.in/icon.png" width="180" alt="kFlavor Logo" />
  </a>
  <h1>kFlavor</h1>
  <p>
    Simplify your Flutter multi-flavor setup with a single YAML configuration. Automate build flavors, firebase, icons, and IDE configs effortlessly.
  </p>
  <a href="https://kflavor.iamyash.in/docs">
    <img src="https://img.shields.io/badge/Documentation-7952B3?style=for-the-badge" alt="Documentation" />
  </a>
  &nbsp;&nbsp;
  <a href="https://kflavor.iamyash.in/prepare">
    <img src="https://img.shields.io/badge/Prepare_YAML-7952B3?style=for-the-badge" alt="Prepare YAML" />
  </a>
  <br>
  <br>
</div>

## Features

- Generate and manage Android/iOS build flavors from a single YAML file
- No need to maintain multiple messy looking `main.dart` entrypoint. uses single `main.dart` entrypoint.
- Automatic configuration of Gradle (Kotlin & Groovy) and Xcode projects
- Firebase integration and configuration per flavor
- Icon generation for each flavor
- Generates Android Studio and VSCode run/debug configurations
- Supports custom arguments for CLI automation
- Easy integration with CI/CD pipelines
- Eliminates the need to maintain multiple `AndroidManifest.xml` files.
- Splash screen generation

## Getting started

1. Add kflavor to your dev dependencies in `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     kflavor:
   ```
2. Run `dart pub get` or `flutter pub get`.
3. Create a `flavors.yaml` file in your project root or use the [Prepare YAML](https://kflavor.iamyash.in/prepare) tool.
4. Run the CLI tool:
   ```sh
   dart run kflavor generate
   ```

For more information, see the [CLI Documentation](https://kflavor.iamyash.in/docs/cli).

## Usage

### Example `flavors.yaml`

```yaml
flavors:
  dev:
    id: myapp.app.dev
    name: MyApp Dev
    icon:
      ios: assets/icon/icon_dev.png
      android:
        path: assets/icon/icon_android.png
        background: "#E0F9FF"
    firebase: firebase-dev-project-id
  prod:
    id: myapp.app
    name: MyApp
    icon:
      ios: assets/icon/icon.png
      android:
        path: assets/icon/icon_android.png
        background: "#FFFFFF"
    firebase: firebase-prod-project-id
```

For a full, annotated example and detailed reference, see the project's example `flavors.yaml`: [Valid YAML Configuration](https://kflavor.iamyash.in/docs/configuration)

### Icon preparation

kflavor includes template icons you can use as a visual guide and to ensure all flavors have consistent icon boundaries and spacing. The templates are located here: [Icon Configuration](https://kflavor.iamyash.in/docs/icons)

### Manually run/build/archive from terminal (per flavor)

Below are common terminal commands and patterns for running, building, and archiving your app for a specific flavor. Replace `<flavor>` with your flavor name.

- Flutter (run on device/emulator):

  ```
  flutter run --flavor <flavor>
  ```

#### Single-flavor behavior

If your `flavors.yaml` defines exactly one flavor, kflavor treats the project as a "no-flavor" configuration. That means you do not need to pass a `--flavor` to kflavor's CLI or to Flutter build/run commands — the single flavor is used as the default. If you add additional flavors later, pass the desired flavor name to the commands shown below.

## Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## License

[LICENSE](LICENSE)
