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
  return '''import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
${switch (config) {
    DefaultConfig() => _importLine(config.config.flavor),
    FlavoredConfig() => config.flavors.map((e) => _importLine(e.flavor)).join(''),
  }}
import 'kflavor/flavors.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (KFlavor.current?.flavor) {
      case null:
        return null;
${switch (config) {
    DefaultConfig() => _switchLine(config.config.flavor),
    FlavoredConfig() => config.flavors.map((e) => _switchLine(e.flavor)).join(''),
  }}    }
  }
}
''';
}

String _importLine(String flavor) =>
    '\nimport \'kflavor/firebase_options/firebase_options${flavor.hasValue ? '_$flavor' : ''}.dart\' as ${flavor.hasValue ? '${flavor}_' : ''}options;';

String _switchLine(String flavor) =>
    '''      case KFlavorType.${flavor.hasValue ? flavor : 'none'}:
        return ${flavor.hasValue ? '${flavor}_' : ''}options.DefaultFirebaseOptions.currentPlatform;\n''';
