import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:xml/xml.dart';

void generateAndroidStudioRunConfig(KConfig config) {
  final file = File('.idea/workspace.xml');

  if (!file.existsSync()) {
    log.warning('Looks like project is not opened in Android Studio IDE');
    return;
  }

  final content = file.readAsStringSync();

  if (content.hasValue) {
    List<String> flavors = [];

    switch (config) {
      case DefaultConfig():
        break;
      case FlavoredConfig():
        flavors.addAll(config.flavors.map((e) => e.flavor));
    }

    final updatedContent = _getContent(content, flavors);
    file.writeAsStringSync(updatedContent);

    log.fine('android studio run configuration generated successfully');
  }
}

String _getContent(String content, List<String> flavors) {
  final document = XmlDocument.parse(content);

  final project = document.rootElement;

  XmlElement? runManager = project
      .findElements('component')
      .where((e) => e.getAttribute('name') == 'RunManager')
      .firstOrNull;

  if (runManager == null) {
    runManager = XmlElement(XmlName('component'), [
      XmlAttribute(XmlName('name'), 'RunManager'),
    ]);
    project.children.add(runManager);
  }

  runManager.children.removeWhere((node) {
    return node is XmlElement &&
        node.name.local == 'configuration' &&
        node.getAttribute('type') == 'FlutterRunConfigurationType';
  });

  if (flavors.isEmpty) {
    runManager.children.add(
      XmlElement(
        XmlName('configuration'),
        [
          XmlAttribute(XmlName('name'), 'main.dart'),
          XmlAttribute(XmlName('type'), 'FlutterRunConfigurationType'),
          XmlAttribute(XmlName('factoryName'), 'Flutter'),
        ],
        [
          XmlElement(XmlName('option'), [
            XmlAttribute(XmlName('name'), 'filePath'),
            XmlAttribute(XmlName('value'), r'$PROJECT_DIR$/lib/main.dart'),
          ]),
          XmlElement(XmlName('method'), [XmlAttribute(XmlName('v'), '2')]),
        ],
      ),
    );
  } else {
    for (final flavor in flavors) {
      runManager.children.add(
        XmlElement(
          XmlName('configuration'),
          [
            XmlAttribute(XmlName('name'), flavor),
            XmlAttribute(XmlName('type'), 'FlutterRunConfigurationType'),
            XmlAttribute(XmlName('factoryName'), 'Flutter'),
          ],
          [
            XmlElement(XmlName('option'), [
              XmlAttribute(XmlName('name'), 'additionalArgs'),
              XmlAttribute(XmlName('value'), '--flavor $flavor'),
            ]),
            XmlElement(XmlName('option'), [
              XmlAttribute(XmlName('name'), 'filePath'),
              XmlAttribute(XmlName('value'), r'$PROJECT_DIR$/lib/main.dart'),
            ]),
            XmlElement(XmlName('method'), [XmlAttribute(XmlName('v'), '2')]),
          ],
        ),
      );
    }
  }

  return document.toXmlString(pretty: true, indent: '  ');
}
