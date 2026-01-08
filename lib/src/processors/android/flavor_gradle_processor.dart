import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';

void saveGradleKts(KConfig config) {
  const buildKtsPath = 'android/app/build.gradle.kts';
  const buildGroovyPath = 'android/app/build.gradle';
  const kflavorKtsPath = 'android/app/kflavor.gradle.kts';
  const kflavorGroovyPath = 'android/app/kflavor.gradle';

  final buildKtsFile = File(buildKtsPath);
  final buildGroovyFile = File(buildGroovyPath);

  if (buildKtsFile.existsSync()) {
    final kFlavorKtsFile = File(kflavorKtsPath);
    kFlavorKtsFile.parent.createSync(recursive: true);
    kFlavorKtsFile.writeAsStringSync(_getFlavorGradleKts(config));
    return;
  }

  if (buildGroovyFile.existsSync()) {
    final kflavorGroovyFile = File(kflavorGroovyPath);
    kflavorGroovyFile.parent.createSync(recursive: true);
    kflavorGroovyFile.writeAsStringSync(_getFlavorGradleGroovy(config));
    return;
  }

  throw Exception(
    'No build.gradle(.kts) file found: cannot determine format for kflavor gradle file.',
  );
}

String _getFlavorGradleKts(KConfig config) {
  switch (config) {
    case DefaultConfig():
      return '''
import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    defaultConfig {
${_getAndroidConfig(config.config.config.android, false)}
    }
}
''';
    case FlavoredConfig():
      return '''
import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
${config.flavors.map((flavor) {
        return '''
        create("${flavor.flavor}") {
            dimension = "flavor-type"
${_getAndroidConfig(flavor.config.android, true)}
        }''';
      }).join('\n')}
    }
}
''';
  }
}

String _getFlavorGradleGroovy(KConfig config) {
  switch (config) {
    case DefaultConfig():
      return '''
ext {
    android = project.extensions.findByName('android')
}

android.defaultConfig {
${_getAndroidConfigGroovy(config.config.config.android, false)}
}
''';
    case FlavoredConfig():
      return '''
ext {
    android = project.extensions.findByName('android')
}

android.flavorDimensions 'flavor-type'
android.productFlavors {
${config.flavors.map((flavor) {
        return '''
    ${flavor.flavor} {
        dimension 'flavor-type'
${_getAndroidConfigGroovy(flavor.config.android, true)}
    }''';
      }).join('\n')}
}
''';
  }
}

String _getAndroidConfig(Config config, bool isInner) {
  final scheme = _getScheme(config.scheme);
  final appLink = _getAppLink(config.appLink);

  return '''
        ${isInner ? '    ' : ''}applicationId = "${config.bundleId}"
        ${isInner ? '    ' : ''}resValue(type = "string", name = "app_name", value = "${config.name}")
${scheme.hasValue ? '        ${isInner ? '    ' : ''}$scheme' : ''}
${appLink.hasValue ? '        ${isInner ? '    ' : ''}$appLink' : ''}'''
      .newLineSterilize;
}

String _getAndroidConfigGroovy(Config config, bool isInner) {
  final scheme = _getSchemeGroovy(config.scheme);
  final appLink = _getAppLinkGroovy(config.appLink);
  final indent = isInner ? '    ' : '';
  final resValue = "resValue 'string', 'app_name', '${config.name}'";
  final applicationId = "applicationId '${config.bundleId}'";

  return '''
        $indent$applicationId
        $indent$resValue
${scheme.isNotEmpty ? '        $indent$scheme' : ''}
${appLink.isNotEmpty ? '        $indent$appLink' : ''}'''
      .newLineSterilize;
}

String _getScheme(String scheme) {
  return scheme.hasValue
      ? "resValue(type = \"string\", name = \"scheme\", value = \"$scheme\")"
      : '';
}

String _getAppLink(String appLink) {
  return appLink.hasValue
      ? "resValue(type = \"string\", name = \"app_link\", value = \"$appLink\")"
      : '';
}

String _getSchemeGroovy(String scheme) {
  return scheme.hasValue ? "resValue 'string', 'scheme', '$scheme'" : '';
}

String _getAppLinkGroovy(String appLink) {
  return appLink.hasValue ? "resValue 'string', 'app_link', '$appLink'" : '';
}
