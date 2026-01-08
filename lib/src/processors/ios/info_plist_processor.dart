import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';

void updateInfoPlist(KConfig config) {
  final plistFile = File('ios/Runner/Info.plist');

  String content = plistFile.readAsStringSync();

  content = _setPlistKey(content, 'CFBundleDisplayName', '\$(APP_NAME)');

  content = _setPlistKey(content, 'CFBundleName', '\$(APP_NAME)');

  content = _setPlistKey(
    content,
    'CFBundleIdentifier',
    '\$(PRODUCT_BUNDLE_IDENTIFIER)',
  );

  content = _setCFBundleURLScheme(
    content,
    config.hasIOSScheme ? '\$(APP_URL_SCHEME)' : '',
  );

  plistFile.writeAsStringSync(content);
}

String _setPlistKey(String plist, String key, String value) {
  final keyRegex = RegExp(
    '<key>$key</key>\\s*<string>.*?</string>',
    dotAll: true,
  );

  final replacement = '''
<key>$key</key>\n\t<string>$value</string>''';

  if (keyRegex.hasMatch(plist)) {
    return plist.replaceFirst(keyRegex, replacement);
  }

  return plist.replaceFirst('</dict>', '$replacement\n</dict>');
}

String _setCFBundleURLScheme(String plist, String scheme) {
  if (!scheme.hasValue) {
    final urlTypesRegex = RegExp(
      r'<key>CFBundleURLTypes</key>\s*<array>.*?</array>\s*',
      dotAll: true,
    );
    return plist.replaceFirst(urlTypesRegex, '');
  }

  final urlSchemeRegex = RegExp(
    r'(<key>CFBundleURLSchemes</key>\s*<array>\s*)<string>.*?</string>(\s*</array>)',
    dotAll: true,
  );
  bool found = false;
  plist = plist.replaceAllMapped(urlSchemeRegex, (match) {
    found = true;
    return '${match.group(1)}<string>$scheme</string>${match.group(2)}';
  });

  if (found) {
    return plist;
  }

  final insertBlock =
      '''
\t<key>CFBundleURLTypes</key>
\t<array>
\t  <dict>
\t    <key>CFBundleTypeRole</key>
\t    <string>Editor</string>
\t    <key>CFBundleURLSchemes</key>
\t    <array>
\t      <string>$scheme</string>
\t    </array>
\t  </dict>
\t</array>''';
  return plist.replaceFirst('</dict>', '$insertBlock\n</dict>');
}
