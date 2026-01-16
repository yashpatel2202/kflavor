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
    firebaseProject: _str(flavor?['firebase']).isNotEmpty
        ? _str(flavor?['firebase'])
        : _str(global?['firebase']),
    firebaseAccount: _str(flavor?['firebase_account']).isNotEmpty
        ? _str(flavor?['firebase_account'])
        : _str(global?['firebase_account']),
  );
}
