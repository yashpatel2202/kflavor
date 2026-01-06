import 'dart:io';

void updateInfoPlist() {
  final plistFile = File('ios/Runner/Info.plist');

  var content = plistFile.readAsStringSync();

  content = _setPlistKey(content, 'CFBundleDisplayName', '\$(APP_NAME)');

  content = _setPlistKey(content, 'CFBundleName', '\$(APP_NAME)');

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
