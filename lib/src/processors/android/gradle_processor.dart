import 'dart:io';

/// Update the project's build file to include an `apply { from('kflavor...') }`
/// block. Supports Kotlin DSL (`build.gradle.kts`) and Groovy (`build.gradle`).
///
/// Throws if no recognized build file is found.
void updateApplyGradle() {
  const ktsPath = 'android/app/build.gradle.kts';
  const groovyPath = 'android/app/build.gradle';
  final ktsFile = File(ktsPath);
  final groovyFile = File(groovyPath);

  if (ktsFile.existsSync()) {
    final src = ktsFile.readAsStringSync();
    final updated = _upsertKFlavor(src);
    ktsFile.writeAsStringSync(updated);
    return;
  }

  if (groovyFile.existsSync()) {
    final src = groovyFile.readAsStringSync();
    final updated = _upsertKFlavorGroovy(src);
    groovyFile.writeAsStringSync(updated);
    return;
  }

  throw Exception(
    'No build.gradle(.kts) file found: cannot update apply block.',
  );
}

class _ApplyBlockGroovy {
  final int start;
  final int end;
  final String body;

  _ApplyBlockGroovy(this.start, this.end, this.body);
}

class _ApplyBlock {
  final int start;
  final int end;
  final String body;

  _ApplyBlock(this.start, this.end, this.body);
}

List<_ApplyBlock> _findApplyBlocks(String src) {
  final blocks = <_ApplyBlock>[];
  int depth = 0;
  bool inString = false;
  bool inLineComment = false;
  bool inBlockComment = false;

  for (int i = 0; i < src.length; i++) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';

    if (!inString) {
      if (!inBlockComment && c == '/' && next == '/') {
        inLineComment = true;
      } else if (!inLineComment && c == '/' && next == '*') {
        inBlockComment = true;
      }
    }

    if (inLineComment && c == '\n') inLineComment = false;
    if (inBlockComment && c == '*' && next == '/') {
      inBlockComment = false;
      i++;
      continue;
    }

    if (inLineComment || inBlockComment) continue;

    if (c == '"' && src[i - 1] != '\\') {
      inString = !inString;
    }
    if (inString) continue;

    if (depth == 0 &&
        src.substring(i).startsWith('apply') &&
        RegExp(r'apply\s*\{').hasMatch(src.substring(i))) {
      final start = i;
      i = src.indexOf('{', i);
      depth = 1;

      final bodyStart = i + 1;
      for (i = bodyStart; i < src.length; i++) {
        final ch = src[i];
        if (ch == '{') depth++;
        if (ch == '}') depth--;

        if (depth == 0) {
          blocks.add(_ApplyBlock(start, i + 1, src.substring(bodyStart, i)));
          break;
        }
      }
    }
  }
  return blocks;
}

String _upsertKFlavor(String src) {
  const flavor = 'from("kflavor.gradle.kts")';

  final blocks = _findApplyBlocks(src);

  if (blocks.any((b) => b.body.contains(flavor))) {
    return src;
  }

  if (blocks.isNotEmpty) {
    final block = blocks.first;
    final indent =
        RegExp(r'\n(\s*)\S').firstMatch(block.body)?.group(1) ?? '    ';

    final newBlock =
        '''
apply {
${block.body.trimRight()}
$indent$flavor
}
''';

    return src.replaceRange(block.start, block.end, newBlock);
  }

  return '''${src.trimRight()}

apply {
    $flavor
}
''';
}

List<_ApplyBlockGroovy> _findApplyBlocksGroovy(String src) {
  final blocks = <_ApplyBlockGroovy>[];
  int depth = 0;
  bool inString = false;
  bool inLineComment = false;
  bool inBlockComment = false;

  for (int i = 0; i < src.length; i++) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';

    if (!inString) {
      if (!inBlockComment && c == '/' && next == '/') {
        inLineComment = true;
      } else if (!inLineComment && c == '/' && next == '*') {
        inBlockComment = true;
      }
    }

    if (inLineComment && c == '\n') inLineComment = false;
    if (inBlockComment && c == '*' && next == '/') {
      inBlockComment = false;
      i++;
      continue;
    }

    if (inLineComment || inBlockComment) continue;

    if (c == '\'' && src[i - 1] != '\\') {
      inString = !inString;
    }
    if (inString) continue;

    if (depth == 0 &&
        src.substring(i).startsWith('apply') &&
        RegExp(r'apply\s*\{').hasMatch(src.substring(i))) {
      final start = i;
      i = src.indexOf('{', i);
      depth = 1;

      final bodyStart = i + 1;
      for (i = bodyStart; i < src.length; i++) {
        final ch = src[i];
        if (ch == '{') depth++;
        if (ch == '}') depth--;

        if (depth == 0) {
          blocks.add(
            _ApplyBlockGroovy(start, i + 1, src.substring(bodyStart, i)),
          );
          break;
        }
      }
    }
  }
  return blocks;
}

String _upsertKFlavorGroovy(String src) {
  const flavor = "from('kflavor.gradle')";

  final blocks = _findApplyBlocksGroovy(src);

  if (blocks.any((b) => b.body.contains(flavor))) {
    return src;
  }

  if (blocks.isNotEmpty) {
    final block = blocks.first;
    final indent =
        RegExp(r'\n(\s*)\S').firstMatch(block.body)?.group(1) ?? '    ';

    final newBlock =
        '''
apply {
${block.body.trimRight()}
$indent$flavor
}
''';

    return src.replaceRange(block.start, block.end, newBlock);
  }

  return '''${src.trimRight()}

apply {
    $flavor
}
''';
}
