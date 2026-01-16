import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

/// Generate splash configuration files for `flutter_native_splash`.
///
/// Writes temporary `flutter_native_splash(-<flavor>).yaml` files and invokes
/// `dart run flutter_native_splash:create`. Temporary files are removed after
/// generation. No-op if no splash configuration is present.
Future<void> generateSplash(KConfig config) async {
  const fileName = 'flutter_native_splash';

  List<File> files = [];

  switch (config) {
    case DefaultConfig():
      final content = _getFileContent(config.config.config);
      if (content.isEmpty) break;
      const path = '$fileName.yaml';
      final file = File(path);
      file.writeAsStringSync(content);
      files = [file];
    case FlavoredConfig():
      Map<String, String> flavored = {};
      for (final flavor in config.flavors) {
        final content = _getFileContent(flavor.config);
        if (content.hasValue) flavored[flavor.flavor] = content;
      }
      if (flavored.isEmpty) break;
      for (final entry in flavored.entries) {
        final path = '$fileName-${entry.key}.yaml';
        final file = File(path);
        file.writeAsStringSync(entry.value);
        files.add(file);
      }
  }

  if (files.isNotEmpty) {
    await runInTerminal(
      'dart run flutter_native_splash:create${files.length > 1 ? ' -A' : ''}',
    );
    for (final file in files) {
      file.deleteSync();
    }
    log.fine('splash generated successfully');
  }
}

String _getFileContent(PlatformConfig config) {
  final s = config.splash;
  if (s == null) return '';

  final bg = s.background;
  final icon = s.iconPath;
  final iconBg = s.iconBackground;

  return '''flutter_native_splash:
  color: "$bg"
  ${icon.hasValue ? 'image: "$icon"' : ''}
  android_12:
    color: "$bg"
    ${icon.hasValue ? 'image: "$icon"' : ''}
    icon_background_color: "$iconBg"
'''
      .newLineSterilize;
}
