// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/monotone_curve.dart' as cli;

final class MemorySink implements IOSink {
  final buffer = StringBuffer();
  final bool failWrite;
  final bool failFlush;
  final bool failDone;
  final Completer<void> _completion = Completer<void>();

  MemorySink({
    this.failWrite = false,
    this.failFlush = false,
    this.failDone = false,
  });

  @override
  Future<void> get done => _completion.future;

  @override
  void write(Object? object) {
    if (failWrite) throw StateError('synthetic write failure');
    buffer.write(object);
  }

  @override
  Future<void> flush() async {
    if (failFlush) throw StateError('synthetic flush failure');
  }

  @override
  Future<void> close() {
    if (!_completion.isCompleted) {
      if (failDone) {
        _completion.completeError(StateError('synthetic done failure'));
      } else {
        _completion.complete();
      }
    }
    return _completion.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('exact demo line from actual process', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/monotone_curve.dart',
      'demo',
      '--assert',
    ]).timeout(const Duration(seconds: 30));
    expect(result.exitCode, 0);
    expect(result.stderr, '');
    expect(
      result.stdout,
      'DEMO_OK value=0.687500 area=1.625000 plateau=[1,2]\n',
    );
  });

  test(
    'machine-readable demo has only deterministic synthetic values',
    () async {
      final out = MemorySink();
      final err = MemorySink();
      expect(
        await cli.runCli(
          ['demo', '--assert', '--json'],
          output: out,
          errors: err,
        ),
        0,
      );
      expect(jsonDecode(out.buffer.toString()), {
        'status': 'DEMO_OK',
        'value': 0.6875,
        'area': 1.625,
        'plateau': [1.0, 2.0],
      });
      expect(err.buffer.toString(), '');
    },
  );

  test('invalid and duplicate options have fixed usage and status', () async {
    for (final args in [
      <String>[],
      ['other'],
      ['demo', '--bad'],
      ['demo', '--json', '--json'],
    ]) {
      final out = MemorySink();
      final err = MemorySink();
      expect(await cli.runCli(args, output: out, errors: err), 64);
      expect(out.buffer.toString(), '');
      expect(
        err.buffer.toString(),
        'Usage: dart run bin/monotone_curve.dart demo [--assert] [--json]\n',
      );
    }
  });

  test(
    'synchronous write, asynchronous flush and done failures are nonzero',
    () async {
      for (final out in [
        MemorySink(failWrite: true),
        MemorySink(failFlush: true),
        MemorySink(failDone: true),
      ]) {
        final err = MemorySink();
        expect(await cli.runCli(['demo'], output: out, errors: err), 74);
        expect(err.buffer.toString(), 'OUTPUT_ERROR\n');
        expect(err.buffer.toString(), isNot(contains('StateError')));
      }
    },
  );

  test(
    'stderr failures cannot turn usage or stdout failure into success',
    () async {
      for (final err in [
        MemorySink(failWrite: true),
        MemorySink(failFlush: true),
        MemorySink(failDone: true),
      ]) {
        expect(await cli.runCli([], output: MemorySink(), errors: err), 74);
      }
      expect(
        await cli.runCli(
          ['demo'],
          output: MemorySink(failWrite: true),
          errors: MemorySink(failFlush: true),
        ),
        74,
      );
    },
  );
}
