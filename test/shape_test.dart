// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'package:monotone_curve_core/monotone_curve_core.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('rational polynomial derivative extrema, not only dense samples', () {
    final curve = nonuniform();
    for (var i = 0; i < handCoefficients.length; i++) {
      final p = handCoefficients[i];
      final h = curve.knots[i + 1].x - curve.knots[i].x;
      final candidates = <double>[0, 1];
      if (p[3] != 0) {
        final vertex = -p[2] / (3 * p[3]);
        if (vertex > 0 && vertex < 1) candidates.add(vertex);
      }
      for (final t in candidates) {
        final q = (p[1] + 2 * p[2] * t + 3 * p[3] * t * t) / h;
        expect(q, greaterThanOrEqualTo(-1e-12));
        expect(
          curve.derivative(curve.knots[i].x + h * t).value,
          closeTo(q, 1e-12),
        );
      }
    }
  });

  test(
    'analytic quadratic minima and endpoint containment on fixed fixtures',
    () {
      final fixtures = <MonotoneCurve>[
        linear(),
        plateau(),
        constantCurve(),
        nonuniform(),
        build(const [
          Knot(-5, -8),
          Knot(-4.5, -7),
          Knot(-1, -7),
          Knot(2, 0),
          Knot(9, 3),
        ]),
        build(const [
          Knot(0, -5),
          Knot(0.125, -5),
          Knot(3, -1),
          Knot(3.5, 1),
          Knot(10, 1),
        ]),
        build(const [Knot(0, 0), Knot(1, 20), Knot(2, 20.25), Knot(8, 21)]),
      ];
      for (final curve in fixtures) {
        for (var i = 0; i < curve.knots.length - 1; i++) {
          final l = curve.knots[i];
          final r = curve.knots[i + 1];
          final h = r.x - l.x;
          final delta = (r.y - l.y) / h;
          final ml = curve.derivative(l.x).value;
          final mr = curve.derivative(r.x).value;
          // Hermite derivative in Bernstein form. The quadratic minimum occurs
          // at an endpoint or its single vertex, so sampling is not the proof.
          final middle = 3 * delta - ml - mr;
          final qa = ml - 2 * middle + mr;
          final qb = 2 * (middle - ml);
          final candidates = <double>[0, 1];
          if (qa != 0) {
            final vertex = -qb / (2 * qa);
            if (vertex > 0 && vertex < 1) candidates.add(vertex);
          }
          for (final t in candidates) {
            final u = 1 - t;
            final q = ml * u * u + 2 * middle * t * u + mr * t * t;
            expect(q, greaterThanOrEqualTo(-1e-12));
            expect(curve.derivative(l.x + h * t).value, closeTo(q, 1e-12));
          }
          expect(curve.evaluate(l.x).value, l.y);
          expect(curve.evaluate(r.x).value, r.y);
          for (var j = 0; j <= 64; j++) {
            final value = curve.evaluate(l.x + h * (j / 64)).value;
            expect(value, greaterThanOrEqualTo(l.y - 1e-12));
            expect(value, lessThanOrEqualTo(r.y + 1e-12));
          }
        }
      }
    },
  );

  test('endpoint limiting rejects a negative three-point estimate', () {
    final curve = build(const [Knot(0, 0), Knot(1, 1), Knot(2, 11)]);
    expect(curve.derivative(0).value, 0);
    expect(curve.derivative(2).value, closeTo(14.5, 1e-12));
  });
}
