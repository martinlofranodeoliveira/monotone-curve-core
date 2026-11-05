// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
import 'package:monotone_curve_core/monotone_curve_core.dart';

MonotoneCurve linear() => build(const [Knot(0, 1), Knot(1, 3), Knot(2, 5)]);
MonotoneCurve plateau() => build(const [Knot(0, 0), Knot(1, 1), Knot(2, 1)]);
MonotoneCurve constantCurve() =>
    build(const [Knot(0, 4), Knot(2, 4), Knot(5, 4)]);
MonotoneCurve nonuniform() => build(const [Knot(0, 0), Knot(1, 1), Knot(3, 2)]);

// Independently derived rational slopes and normalized coefficients.
const handSlopes = <double>[7 / 6, 9 / 13, 1 / 6];
const handCoefficients = <List<double>>[
  <double>[0, 7 / 6, -1 / 39, -11 / 78],
  <double>[1, 18 / 13, -4 / 39, -11 / 39],
];

// Hermite basis oracle, deliberately not Horner evaluation.
double hermite(double t, double y0, double y1, double h, double m0, double m1) {
  final t2 = t * t;
  final t3 = t2 * t;
  return (2 * t3 - 3 * t2 + 1) * y0 +
      (t3 - 2 * t2 + t) * h * m0 +
      (-2 * t3 + 3 * t2) * y1 +
      (t3 - t2) * h * m1;
}

// Direct polynomial primitive, independent of the factorized production area.
double primitive(List<double> p, double t) =>
    p[0] * t +
    p[1] * t * t / 2 +
    p[2] * t * t * t / 3 +
    p[3] * t * t * t * t / 4;
