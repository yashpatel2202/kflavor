import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

void main() {
  group('Terminal utils', () {
    test(
      'commandExists returns true for bash (or sh) and false for nonsense',
      () async {
        // Check that `dart` is available on the test machine (cross-platform).
        final dartExists = await commandExists('dart');
        expect(dartExists, isTrue, reason: 'Expected `dart` to be on PATH');

        final random = await commandExists('this-command-should-not-exist-xyz');
        expect(random, isFalse);
      },
    );

    test(
      'runInTerminal succeeds for echo and increments failed on false',
      () async {
        final before = failed;

        // a simple successful command — should not increment failed
        await runInTerminal('echo terminal-test');
        expect(failed, equals(before));

        // a command that fails should increment failed. Use a simple `exit 1`
        // which will be executed by the native shell selected in
        // `runInTerminal` (cmd.exe on Windows or /bin/bash on POSIX).
        await runInTerminal('exit 1');
        expect(failed, equals(before + 1));
      },
    );
  });
}
