// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia
part of '../monotone_curve_core.dart';

/// One supplied measurement. No missing values or inferred measurements.
final class Knot {
  final double x;
  final double y;
  const Knot(this.x, this.y);
}

/// A scalar answer and whether an out-of-domain coordinate was clamped.
final class ScalarResult {
  final double value;
  final bool clamped;
  const ScalarResult(this.value, {this.clamped = false});
}

enum ValidationCode {
  knotCount,
  nonFiniteInput,
  magnitudeLimit,
  xNotIncreasing,
  yDecreasing,
  unsafeArithmetic,
}

/// Stable validation category; [index] identifies an input knot when available.
final class CurveValidationError implements Exception {
  final ValidationCode code;
  final int? index;
  const CurveValidationError(this.code, {this.index});

  @override
  String toString() => 'CurveValidationError(${code.name}, index=$index)';
}

enum QueryCode { nonFiniteInput, invalidTolerance, invalidIterations }

final class QueryError implements Exception {
  final QueryCode code;
  const QueryError(this.code);

  @override
  String toString() => 'QueryError(${code.name})';
}

/// A finite query lies outside the closed interpolation domain.
final class DomainError implements Exception {
  final String coordinate;
  final double lower;
  final double upper;
  const DomainError(this.coordinate, this.lower, this.upper);

  @override
  String toString() => 'DomainError($coordinate outside [$lower, $upper])';
}

/// A query produced a nonfinite arithmetic intermediate. No answer is returned.
final class NumericalError implements Exception {
  const NumericalError();

  @override
  String toString() => 'NumericalError(nonfinite query arithmetic)';
}

/// Bounds are in x units. Except for declared plateaus and exact knot targets,
/// these are floating-evaluation sign brackets, not certified real intervals.
sealed class InverseResult {
  final double lower;
  final double upper;
  final int iterations;
  const InverseResult._(this.lower, this.upper, this.iterations);

  // Both endpoints are in [-1e9, 1e9], so this subtraction is finite.
  double get width => upper - lower;
}

/// A plateau, an exact nonplateau knot, or a bracket meeting the requested width.
final class InverseBracket extends InverseResult {
  final bool isPlateau;
  const InverseBracket._(
    double lower,
    double upper,
    int iterations, {
    this.isPlateau = false,
  }) : super._(lower, upper, iterations);
}

enum UnresolvedReason { iterationLimit, stagnation }

/// The endpoint inequalities remain valid, but the requested width was not met.
final class UnresolvedBracket extends InverseResult {
  final UnresolvedReason reason;
  const UnresolvedBracket._(
    double lower,
    double upper,
    int iterations,
    this.reason,
  ) : super._(lower, upper, iterations);
}
