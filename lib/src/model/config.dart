import 'package:kflavor/src/utils/string_utils.dart';

sealed class KConfig {
  const KConfig({required this.buildRunner});

  bool get hasAndroidScheme;
  bool get hasAndroidAppLink;

  bool get hasIOSScheme;
  bool get hasIOSAppLink;
  bool get hasIOSDevTeam;

  bool get hasFirebase;

  final bool buildRunner;
}

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

class FlavorConfig {
  final String flavor;
  final PlatformConfig config;

  bool get hasFirebase => config.firebaseProject.hasValue;

  const FlavorConfig({required this.flavor, required this.config});
}

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

class Config {
  final String name;
  final String bundleId;
  final String scheme;
  final String appLink;
  final String developmentTeam;
  final IconConfig? icon;

  bool get hasScheme => scheme.hasValue;
  bool get hasAppLink => appLink.hasValue;
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

class IconConfig {
  final String path;
  final String background;

  const IconConfig({required this.path, required this.background});
}

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
