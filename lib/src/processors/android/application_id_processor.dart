import 'dart:io';

/// Remove the `applicationId` entry from the `defaultConfig` block in
/// `android/app/build.gradle.kts` or `android/app/build.gradle` to avoid
/// conflicts when per-flavor ids are supplied.
///
/// This operates on both Kotlin DSL and Groovy files. Will no-op if the file or
/// block cannot be found.
void removeApplicationId() {
  const ktsPath = 'android/app/build.gradle.kts';
  const groovyPath = 'android/app/build.gradle';
  final ktsFile = File(ktsPath);
  final groovyFile = File(groovyPath);

  if (ktsFile.existsSync()) {
    final src = ktsFile.readAsStringSync();
    final updated = _removeApplicationIdFromDefaultConfig(src);
    ktsFile.writeAsStringSync(updated);
    return;
  }

  if (groovyFile.existsSync()) {
    final src = groovyFile.readAsStringSync();
    final updated = _removeApplicationIdFromDefaultConfigGroovy(src);
    groovyFile.writeAsStringSync(updated);
    return;
  }
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

/// Finds the first block with the given [name] in the [src] string (Groovy).
///
/// Similar to [_findNamedBlock] but handles both single-quoted and
/// double-quoted strings used in Groovy files.
_Block? _findNamedBlockGroovy(String src, String name) {
  int depth = 0;
  bool inSingleQuoteString = false;
  bool inDoubleQuoteString = false;
  bool inLineComment = false;
  bool inBlockComment = false;

  for (int i = 0; i < src.length; i++) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';
    final prev = i > 0 ? src[i - 1] : '';

    if (!inSingleQuoteString && !inDoubleQuoteString) {
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

    // Handle single-quoted strings
    if (c == '\'' && prev != r'\' && !inDoubleQuoteString) {
      inSingleQuoteString = !inSingleQuoteString;
    }
    // Handle double-quoted strings
    if (c == '"' && prev != r'\' && !inSingleQuoteString) {
      inDoubleQuoteString = !inDoubleQuoteString;
    }
    if (inSingleQuoteString || inDoubleQuoteString) continue;

    if (depth == 0 &&
        src.substring(i).startsWith(name) &&
        RegExp('$name\\s*\\{').hasMatch(src.substring(i))) {
      final start = i;
      i = src.indexOf('{', i);
      depth = 1;
      final bodyStart = i + 1;

      // Reset string tracking for inner loop
      bool innerInSingleQuote = false;
      bool innerInDoubleQuote = false;

      for (i = bodyStart; i < src.length; i++) {
        final ch = src[i];
        final prevCh = i > 0 ? src[i - 1] : '';

        // Handle single-quoted strings
        if (ch == '\'' && prevCh != r'\' && !innerInDoubleQuote) {
          innerInSingleQuote = !innerInSingleQuote;
        }
        // Handle double-quoted strings
        if (ch == '"' && prevCh != r'\' && !innerInSingleQuote) {
          innerInDoubleQuote = !innerInDoubleQuote;
        }

        if (!innerInSingleQuote && !innerInDoubleQuote) {
          if (ch == '{') depth++;
          if (ch == '}') depth--;
        }

        if (depth == 0) {
          return _Block(start, i + 1, src.substring(bodyStart, i));
        }
      }
    }
  }
  return null;
}

/// Removes the `applicationId` entry from the `defaultConfig` block in the
/// given Groovy [src] string.
///
/// This function looks for the `android` block, then the `defaultConfig` block
/// within it. If found, it removes the `applicationId` line and returns the
/// updated source string. If the blocks are not found or no `applicationId`
/// line exists, the original [src] string is returned.
String _removeApplicationIdFromDefaultConfigGroovy(String src) {
  final androidBlock = _findNamedBlockGroovy(src, 'android');
  if (androidBlock == null) return src;

  final defaultConfigBlock = _findNamedBlockGroovy(
    androidBlock.body,
    'defaultConfig',
  );
  if (defaultConfigBlock == null) return src;

  final updatedDefaultConfig = defaultConfigBlock.body
      .split('\n')
      .where((line) => !RegExp(r'^\s*applicationId\s').hasMatch(line))
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
