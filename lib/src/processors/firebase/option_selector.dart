import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';

void generateFirebaseOptions(KConfig config) {
  const filePath = 'lib/firebase_options.dart';
  final file = File(filePath);

  if (file.existsSync()) {
    file.deleteSync(recursive: true);
  }

  if (!config.hasFirebase) return;

  final content = _getContent(config);
  file.writeAsStringSync(content);
}

String _getContent(KConfig config) {
  final accessibleFlavor = _getAccessibleFlavor(config);

  return '''import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
${accessibleFlavor.map((e) => _importLine(e)).join('')}
import 'kflavor/flavors.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (KFlavor.current?.flavor) {
      case null:
        return null;
${switch (config) {
    DefaultConfig() => _switchLine(config.config.flavor, accessibleFlavor.contains(config.config.flavor)),
    FlavoredConfig() => config.flavors.map((e) => _switchLine(e.flavor, accessibleFlavor.contains(e.flavor))).join(''),
  }}    }
  }
}
''';
}

List<String> _getAccessibleFlavor(KConfig config) {
  List<String> flavors = [];

  void checkAndAddFlavor(String flavor) {
    final file = File(
      'lib/kflavor/firebase_options/firebase_options${flavor.hasValue ? '_$flavor' : ''}.dart',
    );
    final available = file.existsSync();
    if (available) flavors.add(flavor);
  }

  switch (config) {
    case DefaultConfig():
      checkAndAddFlavor(config.config.flavor);
    case FlavoredConfig():
      for (final flavor in config.flavors) {
        checkAndAddFlavor(flavor.flavor);
      }
  }

  return flavors;
}

String _importLine(String flavor) =>
    '\nimport \'kflavor/firebase_options/firebase_options${flavor.hasValue ? '_$flavor' : ''}.dart\' as ${flavor.hasValue ? '${flavor}_' : ''}options;';

String _switchLine(String flavor, bool hasFlavor) =>
    '''      case KFlavorType.${flavor.hasValue ? flavor : 'none'}:
        return ${hasFlavor ? '${flavor.hasValue ? '${flavor}_' : ''}options.DefaultFirebaseOptions.currentPlatform' : 'null'};\n''';
