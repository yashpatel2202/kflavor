import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/ios/entitlement_processor.dart';
import 'package:kflavor/src/processors/ios/info_plist_processor.dart';
import 'package:kflavor/src/processors/ios/podfile_processor.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

/// Create or update the Xcode project using `xcodegen` based on `config`.
///
/// This function generates `ios/project.yml`, runs `xcodegen generate`, and
/// updates Podfile, entitlements and Info.plist as needed. This is a macOS-
/// only operation and will no-op on other platforms.
Future<void> createXCodeProject(KConfig config) async {
  await _verifyXCodeGen();

  final entitlement = await _getEntitlement();
  final hasEntitlement = entitlement.hasValue || config.hasIOSAppLink;

  final content = _getContent(config, hasEntitlement);

  const path = 'ios/project.yml';
  final file = File(path);
  file.writeAsStringSync(content);

  await runInTerminal('cd ios && xcodegen generate');

  if (entitlement.hasValue) _saveEntitlement(entitlement ?? '');

  file.deleteSync();

  updatePodFile(config);

  updateEntitlement(config);

  updateInfoPlist(config);
}

Future<String?> _getEntitlement() async {
  const path = 'ios/Runner/Runner.entitlements';
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsStringSync();
}

void _saveEntitlement(String content) {
  const path = 'ios/Runner/Runner.entitlements';
  final file = File(path);

  file.writeAsStringSync(content);
}

Future<void> _verifyXCodeGen() async {
  final exist = await commandExists('xcodegen');
  if (exist) return;

  await runInTerminal('brew install xcodegen');
}

String _debugConfigLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '  Debug${flavor.hasValue ? '-$flavor' : ''}: debug';
}

String _profileConfigLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '  Profile${flavor.hasValue ? '-$flavor' : ''}: release';
}

String _releaseConfigLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '  Release${flavor.hasValue ? '-$flavor' : ''}: release';
}

String _getConfigLines(KConfig config) {
  return '''
${config.mapper(map: _debugConfigLine, join: '\n')}

${config.mapper(map: _profileConfigLine, join: '\n')}

${config.mapper(map: _releaseConfigLine, join: '\n')}''';
}

String _debugConfigFileLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '  Debug${flavor.hasValue ? '-$flavor' : ''}: Flutter/Debug.xcconfig';
}

String _profileConfigFileLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '  Profile${flavor.hasValue ? '-$flavor' : ''}: Flutter/Release.xcconfig';
}

String _releaseConfigFileLine(FlavorConfig config) {
  final flavor = config.flavor;

  return '  Release${flavor.hasValue ? '-$flavor' : ''}: Flutter/Release.xcconfig';
}

String _getConfigFileLines(KConfig config) {
  return '''
${config.mapper(map: _debugConfigFileLine, join: '\n')}

${config.mapper(map: _profileConfigFileLine, join: '\n')}

${config.mapper(map: _releaseConfigFileLine, join: '\n')}''';
}

String _getDeepLinkLines(String scheme) {
  return scheme.hasValue ? '''\n          APP_URL_SCHEME: $scheme''' : '';
}

String _getAppLinkLines(String appLink) {
  return appLink.hasValue
      ? '''\n          APP_ASSOCIATED_DOMAIN: $appLink'''
      : '';
}

String _getDevelopmentTeam(String devTeam) {
  return devTeam.hasValue
      ? '''\n          DEVELOPMENT_TEAM: $devTeam
          CODE_SIGN_STYLE: Automatic'''
      : '';
}

String _targetLine(
  String type,
  String bundleId,
  String appName,
  String flavor,
  String scheme,
  String appLink,
  String devTeam,
) {
  return '''        $type${flavor.hasValue ? '-$flavor' : ''}:
          PRODUCT_BUNDLE_IDENTIFIER: $bundleId
          APP_NAME: $appName
          ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon${flavor.hasValue ? '-$flavor' : ''}${_getDeepLinkLines(scheme)}${_getAppLinkLines(appLink)}${_getDevelopmentTeam(devTeam)}''';
}

