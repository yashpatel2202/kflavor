import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

/// Generate launcher icons using `flutter_launcher_icons` for configured
/// flavors.
///
/// Writes temporary `flutter_launcher_icons(-<flavor>).yaml` files and invokes
/// the icon generator. Temporary files are removed after generation. No-op if
/// no icon configuration is present.
Future<void> generateIcons(KConfig config) async {
  const fileName = 'flutter_launcher_icons';

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
      Map<String, String> flavoredIcons = {};
      for (final flavor in config.flavors) {
        final content = _getFileContent(flavor.config);
        if (content.hasValue) flavoredIcons[flavor.flavor] = content;
      }
      if (flavoredIcons.isEmpty) break;
      for (final entry in flavoredIcons.entries) {
        final path = '$fileName-${entry.key}.yaml';
        final file = File(path);
        file.writeAsStringSync(entry.value);
        files.add(file);
      }
  }

  if (files.isNotEmpty) {
    await runInTerminal('dart run flutter_launcher_icons');
    for (final file in files) {
      file.deleteSync();
    }
    log.fine('icons generated successfully');
  }
}

String _getFileContent(PlatformConfig config) {
  final hasAndroid = config.android.icon != null;
  final hasiOS = config.ios.icon != null;

  if (!hasAndroid && !hasiOS) return '';

  return '''flutter_launcher_icons:
  android: "ic_launcher"
  ios: $hasiOS
  remove_alpha_ios: true
${hasiOS ? '  image_path_ios: "${config.ios.icon!.path}"' : ''}
${hasAndroid ? '  image_path_android: "${config.android.icon!.path}"' : ''}
${hasAndroid ? '  adaptive_icon_background: "${config.android.icon!.background}"' : ''}
${hasAndroid ? '  adaptive_icon_foreground: "${config.android.icon!.path}"' : ''}'''
      .newLineSterilize;
}
