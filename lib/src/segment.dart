// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
part of '../monotone_curve_core.dart';

/// Original normalized Hermite representation: a + b*t + c*t^2 + d*t^3.
final class _Segment {
  final double x0;
  final double x1;
  final double y0;
  final double y1;
  final double h;
  final double a;
  final double b;
  final double c;
  final double d;

  const _Segment._(
    this.x0,
    this.x1,
    this.y0,
    this.y1,
    this.h,
    this.a,
    this.b,
    this.c,
    this.d,
  );

  factory _Segment.build(Knot left, Knot right, double ml, double mr) {
    final n = _buildMath;
    final h = n.sub(right.x, left.x);
    final dy = n.sub(right.y, left.y);
    final b = n.mul(h, ml);
    final end = n.mul(h, mr);
    final c = n.sub(n.sub(n.mul(3.0, dy), n.mul(2.0, b)), end);
    final d = n.sub(n.add(b, end), n.mul(2.0, dy));
    // Bound the absolute derivative expression before allowing any queries.
    final derivativeNumeratorBound = n.add(
      b.abs(),
      n.add(n.mul(2.0, c.abs()), n.mul(3.0, d.abs())),
    );
    n.div(derivativeNumeratorBound, h);
    n.add(left.y.abs(), n.add(b.abs(), n.add(c.abs(), d.abs())));
    return _Segment._(left.x, right.x, left.y, right.y, h, left.y, b, c, d);
  }

  double _t(double x) {
    if (x == x0) return 0.0;
    if (x == x1) return 1.0;
    return _evalMath.div(_evalMath.sub(x, x0), h);
  }

  double value(double x) {
    if (x == x0) return y0;
    if (x == x1) return y1;
    final n = _evalMath;
    final t = _t(x);
    final raw = n.add(n.mul(n.add(n.mul(n.add(n.mul(d, t), c), t), b), t), a);
    // Numerical projection is not out-of-domain clamping.
    if (raw < y0) return y0;
    if (raw > y1) return y1;
    return raw;
  }

  double derivative(double x) {
    final n = _evalMath;
    final t = _t(x);
    final q = n.add(b, n.mul(t, n.add(n.mul(2.0, c), n.mul(n.mul(3.0, d), t))));
    return n.div(q, h);
  }

  /// Factorized antiderivative difference avoids subtracting nearly equal areas.
  double area(double left, double right) {
    final n = _evalMath;
    final l = _t(left);
    final r = _t(right);
    final l2 = n.mul(l, l);
    final r2 = n.mul(r, r);
    final sum2 = n.add(l, r);
    final sum3 = n.add(n.add(l2, n.mul(l, r)), r2);
    final sum4 = n.mul(sum2, n.add(l2, r2));
    final mean = n.add(
      n.add(a, n.mul(n.div(b, 2.0), sum2)),
      n.add(n.mul(n.div(c, 3.0), sum3), n.mul(n.div(d, 4.0), sum4)),
    );
    return n.mul(n.sub(right, left), mean);
  }
}
