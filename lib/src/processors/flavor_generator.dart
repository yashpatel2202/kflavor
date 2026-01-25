import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:recase/recase.dart';

/// Generate the Dart flavor provider file at `lib/kflavor/flavors.dart`.
///
/// The generated file exposes `KFlavor` and `KFlavorType` with per-flavor
/// platform values (ids, appName, scheme, appLink). This is used by the app
/// at runtime to access current flavor values.
void generateFlavorProvider(KConfig config) {
  final content = _getContent(config);

  const path = 'lib/kflavor/flavors.dart';
  final file = File(path);

  file.parent.createSync(recursive: true);

  file.writeAsStringSync(content);
}

String _getContent(KConfig config) {
  return '''import 'package:flutter/services.dart';

enum KFlavorType { ${switch (config) {
    DefaultConfig() => 'none',
    FlavoredConfig() => config.flavors.map((e) => e.flavor).join(', '),
  }} }

sealed class KFlavor {
  static KFlavor? get current => KFlavor._current;

  /// Flavor type
  KFlavorType get flavor;

  /// Android specific values
  PlatformFlavor get android;

  /// iOS specific values
  PlatformFlavor get ios;

  const KFlavor();

  static KFlavor? get _current {
    final flavor = KFlavorType.values
        .where((e) => e.name == appFlavor)
        .firstOrNull;
    
    return switch (flavor) {
      null => ${switch (config) {
    DefaultConfig() => 'const _NoneFlavor()',
    FlavoredConfig() => 'null',
  }},
${switch (config) {
    DefaultConfig() => _currentFlavorSwitch('none'),
    FlavoredConfig() => config.flavors.map((e) => _currentFlavorSwitch(e.flavor)).join(''),
  }}    };
  }
}

class PlatformFlavor {
  /// ApplicationId for android & BundleId for iOS.
  final String id;

  /// Name of application.
  final String appName;

  /// Deeplink scheme. i.e. my-app://\\<custom>/\\<path>
  final String? scheme;

  /// HTTPS app-link. i.e. https://www.my-app.com/\\<custom>/\\<path>
  final String? appLink;

  const PlatformFlavor({
    required this.id,
    required this.appName,
    this.scheme,
    this.appLink,
  });
}

${switch (config) {
    DefaultConfig() => _currentFlavorClass(config.config),
    FlavoredConfig() => config.flavors.map((e) => _currentFlavorClass(e)).join('\n'),
  }}''';
}

String _currentFlavorSwitch(String flavor) =>
    '      KFlavorType.$flavor => const _${flavor.pascalCase}Flavor(),\n';

String _currentFlavorClass(FlavorConfig config) {
  final flavor = config.flavor.hasValue ? config.flavor : 'none';
  final android = config.config.android;
  final ios = config.config.ios;

  return '''
final class _${flavor.pascalCase}Flavor extends KFlavor {
  @override
  KFlavorType get flavor => .$flavor;

  @override
  PlatformFlavor get android => const PlatformFlavor(
${_platformValues(android)}
  );

  @override
  PlatformFlavor get ios => const PlatformFlavor(
${_platformValues(ios)}
  );

  const _${flavor.pascalCase}Flavor();
}
''';
}

String _platformValues(Config config) {
  return '''    id: '${config.bundleId}',
    appName: '${config.name}',
    scheme: '${config.scheme.hasValue ? config.scheme : 'null'}',
    appLink: '${config.appLink.hasValue ? config.appLink : 'null'}',''';
}
