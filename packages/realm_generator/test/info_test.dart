import 'dart:io';

import 'package:logging/logging.dart';
import 'package:term_glyph/term_glyph.dart';
import 'package:test/test.dart';

import 'test_util.dart';

// build_runner wraps every log emitted while a builder is running with a
// 'Generating <output>: <builder> on <input>:\n' header, and also emits its
// own progress notices ('Running <builder>', '[generate (n)] completed...')
// through the same wrapper. Strip the header to recover the message actually
// passed to `log.info` in realm_generator, and skip build_runner's own notices.
final _builderContextHeader = RegExp(r'^Generating [^\n]*:\n');

void main() async {
  const directory = 'test/info_test_data';
  ascii = false; // force unicode glyphs

  await for (final infoFile in Directory(directory).list(recursive: true).where((f) => f.path.endsWith('.expected')).cast<File>()) {
    final sourceFile = File(infoFile.path.replaceFirst('.expected', '.dart'));
    String? firstLog;
    testCompile(
      'log from compile $sourceFile',
      sourceFile,
      completion(predicate((_) {
        return firstLog?.normalizeLineEndings() == infoFile.readAsStringSync().normalizeLineEndings();
      })),
      onLog: (record) {
        if (firstLog != null || record.level != Level.INFO) return;
        final header = _builderContextHeader.firstMatch(record.message);
        if (header == null) return;
        final message = record.message.substring(header.end);
        if (message.startsWith('Running ') || message.startsWith('[generate')) return;
        firstLog = '[INFO] testBuilder: $message';
      },
    );
  }
}
