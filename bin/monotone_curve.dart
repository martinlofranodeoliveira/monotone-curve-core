// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:monotone_curve_core/monotone_curve_core.dart';

const _usage =
    'Usage: dart run bin/monotone_curve.dart demo [--assert] [--json]\n';
const _ioTimeout = Duration(seconds: 5);

/// Observe IOSink.done before writing, including failures delivered separately
/// from flush(). Close the CLI-owned sink and await completion before success.
Future<bool> _emit(IOSink sink, String text) async {
  try {
    final completion = sink.done.then<bool>(
      (_) => true,
      onError: (Object _, StackTrace __) => false,
    );
    try {
      sink.write(text);
      await sink.flush().timeout(_ioTimeout);
      await sink.close().timeout(_ioTimeout);
      return await completion.timeout(_ioTimeout);
    } catch (_) {
      try {
        await sink.close().timeout(_ioTimeout);
      } catch (_) {
        // The fixed diagnostic is attempted on the other sink by the caller.
      }
      try {
        await completion.timeout(_ioTimeout);
      } catch (_) {
        // A blocked or failed completion is also an output failure.
      }
      return false;
    }
  } catch (_) {
    return false;
  }
}

/// The CLI owns and closes supplied sinks. Injection supports failure tests.
Future<int> runCli(List<String> args, {IOSink? output, IOSink? errors}) async {
  final out = output ?? stdout;
  final err = errors ?? stderr;
  final flags = args.length > 1 ? args.sublist(1) : <String>[];
  final valid =
      args.isNotEmpty &&
      args.first == 'demo' &&
      flags.every((flag) => flag == '--assert' || flag == '--json') &&
      flags.toSet().length == flags.length;
  if (!valid) return await _emit(err, _usage) ? 64 : 74;

  late final String text;
  try {
    final curve = build(const [Knot(0, 0), Knot(1, 1), Knot(2, 1)]);
    final value = curve.evaluate(0.5).value;
    final area = curve.integrate(0, 2).value;
    final inverse = curve.inverseRange(1);
    if (flags.contains('--assert') &&
        ((value - 0.6875).abs() > 1e-12 ||
            (area - 1.625).abs() > 1e-12 ||
            inverse is! InverseBracket ||
            !inverse.isPlateau ||
            inverse.lower != 1 ||
            inverse.upper != 2)) {
      throw StateError('demo invariant');
    }
    if (flags.contains('--json')) {
      text =
          '${jsonEncode(<String, Object>{
            'status': 'DEMO_OK',
            'value': value,
            'area': area,
            'plateau': <double>[inverse.lower, inverse.upper],
          })}\n';
    } else {
      text =
          'DEMO_OK value=${value.toStringAsFixed(6)} '
          'area=${area.toStringAsFixed(6)} '
          'plateau=[${inverse.lower.toStringAsFixed(0)},'
          '${inverse.upper.toStringAsFixed(0)}]\n';
    }
  } catch (_) {
    return await _emit(err, 'DEMO_ERROR\n') ? 70 : 74;
  }
  if (!await _emit(out, text)) {
    await _emit(err, 'OUTPUT_ERROR\n');
    return 74;
  }
  return 0;
}

Future<void> main(List<String> args) async {
  // Failure is the default even if an awaited operation never completes.
  exitCode = 74;
  try {
    exitCode = await runCli(args);
  } catch (_) {
    exitCode = await _emit(stderr, 'CLI_ERROR\n') ? 70 : 74;
  }
}
