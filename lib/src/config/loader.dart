import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:yaml/yaml.dart';

part 'parser.dart';

class ConfigLoader {
  static KConfig load({String? filePath}) {
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
