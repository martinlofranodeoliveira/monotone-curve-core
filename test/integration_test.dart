// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'package:monotone_curve_core/monotone_curve_core.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('linear, plateau and constant exact areas', () {
    expect(linear().integrate(0, 2).value, closeTo(6, 1e-12));
    expect(plateau().integrate(0, 2).value, 1.625);
    expect(constantCurve().integrate(0, 5).value, 20);
    expect(plateau().integrate(0, 1).value, 0.625);
    expect(plateau().integrate(1, 2).value, 1);
  });

  test('independent rational antiderivative totals and partial intervals', () {
    final curve = nonuniform();
    expect(curve.integrate(0, 3).value, closeTo(1159 / 312, 1e-12));
    expect(curve.integrate(0, 0.5).value, closeTo(2135 / 14976, 1e-12));
    expect(curve.integrate(0.5, 2).value, closeTo(8615 / 4992, 1e-12));
    for (final bounds in [
      <double>[0.125, 0.875],
      <double>[1.25, 2.75],
    ]) {
      final segment = bounds[0] < 1 ? 0 : 1;
      final origin = segment == 0 ? 0.0 : 1.0;
      final h = segment == 0 ? 1.0 : 2.0;
      final p = handCoefficients[segment];
      final expected =
          h *
          (primitive(p, (bounds[1] - origin) / h) -
              primitive(p, (bounds[0] - origin) / h));
      expect(
        curve.integrate(bounds[0], bounds[1]).value,
        closeTo(expected, 1e-12),
      );
    }
  });

  test('reversal, exact zero and additivity across a knot', () {
    final curve = nonuniform();
    expect(
      curve.integrate(2.75, 0.125).value,
      -curve.integrate(0.125, 2.75).value,
    );
    expect(curve.integrate(0.3, 0.3).value, 0.0);
    final split =
        curve.integrate(0.25, 1).value + curve.integrate(1, 2.5).value;
    expect(curve.integrate(0.25, 2.5).value, closeTo(split, 1e-12));
  });

  test('negative values cancel analytically, without sampling', () {
    final curve = build(const [Knot(-4, -3), Knot(-1, 0), Knot(2, 3)]);
    expect(curve.integrate(-4, 2).value, 0);
    expect(curve.integrate(-4, -1).value, -4.5);
    expect(curve.integrate(-1, 2).value, 4.5);
  });

  test('clamping trims bounds instead of integrating an extension', () {
    final curve = linear();
    expect(() => curve.integrate(-1, 2), throwsA(isA<DomainError>()));
    expect(() => curve.integrate(-1, -1), throwsA(isA<DomainError>()));
    final trimmed = curve.integrate(-10, 10, clamp: true);
    expect(trimmed.value, 6);
    expect(trimmed.clamped, isTrue);
    expect(curve.integrate(10, -10, clamp: true).value, -6);
    final empty = curve.integrate(-10, -2, clamp: true);
    expect(empty.value, 0);
    expect(empty.clamped, isTrue);
    expect(curve.integrate(0, 2, clamp: true).clamped, isFalse);
  });

  test('nonfinite equal bounds are invalid, not zero', () {
    expect(
      () => linear().integrate(double.nan, double.nan),
      throwsA(isA<QueryError>()),
    );
    expect(
      () => linear().integrate(0, double.infinity, clamp: true),
      throwsA(isA<QueryError>()),
    );
  });
}
