import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';

void saveGradleKts(KConfig config) {
  const path = 'android/app/kflavor.gradle.kts';
  final file = File(path);

  file.parent.createSync(recursive: true);

  file.writeAsStringSync(_getFlavorGradleKts(config));
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
