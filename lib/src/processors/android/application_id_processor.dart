import 'dart:io';

/// Remove the `applicationId` entry from the `defaultConfig` block in
/// `android/app/build.gradle.kts` to avoid conflicts when per-flavor ids are
/// supplied.
///
/// This only operates on the Kotlin DSL file and will no-op if the file or
/// block cannot be found.
void removeApplicationId() {
  final file = File('android/app/build.gradle.kts');
  final src = file.readAsStringSync();

  final updated = _removeApplicationIdFromDefaultConfig(src);

  file.writeAsStringSync(updated);
}

class _Block {
  final int start;
  final int end;
  final String body;

  _Block(this.start, this.end, this.body);
}

/// Finds the first block with the given [name] in the [src] string.
///
/// A block is considered to start with the given [name] followed by an opening
/// brace `{`, and ends with the matching closing brace `}`. This function
/// handles nested blocks and ignores blocks that are inside string literals or
/// comments.
///
/// Returns the found block as a [_Block] instance, or null if no block is
/// found.
_Block? _findNamedBlock(String src, String name) {
  int depth = 0;
  bool inString = false;
  bool inLineComment = false;
  bool inBlockComment = false;

  for (int i = 0; i < src.length; i++) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';

    if (!inString) {
      if (!inBlockComment && c == '/' && next == '/') inLineComment = true;
      if (!inLineComment && c == '/' && next == '*') inBlockComment = true;
    }

    if (inLineComment && c == '\n') inLineComment = false;
    if (inBlockComment && c == '*' && next == '/') {
      inBlockComment = false;
      i++;
      continue;
    }
    if (inLineComment || inBlockComment) continue;

    if (c == '"' && src[i - 1] != r'\') inString = !inString;
    if (inString) continue;

    if (depth == 0 &&
        src.substring(i).startsWith(name) &&
        RegExp('$name\\s*\\{').hasMatch(src.substring(i))) {
      final start = i;
      i = src.indexOf('{', i);
      depth = 1;
      final bodyStart = i + 1;

      for (i = bodyStart; i < src.length; i++) {
        if (src[i] == '{') depth++;
        if (src[i] == '}') depth--;
        if (depth == 0) {
          return _Block(start, i + 1, src.substring(bodyStart, i));
        }
      }
    }
  }
  return null;
}

/// Removes the `applicationId` entry from the `defaultConfig` block in the
/// given [src] string.
///
/// This function looks for the `android` block, then the `defaultConfig` block
/// within it. If found, it removes the `applicationId` line and returns the
/// updated source string. If the blocks are not found or no `applicationId`
/// line exists, the original [src] string is returned.
String _removeApplicationIdFromDefaultConfig(String src) {
  final androidBlock = _findNamedBlock(src, 'android');
  if (androidBlock == null) return src;

  final defaultConfigBlock = _findNamedBlock(
    androidBlock.body,
    'defaultConfig',
  );
  if (defaultConfigBlock == null) return src;

  final updatedDefaultConfig = defaultConfigBlock.body
      .split('\n')
      .where((line) => !RegExp(r'^\s*applicationId\s*=').hasMatch(line))
      .join('\n');

  if (updatedDefaultConfig == defaultConfigBlock.body) {
    return src;
  }

  final updatedAndroidBody = androidBlock.body.replaceRange(
    defaultConfigBlock.start,
    defaultConfigBlock.end,
    '''
defaultConfig {$updatedDefaultConfig}''',
  );

  return src.replaceRange(androidBlock.start, androidBlock.end, '''
android {$updatedAndroidBody}''');
}
