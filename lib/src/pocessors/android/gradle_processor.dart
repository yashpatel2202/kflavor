import 'dart:io';

void updateApplyGradle() {
  final file = File('android/app/build.gradle.kts');
  final src = file.readAsStringSync();

  final updated = _upsertKFlavor(src);

  file.writeAsStringSync(updated);
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
