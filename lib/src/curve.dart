// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
part of '../monotone_curve_core.dart';

/// Immutable PCHIP curve. Construction does not retain the caller's list.
final class MonotoneCurve {
  static const int maxKnots = 4096;
  static const double magnitudeLimit = 1000000000.0;
  static const int maxInverseIterations = 1024;

  final List<Knot> _knots;
  final List<double> _slopes;
  final List<_Segment> _segments;

  const MonotoneCurve._(this._knots, this._slopes, this._segments);

  factory MonotoneCurve.build(List<Knot> knots) {
    final count = knots.length;
    if (count < 2 || count > maxKnots) {
      throw const CurveValidationError(ValidationCode.knotCount);
    }
    try {
      final copy = <Knot>[];
      for (var i = 0; i < count; i++) {
        final knot = knots[i];
        if (!knot.x.isFinite || !knot.y.isFinite) {
          throw CurveValidationError(ValidationCode.nonFiniteInput, index: i);
        }
        if (knot.x.abs() > magnitudeLimit || knot.y.abs() > magnitudeLimit) {
          throw CurveValidationError(ValidationCode.magnitudeLimit, index: i);
        }
        _buildMath.check(knot.x);
        _buildMath.check(knot.y);
        if (i > 0) {
          if (knot.x <= copy.last.x) {
            throw CurveValidationError(ValidationCode.xNotIncreasing, index: i);
          }
          if (knot.y < copy.last.y) {
            throw CurveValidationError(ValidationCode.yDecreasing, index: i);
          }
        }
        copy.add(Knot(knot.x, knot.y));
      }
      final widths = <double>[];
      final secants = <double>[];
      for (var i = 0; i < copy.length - 1; i++) {
        final h = _buildMath.sub(copy[i + 1].x, copy[i].x);
        _buildMath.div(1.0, h);
        widths.add(h);
        secants.add(
          _buildMath.div(_buildMath.sub(copy[i + 1].y, copy[i].y), h),
        );
      }
      final slopes = List<double>.filled(copy.length, 0.0);
      if (copy.length == 2) {
        slopes[0] = secants[0];
        slopes[1] = secants[0];
      } else {
        slopes[0] = _endpointSlope(
          widths[0],
          widths[1],
          secants[0],
          secants[1],
        );
        final last = widths.length - 1;
        slopes[copy.length - 1] = _endpointSlope(
          widths[last],
          widths[last - 1],
          secants[last],
          secants[last - 1],
        );
        for (var i = 1; i < copy.length - 1; i++) {
          slopes[i] = _interiorSlope(
            widths[i - 1],
            widths[i],
            secants[i - 1],
            secants[i],
          );
        }
      }
      final segments = <_Segment>[];
      for (var i = 0; i < copy.length - 1; i++) {
        segments.add(
          _Segment.build(copy[i], copy[i + 1], slopes[i], slopes[i + 1]),
        );
      }
      return MonotoneCurve._(
        List<Knot>.unmodifiable(copy),
        List<double>.unmodifiable(slopes),
        List<_Segment>.unmodifiable(segments),
      );
    } on _NumericFailure {
      throw const CurveValidationError(ValidationCode.unsafeArithmetic);
    }
  }

  List<Knot> get knots => _knots;
  double get minX => _knots.first.x;
  double get maxX => _knots.last.x;
  double get minY => _knots.first.y;
  double get maxY => _knots.last.y;

  ScalarResult _bound(double x, String name, bool clamp) {
    _requireFinite(x);
    if (x < minX) {
      if (!clamp) throw DomainError(name, minX, maxX);
      return ScalarResult(minX, clamped: true);
    }
    if (x > maxX) {
      if (!clamp) throw DomainError(name, minX, maxX);
      return ScalarResult(maxX, clamped: true);
    }
    return ScalarResult(x);
  }

