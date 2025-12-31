class KConfig {
  final FlavorConfig defaultConfig;
  final List<FlavorConfig> flavors;

  const KConfig({required this.defaultConfig, required this.flavors});
}

class FlavorConfig {
  final String flavor;
  final PlatformConfig config;

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
  final IconConfig? icon;

  const Config({
    required this.name,
    required this.bundleId,
    required this.scheme,
    required this.appLink,
    this.icon,
  });
}

class IconConfig {
  final String path;
  final String background;

  const IconConfig({required this.path, required this.background});
}
