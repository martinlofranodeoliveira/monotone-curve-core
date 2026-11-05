// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
part of '../monotone_curve_core.dart';

final class _NumericFailure implements Exception {
  const _NumericFailure();
}

/// Construction rejects subnormal nonzero results and multiply/divide underflow.
/// Queries permit gradual underflow, but never NaN or infinity.
final class _FiniteMath {
  final bool construction;
  const _FiniteMath({required this.construction});

  static const double minNormal = 2.2250738585072014e-308;

  double check(double value) {
    if (!value.isFinite ||
        (construction && value != 0.0 && value.abs() < minNormal)) {
      throw const _NumericFailure();
    }
    return value;
  }

  double add(double a, double b) => check(a + b);
  double sub(double a, double b) => check(a - b);

  double mul(double a, double b) {
    final value = check(a * b);
    if (construction && a != 0.0 && b != 0.0 && value == 0.0) {
      throw const _NumericFailure();
    }
    return value;
  }

  double div(double a, double b) {
    final value = check(a / b);
    if (construction && a != 0.0 && value == 0.0) {
      throw const _NumericFailure();
    }
    return value;
  }
}

const _buildMath = _FiniteMath(construction: true);
const _evalMath = _FiniteMath(construction: false);

T _numericalQuery<T>(T Function() operation) {
  try {
    return operation();
  } on _NumericFailure {
    throw const NumericalError();
  }
}

void _requireFinite(double value) {
  if (!value.isFinite) {
    throw const QueryError(QueryCode.nonFiniteInput);
  }
}

/// Weighted harmonic mean, scaled so reciprocals of tiny secants are unnecessary.
double _interiorSlope(double hl, double hr, double dl, double dr) {
  if (dl == 0.0 || dr == 0.0) return 0.0;
  final n = _buildMath;
  final scale = hl > hr ? hl : hr;
  final l = n.div(hl, scale);
  final r = n.div(hr, scale);
  final wLeft = n.add(n.mul(2.0, r), l);
  final wRight = n.add(r, n.mul(2.0, l));
  final sum = n.add(wLeft, wRight);
  final alpha = n.div(wLeft, sum);
  final beta = n.div(wRight, sum);
  final small = dl < dr ? dl : dr;
  final denominator = n.add(
    n.mul(alpha, n.div(small, dl)),
    n.mul(beta, n.div(small, dr)),
  );
  return n.div(small, denominator);
}

/// One-sided three-point estimate, limited before rescaling to value/x units.
double _endpointSlope(double hn, double hf, double dn, double df) {
  if (dn == 0.0) return 0.0;
  final n = _buildMath;
  final scale = dn > df ? dn : df;
  final near = n.div(dn, scale);
  final far = n.div(df, scale);
  final fraction = n.div(hn, n.add(hn, hf));
  var candidate = n.add(near, n.mul(fraction, n.sub(near, far)));
  if (candidate <= 0.0) return 0.0;
  if (df == 0.0) {
    final cap = n.mul(3.0, near);
    if (candidate > cap) candidate = cap;
  }
  return n.mul(candidate, scale);
}