  int _lowerX(double x) {
    var lo = 0;
    var hi = _knots.length;
    while (lo < hi) {
      final mid = lo + ((hi - lo) ~/ 2);
      if (_knots[mid].x < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  int _lowerY(double y) {
    var lo = 0;
    var hi = _knots.length;
    while (lo < hi) {
      final mid = lo + ((hi - lo) ~/ 2);
      if (_knots[mid].y < y) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  double _valueAt(double x) {
    final i = _lowerX(x);
    if (_knots[i].x == x) return _knots[i].y;
    return _segments[i - 1].value(x);
  }

  /// Evaluate in the closed domain; explicit clamping is reported.
  ScalarResult evaluate(double x, {bool clamp = false}) {
    final bounded = _bound(x, 'x', clamp);
    return _numericalQuery(
      () => ScalarResult(_valueAt(bounded.value), clamped: bounded.clamped),
    );
  }

  /// At a clamped coordinate, returns the endpoint's one-sided curve slope,
  /// not the derivative of an imagined constant extension.
  ScalarResult derivative(double x, {bool clamp = false}) {
    final bounded = _bound(x, 'x', clamp);
    return _numericalQuery(() {
      final i = _lowerX(bounded.value);
      final value = _knots[i].x == bounded.value
          ? _slopes[i]
          : _segments[i - 1].derivative(bounded.value);
      return ScalarResult(value, clamped: bounded.clamped);
    });
  }

  /// Analytic segment integration. Clamping trims each bound independently.
  ScalarResult integrate(double a, double b, {bool clamp = false}) {
    final ba = _bound(a, 'a', clamp);
    final bb = _bound(b, 'b', clamp);
    final clamped = ba.clamped || bb.clamped;
    return _numericalQuery(() {
      var left = ba.value;
      var right = bb.value;
      if (left == right) return ScalarResult(0.0, clamped: clamped);
      final reversed = left > right;
      if (reversed) {
        final swap = left;
        left = right;
        right = swap;
      }
      final n = _evalMath;
      var sum = 0.0;
      var correction = 0.0;
      for (final segment in _segments) {
        if (segment.x1 <= left || segment.x0 >= right) continue;
        final l = left > segment.x0 ? left : segment.x0;
        final r = right < segment.x1 ? right : segment.x1;
        final term = segment.area(l, r);
        final next = n.add(sum, term);
        final residual = sum.abs() >= term.abs()
            ? n.add(n.sub(sum, next), term)
            : n.add(n.sub(term, next), sum);
        correction = n.add(correction, residual);
        sum = next;
      }
      final total = n.add(sum, correction);
      return ScalarResult(
        reversed ? n.sub(0.0, total) : total,
        clamped: clamped,
      );
    });
  }

  /// Absolute x-width tolerance, default 1e-9; no relative or y tolerance.
  /// Exact knot targets and whole declared plateaus bypass bisection.
  InverseResult inverseRange(
    double y, {
    double tolerance = 1e-9,
    int maxIterations = 80,
  }) {
    _requireFinite(y);
    if (!tolerance.isFinite || tolerance < 0.0) {
      throw const QueryError(QueryCode.invalidTolerance);
    }
    if (maxIterations < 0 || maxIterations > maxInverseIterations) {
      throw const QueryError(QueryCode.invalidIterations);
    }
    if (y < minY || y > maxY) throw DomainError('y', minY, maxY);
    return _numericalQuery<InverseResult>(() {
      final i = _lowerY(y);
      if (_knots[i].y == y) {
        var end = i;
        while (end + 1 < _knots.length && _knots[end + 1].y == y) {
          end++;
        }
        return InverseBracket._(
          _knots[i].x,
          _knots[end].x,
          0,
          isPlateau: end > i,
        );
      }
      var lo = _knots[i - 1].x;
      var hi = _knots[i].x;
      var used = 0;
      final n = _evalMath;
      if (n.sub(hi, lo) <= tolerance) {
        return InverseBracket._(lo, hi, used);
      }
      while (used < maxIterations) {
        final mid = n.add(lo, n.div(n.sub(hi, lo), 2.0));
        if (mid == lo || mid == hi) {
          return UnresolvedBracket._(lo, hi, used, UnresolvedReason.stagnation);
        }
        final value = _valueAt(mid);
        used++;
        // Equality is not evidence of a mathematical root or declared plateau.
        if (value < y) {
          lo = mid;
        } else {
          hi = mid;
        }
        if (n.sub(hi, lo) <= tolerance) {
          return InverseBracket._(lo, hi, used);
        }
      }
      return UnresolvedBracket._(lo, hi, used, UnresolvedReason.iterationLimit);
    });
  }
}
