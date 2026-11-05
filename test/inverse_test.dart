// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'package:monotone_curve_core/monotone_curve_core.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void expectSigns(MonotoneCurve curve, double y, InverseResult result) {
  expect(result.lower, lessThanOrEqualTo(result.upper));
  expect(curve.evaluate(result.lower).value, lessThanOrEqualTo(y));
  expect(curve.evaluate(result.upper).value, greaterThanOrEqualTo(y));
}

void main() {
  test('exact nonplateau knot is a point, including domain endpoints', () {
    final curve = linear();
    for (var i = 0; i < curve.knots.length; i++) {
      final knot = curve.knots[i];
      final result = curve.inverseRange(knot.y, tolerance: 0, maxIterations: 0);
      expect(result, isA<InverseBracket>());
      expect(result.lower, knot.x);
      expect(result.upper, knot.x);
      expect((result as InverseBracket).isPlateau, isFalse);
      expect(result.iterations, 0);
    }
  });

  test('plateau fixture and fully constant curve return entire intervals', () {
    final p = plateau().inverseRange(1) as InverseBracket;
    expect(p.lower, 1);
    expect(p.upper, 2);
    expect(p.isPlateau, isTrue);
    final c = constantCurve().inverseRange(4) as InverseBracket;
    expect(c.lower, 0);
    expect(c.upper, 5);
    expect(c.isPlateau, isTrue);
    expect(c.iterations, 0);
  });

  test('initial, multi-segment and final plateaus include both endpoints', () {
    final curve = build(const [
      Knot(0, 0),
      Knot(1, 0),
      Knot(2, 1),
      Knot(3, 1),
      Knot(4, 1),
      Knot(5, 2),
      Knot(6, 2),
    ]);
    for (final expected in [
      <double>[0, 0, 1],
      <double>[1, 2, 4],
      <double>[2, 5, 6],
    ]) {
      final result = curve.inverseRange(
        expected[0],
        tolerance: 0,
        maxIterations: 0,
      );
      expect(result.lower, expected[1]);
      expect(result.upper, expected[2]);
      expect((result as InverseBracket).isPlateau, isTrue);
      expectSigns(curve, expected[0], result);
    }
  });

  test('zero budget returns a valid unresolved non-knot bracket', () {
    final curve = linear();
    final result = curve.inverseRange(2.3, maxIterations: 0);
    expect(result, isA<UnresolvedBracket>());
    expect(
      (result as UnresolvedBracket).reason,
      UnresolvedReason.iterationLimit,
    );
    expect(result.lower, 0);
    expect(result.upper, 1);
    expect(result.iterations, 0);
    expectSigns(curve, 2.3, result);
  });

  test('adequate budget meets absolute x width and retains sign bounds', () {
    final curve = nonuniform();
    for (final target in [0.17, 0.7, 1.3, 1.97]) {
      final result = curve.inverseRange(target, tolerance: 1e-9);
      expect(result, isA<InverseBracket>());
      expect(result.width, lessThanOrEqualTo(1e-9));
      expect(result.width, greaterThan(0));
      expect(result.iterations, lessThanOrEqualTo(80));
      expectSigns(curve, target, result);
    }
  });

  test('budget exhaustion can be retried without modifying the curve', () {
    final curve = nonuniform();
    final short = curve.inverseRange(1.3, tolerance: 1e-12, maxIterations: 2);
    expect(short, isA<UnresolvedBracket>());
    expect(short.iterations, 2);
    expectSigns(curve, 1.3, short);
    final longer = curve.inverseRange(
      1.3,
      tolerance: 1e-12,
      maxIterations: 100,
    );
    expect(longer, isA<InverseBracket>());
    expect(longer.width, lessThanOrEqualTo(1e-12));
    expect(longer.lower, greaterThanOrEqualTo(short.lower));
    expect(longer.upper, lessThanOrEqualTo(short.upper));
  });

  test('an exactly equal midpoint is not fabricated into a point root', () {
    final curve = build(const [Knot(0, 0), Knot(1, 2)]);
    final result = curve.inverseRange(1, tolerance: 1e-9);
    expect(result, isA<InverseBracket>());
    expect(result.width, greaterThan(0));
    expect(result.lower, lessThanOrEqualTo(0.5));
    expect(result.upper, greaterThanOrEqualTo(0.5));
    expectSigns(curve, 1, result);
  });

  test('adjacent representable coordinates return unresolved stagnation', () {
    final curve = build(const [Knot(1, 0), Knot(1.0000000000000002, 1)]);
    final result = curve.inverseRange(0.5, tolerance: 0, maxIterations: 1024);
    expect(result, isA<UnresolvedBracket>());
    expect((result as UnresolvedBracket).reason, UnresolvedReason.stagnation);
    expect(result.width, greaterThan(0));
    expect(result.iterations, 0);
    expectSigns(curve, 0.5, result);
  });

  test('rounding equality does not create a declared plateau', () {
    final curve = build(const [Knot(0, 999999999), Knot(1, 1000000000)]);
    final result = curve.inverseRange(
      999999999.5,
      tolerance: 0,
      maxIterations: 1024,
    );
    expect(result, isA<UnresolvedBracket>());
    expect((result as UnresolvedBracket).reason, UnresolvedReason.stagnation);
    expect(result.width, greaterThan(0));
    expectSigns(curve, 999999999.5, result);
  });

  test('finite parameter validation and closed y domain', () {
    final curve = plateau();
    for (final bad in [-1.0, double.nan, double.infinity]) {
      expect(
        () => curve.inverseRange(0.5, tolerance: bad),
        throwsA(isA<QueryError>()),
      );
    }
    for (final bad in [-1, 1025]) {
      expect(
        () => curve.inverseRange(0.5, maxIterations: bad),
        throwsA(isA<QueryError>()),
      );
    }
    expect(() => curve.inverseRange(-0.1), throwsA(isA<DomainError>()));
    expect(() => curve.inverseRange(1.1), throwsA(isA<DomainError>()));
    expect(() => curve.inverseRange(double.nan), throwsA(isA<QueryError>()));
    expect(
      () => curve.inverseRange(double.infinity),
      throwsA(isA<QueryError>()),
    );
    final wide = curve.inverseRange(0.5, tolerance: 2, maxIterations: 0);
    expect(wide, isA<InverseBracket>());
    expect(wide.iterations, 0);
  });
}
