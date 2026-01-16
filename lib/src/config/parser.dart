part of 'loader.dart';

/// Parse a decoded JSON/YAML map into a `KConfig` model.
///
/// This converts the provided `json` map into either a `DefaultConfig` or a
/// `FlavoredConfig`, validating required fields (like `name` and `id`) and
/// normalizing per-platform values. Throws `StateError` for missing required
/// flavor fields.
KConfig kConfigFromJson(Map<String, dynamic> json) {
  final global = json;
  final flavorsNode = _map(json['flavors']);
  final buildRunner = _getBuildRunner(json);

  if (flavorsNode == null) {
    return DefaultConfig(
      buildRunner: buildRunner,
      config: FlavorConfig(
        flavor: '',
        config: _buildPlatformConfig(global, null),
      ),
    );
  }

  final flavorEntries = <String, Map<String, dynamic>>{};

  for (final entry in flavorsNode.entries) {
    final m = _map(entry.value);
    flavorEntries[entry.key] = m ?? {};
  }

  final flavorCount = flavorEntries.length;

  final flavors = <FlavorConfig>[];

  for (final entry in flavorEntries.entries) {
    final flavorKey = entry.key;
    final flavorMap = entry.value;

    if (!_hasName(global, flavorMap)) {
      throw StateError(
        'Flavor "$flavorKey" is missing required "name" '
        '(not provided in flavor or global)',
      );
    }

    if (!_hasId(global, flavorMap)) {
      throw StateError(
        'Flavor "$flavorKey" is missing required "id" '
        '(not provided in flavor or global)',
      );
    }

    flavors.add(
      FlavorConfig(
        flavor: entry.key,
        config: _buildPlatformConfig(global, entry.value),
      ),
    );
  }

  if (flavorCount == 1) {
    final only = flavorEntries.values.first;

    return DefaultConfig(
      buildRunner: buildRunner,
      config: FlavorConfig(
        flavor: '',
        config: _buildPlatformConfig(global, only),
      ),
    );
  }

  return FlavoredConfig(buildRunner: buildRunner, flavors: flavors);
}

bool _getBuildRunner(Map<String, dynamic> json) {
  final value = json['build_runner'];
  if (value is bool) return value;
  if (value is String) {
    return ['true', 'yes'].contains(value.toLowerCase());
  }
  return false;
}

String _str(dynamic v) => v?.toString() ?? '';

Map<String, dynamic>? _map(dynamic v) => v is Map<String, dynamic> ? v : null;

bool _hasName(Map<String, dynamic>? global, Map<String, dynamic> flavor) {
  return _str(flavor['name']).isNotEmpty || _str(global?['name']).isNotEmpty;
}

bool _hasId(Map<String, dynamic>? global, Map<String, dynamic> flavor) {
  bool has(dynamic id) =>
      id is String && id.isNotEmpty ||
      id is Map &&
          (_str(id['android']).isNotEmpty || _str(id['ios']).isNotEmpty);

  return has(flavor['id']) || has(global?['id']);
}

String _platformId(dynamic id, String platform) {
  if (id == null) return '';
  if (id is String) return id;
  if (id is Map) return _str(id[platform]);
  return '';
}

IconConfig? _parseIcon(dynamic icon) {
  if (icon == null) return null;

  if (icon is String) {
    return IconConfig(path: icon, background: '');
  }

  if (icon is Map) {
    final path = _str(icon['path']);
    if (path.isEmpty) return null;

    return IconConfig(path: path, background: _str(icon['background']));
  }

  return null;
}

/// Parse a generic icon node. This will try to find a usable icon from
/// different shapes used in the YAML:
/// - String: path
/// - Map with platform keys (android/ios): prefer android then ios
/// - Map with path/background: use directly
IconConfig? _parseAnyIcon(dynamic iconNode) {
  if (iconNode == null) return null;

  // Direct path string
  if (iconNode is String) return IconConfig(path: iconNode, background: '');

  // Map: could be platform keyed or direct path/background
  if (iconNode is Map) {
    if (iconNode.containsKey('android')) {
      return _parseIcon(iconNode['android']);
    }
    if (iconNode.containsKey('ios')) {
      return _parseIcon(iconNode['ios']);
    }

    // Assume it's a direct icon map with path/background
    return _parseIcon(iconNode);
  }

  return null;
}

