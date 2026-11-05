// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'dart:collection';

import 'package:monotone_curve_core/monotone_curve_core.dart';
import 'package:test/test.dart';

Matcher validation(ValidationCode code) =>
    isA<CurveValidationError>().having((error) => error.code, 'code', code);

final class ExpandingReportedList extends ListBase<Knot> {
  var lengthReads = 0;

  @override
  int get length => ++lengthReads <= 2 ? 2 : 4097;

  @override
  set length(int value) => throw UnsupportedError('read-only synthetic list');

  @override
  Knot operator [](int index) => Knot(index.toDouble(), index.toDouble());

  @override
  void operator []=(int index, Knot value) =>
      throw UnsupportedError('read-only synthetic list');
}

void main() {
  test(
    'construction captures a bounded input count before reading a custom list',
    () {
      final curve = build(ExpandingReportedList());
      expect(curve.knots.length, 2);
      expect(curve.evaluate(0.5).value, 0.5);
    },
  );
  test('at least two and at most 4096 knots', () {
    expect(() => build([]), throwsA(validation(ValidationCode.knotCount)));
    expect(
      () => build(const [Knot(0, 0)]),
      throwsA(validation(ValidationCode.knotCount)),
    );
    final maximum = List<Knot>.generate(4096, (i) => Knot(i.toDouble(), 0));
    expect(build(maximum).inverseRange(0).upper, 4095);
    final excessive = List<Knot>.generate(4097, (i) => Knot(i.toDouble(), 0));
    expect(
      () => build(excessive),
      throwsA(validation(ValidationCode.knotCount)),
    );
  });

  test('duplicate and reversed x are not sorted or repaired', () {
    for (final x in [0.0, -1.0]) {
      expect(
        () => build([const Knot(0, 0), Knot(x, 1)]),
        throwsA(validation(ValidationCode.xNotIncreasing)),
      );
    }
  });

  test('decreasing y is rejected', () {
    expect(
      () => build(const [Knot(0, 2), Knot(1, 1)]),
      throwsA(validation(ValidationCode.yDecreasing)),
    );
  });

  test('NaN and infinity have a stable input error', () {
    for (final bad in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        () => build([const Knot(0, 0), Knot(1, bad)]),
        throwsA(validation(ValidationCode.nonFiniteInput)),
      );
      expect(
        () => build([const Knot(0, 0), Knot(bad, 1)]),
        throwsA(validation(ValidationCode.nonFiniteInput)),
      );
    }
  });

  test('inclusive magnitude limit and rejection outside it', () {
    final curve = build(const [Knot(-1e9, -1e9), Knot(1e9, 1e9)]);
    expect(curve.evaluate(0).value, 0);
    expect(
      () => build(const [Knot(0, 0), Knot(1e9 + 1, 1)]),
      throwsA(validation(ValidationCode.magnitudeLimit)),
    );
    expect(
      () => build(const [Knot(0, 0), Knot(1, 1e9 + 1)]),
      throwsA(validation(ValidationCode.magnitudeLimit)),
    );
  });

  test('successful construction is detached and read-only', () {
    final input = [const Knot(0, 0), const Knot(1, 1)];
    final curve = build(input);
    input[0] = const Knot(-5, -5);
    input.add(const Knot(2, 2));
    expect(curve.knots.length, 2);
    expect(curve.evaluate(0.5).value, 0.5);
    expect(() => curve.knots.add(const Knot(2, 2)), throwsUnsupportedError);
    expect(() => curve.knots[0] = const Knot(-1, -1), throwsUnsupportedError);
  });

  test('failed validation leaves caller objects and order unchanged', () {
    final input = [const Knot(2, 1), const Knot(1, 2)];
    final first = input.first;
    final second = input.last;
    expect(
      () => build(input),
      throwsA(validation(ValidationCode.xNotIncreasing)),
    );
    expect(input.length, 2);
    expect(identical(input.first, first), isTrue);
    expect(identical(input.last, second), isTrue);
  });
}
