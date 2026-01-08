import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/model/config.dart';

void generateVSCodeRunConfig(KConfig config) {
  final dir = Directory('.vscode');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final file = File('.vscode/launch.json');
  Map<String, dynamic> launchConfig = {
    'version': '0.2.0',
    'configurations': [],
  };

  if (file.existsSync()) {
    try {
      final content = file.readAsStringSync();
      final jsonContent = json.decode(content);
      if (jsonContent is Map<String, dynamic> &&
          jsonContent['configurations'] is List) {
        launchConfig = jsonContent;
      }
    } catch (_) {}
  }

  launchConfig['configurations'] = (launchConfig['configurations'] as List)
      .where((c) => c['type'] != 'dart')
      .toList();

  List<String> flavors = [];
  switch (config) {
    case DefaultConfig():
      break;
    case FlavoredConfig():
      flavors.addAll(config.flavors.map((e) => e.flavor));
  }

  if (flavors.isEmpty) {
    launchConfig['configurations'].addAll([
      {
        'name': 'Run main.dart',
        'request': 'launch',
        'type': 'dart',
        'program': 'lib/main.dart',
        'args': [],
      },
      {
        'name': 'Debug main.dart',
        'request': 'launch',
        'type': 'dart',
        'program': 'lib/main.dart',
        'args': [],
        'noDebug': false,
      },
    ]);
  } else {
    for (final flavor in flavors) {
      launchConfig['configurations'].addAll([
        {
          'name': 'Run $flavor',
          'request': 'launch',
          'type': 'dart',
          'program': 'lib/main.dart',
          'args': ['--flavor', flavor],
        },
        {
          'name': 'Debug $flavor',
          'request': 'launch',
          'type': 'dart',
          'program': 'lib/main.dart',
          'args': ['--flavor', flavor],
          'noDebug': false,
        },
      ]);
    }
  }

  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(launchConfig));
  log.fine('VSCode run/debug configuration generated successfully');
}
