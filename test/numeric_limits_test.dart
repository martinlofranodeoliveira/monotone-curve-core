// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'package:monotone_curve_core/monotone_curve_core.dart';
import 'package:test/test.dart';

Matcher get unsafe => isA<CurveValidationError>().having(
  (error) => error.code,
  'code',
  ValidationCode.unsafeArithmetic,
);

void main() {
  test('huge secants fail closed before publishing coefficients', () {
    final input = [const Knot(0, 0), const Knot(1e-300, 1e9)];
    expect(() => build(input), throwsA(unsafe));
    expect(input[1].x, 1e-300);
    expect(input[1].y, 1e9);
  });

  test('subnormal inputs and reciprocal-overflow spacing are rejected', () {
    expect(() => build(const [Knot(0, 0), Knot(5e-324, 1)]), throwsA(unsafe));
    expect(() => build(const [Knot(0, 0), Knot(1, 5e-324)]), throwsA(unsafe));
  });

  test(
    'construction does not silently turn a tiny positive secant into zero',
    () {
      expect(
        () => build(const [Knot(0, 0), Knot(1e9, 1e-300)]),
        throwsA(unsafe),
      );
    },
  );

  test('large normal slopes can still be represented', () {
    final curve = build(const [Knot(0, 0), Knot(1e-100, 1)]);
    expect(curve.evaluate(5e-101).value, closeTo(0.5, 1e-12));
    expect(curve.derivative(0).value / 1e100, closeTo(1, 1e-12));
    expect(curve.integrate(0, 1e-100).value / 1e-100, closeTo(0.5, 1e-12));
  });

  test('normal constant curve at tiny spacing is not rejected needlessly', () {
    final curve = build(const [Knot(0, 4), Knot(1e-300, 4)]);
    expect(curve.evaluate(5e-301).value, 4);
    expect(curve.derivative(5e-301).value, 0);
    expect(curve.integrate(0, 1e-300).value, 4e-300);
  });

  test(
    'coordinate offsets and cancellation have explicit floating behavior',
    () {
      final curve = build(const [
        Knot(999999998, -1000000000),
        Knot(999999999, -999999999),
        Knot(1000000000, -999999998),
      ]);
      expect(curve.evaluate(999999998.5).value, -999999999.5);
      expect(curve.derivative(999999998.5).value, 1);
      expect(curve.integrate(999999998, 1000000000).value, -1999999998);
      final bracket = curve.inverseRange(-999999999.5, tolerance: 1e-9);
      expect(bracket, isA<UnresolvedBracket>());
      expect(
        (bracket as UnresolvedBracket).reason,
        UnresolvedReason.stagnation,
      );
      expect(
        curve.evaluate(bracket.lower).value,
        lessThanOrEqualTo(-999999999.5),
      );
      expect(
        curve.evaluate(bracket.upper).value,
        greaterThanOrEqualTo(-999999999.5),
      );
    },
  );

  test('finite query underflow is allowed rather than inventing precision', () {
    final curve = build(const [Knot(0, 0), Knot(1, 1)]);
    final value = curve.evaluate(5e-324).value;
    expect(value.isFinite, isTrue);
    expect(value, greaterThanOrEqualTo(0));
    expect(curve.integrate(0, 5e-324).value, 0);
  });
}
