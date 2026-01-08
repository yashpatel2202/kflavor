import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

void main() {
  group('Terminal utils', () {
    test(
      'commandExists returns true for bash (or sh) and false for nonsense',
      () async {
        // On most systems, 'bash' exists; fall back to 'sh' if not
        final bashExists = await commandExists('bash');
        final shExists = await commandExists('sh');
        expect(
          bashExists || shExists,
          isTrue,
          reason: 'Expected either bash or sh to exist on the test machine',
        );

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

        // a command that fails should increment failed
        await runInTerminal('false');
        expect(failed, equals(before + 1));
      },
    );
  });
}
