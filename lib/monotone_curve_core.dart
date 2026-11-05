// SPDX-License-Identifier: MIT
// Copyright 2026 Lofrano Tecnologia

/// Memory-only, bounded PCHIP interpolation for nondecreasing data.
///
/// See docs/contract.md for floating-point and inverse-bracket semantics.
library;

part 'src/types.dart';
part 'src/numeric.dart';
part 'src/segment.dart';
part 'src/curve.dart';

/// Constructs a detached immutable curve, or throws [CurveValidationError].
MonotoneCurve build(List<Knot> knots) => MonotoneCurve.build(knots);
