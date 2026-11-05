# Monotone Curve Core

Development version **0.1.0**, unreleased. Original MIT software by [Lofrano Tecnologia](https://lofranotecnologia.com.br). Repository: [martinlofranodeoliveira/monotone-curve-core](https://github.com/martinlofranodeoliveira/monotone-curve-core).

A small Dart library for shape-preserving interpolation of supplied, ordered, nondecreasing measurements. It evaluates PCHIP cubics, their analytic derivatives and integrals, and plateau-aware inverse brackets. It does not fit a statistical model, smooth data, infer measurements, or need charts, network access, or an API service.

[Português](README.pt-BR.md) · [Precise bilingual contract](docs/contract.md) · [Design](docs/design.md) · [Hand-derived fixtures](docs/numerical-fixtures.md)

## Install and verify

Target runtime: Dart **3.13.7**, supplied in the official image `dart:stable@sha256:517cbeb4612c4dff11c983edea521d5aef3f47a674c23684fad5e89803ca5b1c`. The library uses only the Dart SDK. `test: 1.33.0` is an exact development-only dependency.

From the project directory:

```sh
dart --version
dart pub get
dart analyze --fatal-infos
dart test
dart run bin/monotone_curve.dart demo --assert
dart run bin/monotone_curve.dart demo --assert --json
```

Human-readable output is exactly:

```text
DEMO_OK value=0.687500 area=1.625000 plateau=[1,2]
```

Machine-readable output:

```json
{"status":"DEMO_OK","value":0.6875,"area":1.625,"plateau":[1.0,2.0]}
```

Resolve dependencies once, retain the Dart-generated `pubspec.lock` in version control, and keep the populated package cache for offline tests. CI requires the committed lock and checks offline resolution after preparation:

```sh
dart pub get --offline --enforce-lockfile
dart test
dart run bin/monotone_curve.dart demo --assert
```

No runtime dependency resolution or network access is performed by the library or demo logic. Dart tooling still needs its prepared package configuration/cache. Generated files belong in `.dart_tool/` or `build/`, not source directories.

## Use

Inside this package, or from a Dart project declaring this package as a local path dependency:

```dart
import 'package:monotone_curve_core/monotone_curve_core.dart';

void main() {
  final curve = build(const [Knot(0, 0), Knot(1, 1), Knot(2, 1)]);
  final value = curve.evaluate(0.5); // value.value == 0.6875
  final slope = curve.derivative(0.5); // slope.value == 1.125
  final area = curve.integrate(0, 2); // area.value == 1.625
  final inverse = curve.inverseRange(1); // [1, 2], whole plateau
  final edge = curve.evaluate(-1, clamp: true);
  // edge.value == 0; edge.clamped == true
  if (value.clamped || slope.clamped || area.clamped || inverse.width < 0) {
    throw StateError('unexpected result');
  }
}
```

For a non-knot inverse, distinguish success from a useful but unresolved answer:

```dart
final curve = build(const [Knot(0, 1), Knot(1, 3), Knot(2, 5)]);
final result = curve.inverseRange(2.3, tolerance: 1e-9, maxIterations: 80);
if (result is UnresolvedBracket) {
  // Retains F(lower) <= 2.3 <= F(upper). Retry or accept wider bounds.
  // A larger budget cannot overcome representable-coordinate stagnation.
} else {
  // A nonplateau bracket is at most 1e-9 x units wide.
}
```

## Important contract

- 2–4096 knots; finite coordinates/values with absolute magnitude at most `1e9`; strictly increasing x and nondecreasing y. Inputs are never sorted or modified.
- Construction additionally rejects nonfinite or nonzero subnormal arithmetic, and multiply/divide underflow to zero. This conservative representability gate can reject otherwise valid finite mathematical data, including tiny spacings or huge secants.
- Closed x domain. `DomainError` by default; explicit `clamp: true` reports actual clamping. A clamped derivative is the endpoint curve slope, not the derivative of a constant extension. Clamped integration trims both bounds; it adds no exterior area.
- Exact knots return supplied values. Interior values use normalized Horner arithmetic followed by endpoint-range projection. No decimal rounding or hidden epsilon is applied.
- `inverseRange` uses an absolute **x-width** tolerance, default `1e-9`, and at most 80 bisections by default, with a hard configurable ceiling of 1024. Zero tolerance and zero iterations are valid.
- Exact nonplateau knot targets return `[x,x]`; equal-y runs return their complete closed declared plateau. These do not need bisection or satisfy a requested narrow width.
- Other answers are sign brackets for the implemented floating evaluation, not outward-rounded interval certification. Equality at a rounded midpoint never becomes a fabricated exact root. Budget failure or midpoint stagnation returns `UnresolvedBracket` with valid endpoint inequalities.
- Integration is analytic per segment, including partial segments. Reversed bounds negate the answer; valid equal bounds yield exactly zero.

## Why this design?

Normalized Hermite segments avoid powers of large absolute coordinates. Weighted harmonic interior slopes and limited one-sided endpoint slopes preserve the supplied monotone shape in real arithmetic. Detached immutable storage makes construction atomic. Bounded knot count and iteration budgets make cost inspectable: construction/integration are O(n), evaluation/derivatives O(log n), inverse O(log n + k log n), with an O(n) scan only when finding the end of an exact plateau.

Tests include rational unequal-width Hermite fixtures, independent polynomial primitives, analytic derivative-quadratic extrema, constant/linear/negative-domain cases, whole plateaus, numerical rejection, sub-ULP inverse requests, and synchronous/asynchronous CLI output failures. These are regression checks, not a universal numerical certification.

## Limitations and responsibility

Binary64 rounding, cancellation, coordinate offsets, and underflow remain visible. The reported derivative is the analytic stored polynomial derivative, not a derivative of every rounding/projection step. Rounded evaluation can have equality shelves not declared as flat polynomials; inverse plateau reporting intentionally does not expand them. There is no arbitrary-precision or broad standards-compliance claim.

This development version cannot validate measurements and is not intended for clinical or financial decisions, safety-critical control, regression, forecasting, denoising, extrapolation, or deployment guarantees. All examples are synthetic. There is no telemetry, persistent storage, shared mutable curve state, clock, or personal data.

See [CONTRIBUTING](CONTRIBUTING.md), [SECURITY](SECURITY.md), and [LICENSE](LICENSE). General contact is through the [official homepage](https://lofranotecnologia.com.br).
