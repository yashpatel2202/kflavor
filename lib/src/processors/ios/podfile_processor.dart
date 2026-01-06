import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';

void updatePodFile(KConfig config) {
  final podfile = File('ios/Podfile');

  final newProjectBlock = _buildProjectBlock(config);

  final content = podfile.readAsStringSync();

  final projectRegex = RegExp(
    r"project\s+'Runner'\s*,\s*\{[\s\S]*?\}",
    multiLine: true,
  );

  if (!projectRegex.hasMatch(content)) return;

  final updated = content.replaceFirst(projectRegex, newProjectBlock);

  podfile.writeAsStringSync(updated);
}

String _buildProjectBlock(KConfig config) {
  return '''project 'Runner', {
${config.mapper(map: _typeLine, join: '\n\n')}
}''';
}

String _typeLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '''
  'Debug${flavor.hasValue ? '-$flavor' : ''}' => :debug,
  'Profile${flavor.hasValue ? '-$flavor' : ''}' => :release,
  'Release${flavor.hasValue ? '-$flavor' : ''}' => :release,''';
}
