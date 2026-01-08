import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:xml/xml.dart';

/// Update the Android `AndroidManifest.xml` application label and intent
/// filters for deep links/app links based on `config`.
///
/// This will set the application label to `@string/app_name` and add/remove
/// intent-filters for activities according to configured schemes and app links.
void updateAndroidManifest(KConfig config) {
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  final bool hasScheme = config.hasAndroidScheme;
  final bool hasAppLink = config.hasAndroidAppLink;

  final doc = XmlDocument.parse(manifestFile.readAsStringSync());
  const androidNs = 'http://schemas.android.com/apk/res/android';

  final application = doc.findAllElements('application').first;

  application.setAttribute('label', '@string/app_name', namespace: androidNs);

  for (final activity in application.findElements('activity')) {
    activity.children.removeWhere(
      (node) => node is XmlElement && _isDeepLinkIntentFilter(node),
    );

    if (hasAppLink) {
      activity.children.add(XmlText('\n        '));
      activity.children.add(_httpsIntentFilter());
    }

    if (hasScheme) {
      activity.children.add(XmlText('\n        '));
      activity.children.add(_schemeIntentFilter());
    }

    activity.children.add(XmlText('\n    '));
  }

  manifestFile.writeAsStringSync(doc.toXmlString(pretty: true, indent: '    '));
}

const androidNs = 'http://schemas.android.com/apk/res/android';

bool _isDeepLinkIntentFilter(XmlElement e) {
  if (e.name.local != 'intent-filter') return false;

  final hasView = e
      .findElements('action')
      .any(
        (a) =>
            a.getAttribute('name', namespace: androidNs) ==
            'android.intent.action.VIEW',
      );

  final hasBrowsable = e
      .findElements('category')
      .any(
        (c) =>
            c.getAttribute('name', namespace: androidNs) ==
            'android.intent.category.BROWSABLE',
      );

  if (!hasView || !hasBrowsable) return false;

  for (final d in e.findElements('data')) {
    final scheme = d.getAttribute('scheme', namespace: androidNs);

    if (scheme == 'https') return true;

    if (scheme != null && scheme != 'https') return true;
  }

  return false;
}

XmlElement _httpsIntentFilter() {
  return XmlElement(
    XmlName('intent-filter'),
    [XmlAttribute(XmlName('autoVerify', 'android'), 'true')],
    [
      _actionView(),
      _categoryDefault(),
      _categoryBrowsable(),
      _data('scheme', 'https'),
      _data('host', '@string/app_link'),
    ],
  );
}

XmlElement _schemeIntentFilter() {
  return XmlElement(XmlName('intent-filter'), [], [
    _actionView(),
    _categoryDefault(),
    _categoryBrowsable(),
    _data('scheme', '@string/scheme'),
  ]);
}

XmlElement _actionView() => XmlElement(XmlName('action'), [
  XmlAttribute(XmlName('name', 'android'), 'android.intent.action.VIEW'),
]);

XmlElement _categoryDefault() => XmlElement(XmlName('category'), [
  XmlAttribute(XmlName('name', 'android'), 'android.intent.category.DEFAULT'),
]);

XmlElement _categoryBrowsable() => XmlElement(XmlName('category'), [
  XmlAttribute(XmlName('name', 'android'), 'android.intent.category.BROWSABLE'),
]);

XmlElement _data(String key, String value) =>
    XmlElement(XmlName('data'), [XmlAttribute(XmlName(key, 'android'), value)]);

/// Reformat manifest attributes to a consistent multi-line style.
void autoFormatManifest() {
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  final content = manifestFile.readAsStringSync();
  final formatted = _formatManifestAttributes(content);
  manifestFile.writeAsStringSync(formatted);
}

String _formatManifestAttributes(String source) {
  final doc = XmlDocument.parse(source);
  var result = source;

  for (final element in doc.descendants.whereType<XmlElement>()) {
    if (element.attributes.length <= 1) continue;

    final tagName = element.name.local;

    final regex = RegExp(
      r'(^[ \t]*)<'
      '$tagName'
      r'(\s+[^>]*?)?(\s*/?)>',
      multiLine: true,
    );

    final matches = regex.allMatches(result).toList();

    for (final match in matches) {
      final originalTag = match.group(0)!;

      if (!_matchesElementAttributes(originalTag, element)) {
        continue;
      }

      final indent = match.group(1)!;
      final selfClosing = match.group(3)!.contains('/');

      final formatted = _formatOpeningTag(
        element: element,
        indent: indent,
        selfClosing: selfClosing,
      );

      result = result.replaceFirst(originalTag, formatted);
      break;
    }
  }

  return result;
}

bool _matchesElementAttributes(String tag, XmlElement element) {
  for (final attr in element.attributes) {
    final prefix = attr.name.prefix != null ? '${attr.name.prefix}:' : '';
    final pattern = RegExp(
      '$prefix${attr.name.local}="${RegExp.escape(attr.value)}"',
    );

    if (!pattern.hasMatch(tag)) return false;
  }
  return true;
}

String _formatOpeningTag({
  required XmlElement element,
  required String indent,
  required bool selfClosing,
}) {
  final buffer = StringBuffer();

  buffer.write('$indent<${element.name.local}\n');

  for (int i = 0; i < element.attributes.length; i++) {
    final attr = element.attributes[i];
    final prefix = attr.name.prefix != null ? '${attr.name.prefix}:' : '';
    final isLast = i == element.attributes.length - 1;

    buffer.write('$indent    $prefix${attr.name.local}="${attr.value}"');

    if (isLast) {
      buffer.write(selfClosing ? ' />' : '>');
    } else {
      buffer.write('\n');
    }
  }

  return buffer.toString();
}