String _getFlavoredTargetLines(FlavorConfig config) {
  final flavor = config.flavor;
  final bundle = config.config.ios.bundleId;
  final name = config.config.ios.name;
  final scheme = config.config.ios.scheme;
  final appLink = config.config.ios.appLink;
  final devTeam = config.config.ios.developmentTeam;

  return '''
${_targetLine('Debug', bundle, name, flavor, scheme, appLink, devTeam)}

${_targetLine('Profile', bundle, name, flavor, scheme, appLink, devTeam)}

${_targetLine('Release', bundle, name, flavor, scheme, appLink, devTeam)}
''';
}

String _getTagetLines(KConfig config) {
  return config.mapper(map: _getFlavoredTargetLines, join: '\n');
}

String _getFlavoredSchemeLines(FlavorConfig config) {
  final flavor = config.flavor;

  return '''  ${flavor.hasValue ? flavor : 'Runner'}:
    build:
      targets:
        Runner: all
    run:
      config: Debug${flavor.hasValue ? '-$flavor' : ''}
    profile:
      config: Profile${flavor.hasValue ? '-$flavor' : ''}
    archive:
      config: Release${flavor.hasValue ? '-$flavor' : ''}''';
}

String _getSchemeLines(KConfig config) {
  return config.mapper(map: _getFlavoredSchemeLines, join: '\n\n');
}

String _getEntitlementString() {
  return '''    entitlements:
      path: Runner/Runner.entitlements''';
}

String _getContent(KConfig config, bool hasEntitlement) {
  return '''name: Runner

options:
  createIntermediateGroups: true
  groupSortPosition: top
  generateEmptyDirectories: true

configs:
${_getConfigLines(config)}

configFiles:
${_getConfigFileLines(config)}

targets:
  Runner:
    type: application
    platform: iOS
${hasEntitlement ? _getEntitlementString() : ''}
    sources:
      - path: Runner
      - path: Runner/GeneratedPluginRegistrant.m
      - path: Runner/GeneratedPluginRegistrant.h
      - path: Flutter/AppFrameworkInfo.plist
      - path: Flutter/Debug.xcconfig
        buildPhase: none
      - path: Flutter/Release.xcconfig
        buildPhase: none
      - path: Flutter/Generated.xcconfig
        buildPhase: none
    settings:
      base:
        INFOPLIST_FILE: Runner/Info.plist
        CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES: 'YES'
        ENABLE_BITCODE: 'NO'
        SWIFT_OBJC_BRIDGING_HEADER: Runner/Runner-Bridging-Header.h
        FRAMEWORK_SEARCH_PATHS: \$(inherited) \$(PROJECT_DIR)/Flutter
        LIBRARY_SEARCH_PATHS: \$(inherited) \$(PROJECT_DIR)/Flutter

      configs:
${_getTagetLines(config)}
    scheme:
      testTargets: []
    preBuildScripts:
      - name: "Run Script"
        script: |
          /bin/sh "\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" build
      - name: Firebase config switch
        script: |
          set -e

          DEST="Runner/GoogleService-Info.plist"
          CONFIG_DIR="Configs"

          FLAVOR=\$(echo "\$CONFIGURATION" | tr '[:upper:]' '[:lower:]' | sed 's/.*-//')

          SRC=""

          if [ -f "\$CONFIG_DIR/\$FLAVOR/GoogleService-Info.plist" ]; then
            SRC="\$CONFIG_DIR/\$FLAVOR/GoogleService-Info.plist"
          elif [ -f "\$CONFIG_DIR/GoogleService-Info.plist" ]; then
            SRC="\$CONFIG_DIR/GoogleService-Info.plist"
          fi

          if [ -n "\$SRC" ]; then
            cp "\$SRC" "\$DEST"
          else
            echo "   Looked for:"
            echo "   - \$CONFIG_DIR/\$FLAVOR/GoogleService-Info.plist"
            echo "   - \$CONFIG_DIR/GoogleService-Info.plist"
            exit 1
          fi
    postBuildScripts:
      - name: "Thin Binary"
        script: |
          /bin/sh "\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" embed_and_thin

schemes:
${_getSchemeLines(config)}''';
}
