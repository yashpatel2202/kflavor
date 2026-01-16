import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:yaml/yaml.dart';

part 'parser.dart';

/// Utility that loads a `KConfig` from a YAML file (default `flavors.yaml`).
///
/// Use `ConfigLoader.load(filePath: path)` to load configuration from a
/// specific path; omit `filePath` to load from the default `flavors.yaml`.
/// Throws if the file cannot be found or parsed.
class ConfigLoader {
  static KConfig load({String? filePath}) {
    if (filePath != null && filePath.isNotEmpty) {
      log.info('Loading configuration from: $filePath');
      return ConfigLoader._load(filePath: filePath);
    }
    log.info('Loading configuration from default location');
    return ConfigLoader._load();
  }

  static KConfig _load({String? filePath}) {
    final file = File(filePath ?? 'flavors.yaml');
    final yamlString = file.readAsStringSync();

    if (!file.existsSync()) {
      throw Exception('${(filePath ?? 'flavors.yaml')} not found');
    }

    var yamlMap = loadYaml(yamlString);

    var jsonString = jsonEncode(yamlMap);

    final value = kConfigFromJson(jsonDecode(jsonString));

    return value;
  }
}