/// Parse splash configuration (common - not platform specific).
/// Behavior:
/// - Use flavor.splash if present, otherwise fall back to global.splash.
/// - If splash.icon is provided use it (string or map{path,background}).
/// - If splash.icon is NOT provided, fall back to the flavor icon then global
///   icon (using whichever platform-specific icon is present).
SplashConfig? _parseSplash({
  required Map<String, dynamic>? global,
  required Map<String, dynamic>? flavor,
}) {
  final splashNode = _map(flavor?['splash']) ?? _map(global?['splash']);
  if (splashNode == null) return null;

  final background = _str(splashNode['background']);

  // Parse explicit splash.icon if provided
  final rawSplashIcon = splashNode['icon'];

  String iconPath = '';
  String iconBg = '';

  if (rawSplashIcon != null) {
    if (rawSplashIcon is String) {
      iconPath = rawSplashIcon;
      iconBg = '';
    } else if (rawSplashIcon is Map) {
      iconPath = _str(rawSplashIcon['path']);
      iconBg = _str(rawSplashIcon['background']);
    }

    // If explicit icon provided but path is empty, treat as not provided and
    // attempt to fall back to icon config below.
    if (iconPath.hasValue) {
      return SplashConfig(
        iconPath: iconPath,
        iconBackground: iconBg,
        background: background,
      );
    }
  }

  // No explicit splash.icon or it was empty -> fall back to flavor/global icon
  final useIcon = _parseAnyIcon(_map(flavor?['icon']) ?? global?['icon']);

  if (useIcon != null) {
    iconPath = useIcon.path;
    iconBg = useIcon.background;

    return SplashConfig(
      iconPath: iconPath,
      iconBackground: iconBg,
      background: background,
    );
  }

  // No icon found, return splash with empty icon fields
  return SplashConfig(iconPath: '', iconBackground: '', background: background);
}

Config _resolveConfig({
  required String platform,
  required Map<String, dynamic>? global,
  required Map<String, dynamic>? flavor,
}) {
  final gIcon = _parseIcon(_map(global?['icon'])?[platform]);
  final fIcon = _parseIcon(_map(flavor?['icon'])?[platform]);

  return Config(
    name: _str(flavor?['name']).isNotEmpty
        ? _str(flavor?['name'])
        : _str(global?['name']),
    bundleId: _platformId(flavor?['id'], platform).isNotEmpty
        ? _platformId(flavor?['id'], platform)
        : _platformId(global?['id'], platform),
    scheme: _str(flavor?['scheme']).isNotEmpty
        ? _str(flavor?['scheme'])
        : _str(global?['scheme']),
    appLink: _str(flavor?['app_link']).isNotEmpty
        ? _str(flavor?['app_link'])
        : _str(global?['app_link']),
    developmentTeam: _str(flavor?['ios_development_team']).isNotEmpty
        ? _str(flavor?['ios_development_team'])
        : _str(global?['ios_development_team']),
    icon: fIcon ?? gIcon,
  );
}

PlatformConfig _buildPlatformConfig(
  Map<String, dynamic>? global,
  Map<String, dynamic>? flavor,
) {
  return PlatformConfig(
    android: _resolveConfig(
      platform: 'android',
      global: global,
      flavor: flavor,
    ),
    ios: _resolveConfig(platform: 'ios', global: global, flavor: flavor),
    firebase: _parseFirebase(global: global, flavor: flavor),
    splash: _parseSplash(global: global, flavor: flavor),
  );
}

/// Parse the firebase configuration which may be expressed in multiple ways:
/// - String: shorthand project id
/// - Map: { project, account, web_id | webId }
/// Also supports the older top-level `firebase_account` fallback for account.
FirebaseConfig? _parseFirebase({
  required Map<String, dynamic>? global,
  required Map<String, dynamic>? flavor,
}) {
  final raw = flavor?['firebase'] ?? global?['firebase'];

  // If not present as a node, there's nothing to parse.
  if (raw == null) return null;

  // Helper to find top-level firebase_account (legacy)
  String fallbackAccount() {
    return _str(flavor?['firebase_account']).hasValue
        ? _str(flavor?['firebase_account'])
        : _str(global?['firebase_account']);
  }

  if (raw is String) {
    final project = raw.trim();
    if (!project.hasValue) return null;
    return FirebaseConfig(
      project: project,
      account: fallbackAccount(),
      webId: '',
    );
  }

  if (raw is Map) {
    final project = _str(raw['project']).hasValue
        ? _str(raw['project'])
        : _str(raw['project_id']);

    if (!project.hasValue) return null;

    String account = '';
    if (_str(raw['account']).hasValue) {
      account = _str(raw['account']);
    } else {
      account = fallbackAccount();
    }

    final webId = _str(raw['web_id']).hasValue
        ? _str(raw['web_id'])
        : _str(raw['webId']);

    return FirebaseConfig(project: project, account: account, webId: webId);
  }

  return null;
}
