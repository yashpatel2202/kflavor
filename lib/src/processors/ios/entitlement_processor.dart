import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:xml/xml.dart';

void updateEntitlement(KConfig config) {
  final entitlementFile = File('ios/Runner/Runner.entitlements');

  if (!entitlementFile.existsSync()) return;

  String content = entitlementFile.readAsStringSync();

  content = _setAppLink(
    content,
    config.hasIOSAppLink ? '\$(APP_ASSOCIATED_DOMAIN)' : '',
  );

  try {
    final document = XmlDocument.parse(content);
    content = document.toXmlString(pretty: true, indent: '\t');
  } catch (_) {}

  entitlementFile.writeAsStringSync(content);
}

String _setAppLink(String content, String appLink) {
  final keyRegex = RegExp(
    r'<key>com\.apple\.developer\.associated-domains</key>\s*<array>.*?</array>\s*',
    dotAll: true,
  );

  if (!appLink.hasValue) {
    return content.replaceFirst(keyRegex, '');
  }

  final block =
      '''
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:$appLink</string>
    <string>webcredentials:$appLink</string>
</array>''';

  if (keyRegex.hasMatch(content)) {
    return content.replaceFirst(keyRegex, block);
  } else {
    return content.contains('</dict>')
        ? content.replaceFirst('</dict>', '$block\n</dict>')
        : content.contains('<dict/>')
        ? content.replaceFirst('<dict/>', '<dict>\n$block\n</dict>')
        : content;
  }
}
