import 'package:kflavor/src/utils/string_utils.dart';

sealed class KConfig {
  const KConfig({required this.buildRunner});

  /// True when Android scheme (custom URL scheme) is present in any flavor.
  bool get hasAndroidScheme;

  /// True when Android app link (https) is present in any flavor.
  bool get hasAndroidAppLink;

  /// True when iOS URL scheme is present in any flavor.
  bool get hasIOSScheme;

  /// True when iOS app link (associated domains) is present in any flavor.
  bool get hasIOSAppLink;

  /// True when an iOS development team is provided for any flavor.
  bool get hasIOSDevTeam;

  /// True when any flavor includes a Firebase project id.
  bool get hasFirebase;

  final bool buildRunner;
}

/// Represents a single (non-flavored) configuration.
class DefaultConfig extends KConfig {
  final FlavorConfig config;

  @override
  bool get hasAndroidScheme => config.config.android.hasScheme;
  @override
  bool get hasAndroidAppLink => config.config.android.hasAppLink;

  @override
  bool get hasIOSScheme => config.config.ios.hasScheme;
  @override
  bool get hasIOSAppLink => config.config.ios.hasAppLink;
  @override
  bool get hasIOSDevTeam => config.config.ios.hasDevTeam;

  @override
  bool get hasFirebase => config.hasFirebase;

  const DefaultConfig({required this.config, required super.buildRunner});
}

/// Represents multiple flavors defined in the configuration.
class FlavoredConfig extends KConfig {
  final List<FlavorConfig> flavors;

  @override
  bool get hasAndroidScheme => flavors.any((e) => e.config.android.hasScheme);
  @override
  bool get hasAndroidAppLink => flavors.any((e) => e.config.android.hasAppLink);

  @override
  bool get hasIOSScheme => flavors.any((e) => e.config.ios.hasScheme);
  @override
  bool get hasIOSAppLink => flavors.any((e) => e.config.ios.hasAppLink);
  @override
  bool get hasIOSDevTeam => flavors.any((e) => e.config.ios.hasDevTeam);

  @override
  bool get hasFirebase => flavors.any((e) => e.hasFirebase);

  const FlavoredConfig({required this.flavors, required super.buildRunner});
}

/// Wrapper for a single flavor and its platform-specific `PlatformConfig`.
class FlavorConfig {
  final String flavor;
  final PlatformConfig config;

  /// True when this flavor has an associated Firebase project id.
  bool get hasFirebase => config.firebaseProject.hasValue;

  const FlavorConfig({required this.flavor, required this.config});
}

/// Platform-scoped configuration (android + ios) and optional firebase id.
class PlatformConfig {
  final Config android;
  final Config ios;
  final String firebaseProject;

  const PlatformConfig({
    required this.android,
    required this.ios,
    required this.firebaseProject,
  });
}

/// Platform-specific configuration details used when generating platform
/// artifacts (bundle/app ids, scheme, app link, team, icon).
class Config {
  final String name;
  final String bundleId;
  final String scheme;
  final String appLink;
  final String developmentTeam;
  final IconConfig? icon;

  /// True when a custom URL scheme is defined.
  bool get hasScheme => scheme.hasValue;

  /// True when an HTTPS app-link (associated domain) is defined.
  bool get hasAppLink => appLink.hasValue;

  /// True when an iOS development team is specified.
  bool get hasDevTeam => developmentTeam.hasValue;

  const Config({
    required this.name,
    required this.bundleId,
    required this.scheme,
    required this.appLink,
    required this.developmentTeam,
    this.icon,
  });
}

/// Icon asset information (path and optional adaptive background).
class IconConfig {
  final String path;
  final String background;

  const IconConfig({required this.path, required this.background});
}

/// Helper extension to map and join flavor-specific content for generators.
extension KConfigExtra on KConfig {
  String mapper({
    required String Function(FlavorConfig config) map,
    String join = '',
  }) {
    final config = this;

    switch (config) {
      case DefaultConfig():
        return map(config.config);
      case FlavoredConfig():
        return config.flavors.map((e) => map(e)).join(join);
    }
  }
}
