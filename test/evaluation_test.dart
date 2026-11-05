// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'package:monotone_curve_core/monotone_curve_core.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('linear acceptance fixture and closed endpoints', () {
    final curve = linear();
    expect(curve.evaluate(0.5).value, closeTo(2, 1e-12));
    expect(curve.evaluate(0).value, 1);
    expect(curve.evaluate(2).value, 5);
    expect(curve.derivative(0).value, 2);
    expect(curve.derivative(2).value, 2);
    expect(curve.evaluate(2).clamped, isFalse);
  });

  test('plateau fixture is cubic, not straight-line interpolation', () {
    final curve = plateau();
    expect(curve.evaluate(0.5).value, 0.6875);
    expect(curve.derivative(0.5).value, 1.125);
    expect(curve.derivative(0).value, 1.5);
    expect(curve.derivative(1).value, 0);
    expect(curve.evaluate(1.75).value, 1);
  });

  test('hand rational values and derivatives on unequal widths', () {
    final curve = nonuniform();
    expect(curve.evaluate(0.5).value, closeTo(349 / 624, 1e-12));
    expect(curve.evaluate(2).value, closeTo(509 / 312, 1e-12));
    expect(curve.derivative(0.5).value, closeTo(323 / 312, 1e-12));
    expect(curve.derivative(2).value, closeTo(167 / 312, 1e-12));
    for (var i = 0; i < curve.knots.length; i++) {
      expect(
        curve.derivative(curve.knots[i].x).value,
        closeTo(handSlopes[i], 1e-12),
      );
    }
    for (var segment = 0; segment < 2; segment++) {
      final l = curve.knots[segment];
      final r = curve.knots[segment + 1];
      for (final t in [0.125, 0.25, 0.5, 0.75, 0.875]) {
        final expected = hermite(
          t,
          l.y,
          r.y,
          r.x - l.x,
          handSlopes[segment],
          handSlopes[segment + 1],
        );
        expect(
          curve.evaluate(l.x + (r.x - l.x) * t).value,
          closeTo(expected, 1e-12),
        );
      }
    }
  });

  test('constant and negative-domain fixtures', () {
    final constant = constantCurve();
    for (final x in [0.0, 0.5, 2.0, 4.0, 5.0]) {
      expect(constant.evaluate(x).value, 4);
      expect(constant.derivative(x).value, 0);
    }
    final negative = build(const [Knot(-4, -3), Knot(-1, 0), Knot(2, 3)]);
    expect(negative.evaluate(-2).value, -1);
    expect(negative.derivative(-2).value, 1);
  });

  test('domain error is default; clamping reports only actual clamping', () {
    final curve = linear();
    expect(() => curve.evaluate(-1), throwsA(isA<DomainError>()));
    expect(() => curve.derivative(3), throwsA(isA<DomainError>()));
    final left = curve.evaluate(-1, clamp: true);
    final right = curve.evaluate(3, clamp: true);
    expect(left.value, 1);
    expect(right.value, 5);
    expect(left.clamped && right.clamped, isTrue);
    expect(curve.evaluate(0, clamp: true).clamped, isFalse);
    final derivative = curve.derivative(-1, clamp: true);
    expect(derivative.value, 2);
    expect(derivative.clamped, isTrue);
  });

  test('nonfinite queries are never clamped', () {
    for (final bad in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        () => linear().evaluate(bad, clamp: true),
        throwsA(isA<QueryError>()),
      );
      expect(
        () => linear().derivative(bad, clamp: true),
        throwsA(isA<QueryError>()),
      );
    }
  });
}
