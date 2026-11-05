# Design — development 0.1.0

## Mathematical basis and provenance

This implementation is original Dart code derived from mathematical formulas, not a translation of an external implementation. References:

1. [SciPy PchipInterpolator mathematical notes](https://docs.scipy.org/doc/scipy/reference/generated/scipy.interpolate.PchipInterpolator.html): weighted harmonic interior derivatives and one-sided endpoint estimates.
2. F. N. Fritsch and J. Butland, *A Method for Constructing Local Monotone Piecewise Cubic Interpolants*, SIAM J. Sci. Stat. Comput. 5(2), 300–304 (1984), [DOI 10.1137/0905021](https://doi.org/10.1137/0905021). The publisher abstract is available; the full text is paywalled.
3. Cleve Moler, *Numerical Computing with MATLAB*, [Chapter 3, sections 3.3/3.4](https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/moler/interp.pdf): piecewise cubic Hermite interpolation and shape preservation.
4. [Dart mathematical library documentation](https://api.dart.dev/dart-math/) and Dart double arithmetic conventions. No scientific-library runtime is needed.

No SciPy implementation source is included or translated. Tests use rational fixtures and independent basis/primitive calculations, not a runtime SciPy oracle.

For interval widths h_i and secants delta_i, an interior slope is zero if either neighboring secant is zero. Otherwise:

```text
wL = 2*hR + hL
wR = hR + 2*hL
m = (wL+wR) / (wL/deltaL + wR/deltaR)
```

All secants here are nonnegative because decreasing y is rejected. The implementation divides widths by their maximum, normalizes the weights, and scales by the smaller secant. This avoids directly reciprocating tiny secants. It does not eliminate all representability failures: ratios that become subnormal or underflow during construction are rejected.

At an endpoint, the one-sided estimate is algebraically:

```text
mNear = deltaNear + hNear/(hNear+hFar) * (deltaNear-deltaFar)
```

Secants are scaled before this expression. A nonpositive estimate is set to zero; the usual three-secant cap applies against a zero neighboring secant. With nonnegative data secants, the cap is rarely active, but the sign limiter matters. For two knots both slopes equal the single secant.

For t=(x-x0)/h, let u=h*m0 and v=h*m1. Expanding the four Hermite basis functions gives:

```text
a = y0
b = u
c = 3*(y1-y0) - 2*u - v
d = u + v - 2*(y1-y0)
P(t) = a + b*t + c*t^2 + d*t^3
P'(x) = (b + 2*c*t + 3*d*t^2)/h
```

Every construction arithmetic operation passes through a checked kernel. A conservative absolute-coefficient derivative bound is checked as well. Local temporaries are discarded on any failure; no curve is published before every segment succeeds.

## Numerical representation

The input limits are deliberately modest, but tiny differences can still create huge slopes. The construction gate accepts zero or normal binary64 numbers only, rejects nonfinite intermediates, and rejects nonzero multiply/divide operands whose result underflows to zero. It checks reciprocal spacing explicitly. This is a representability policy, not a guarantee that all bounded finite data can be interpolated.

Subtraction cancellation and rounding to an ordinary normal value are allowed; exactness is not inferred from them. At query time finite gradual underflow is allowed. Nonfinite query intermediates fail with `NumericalError`. All coefficient/query arithmetic uses the checked kernel; bounded integer indexing is separate.

Exact knot evaluations return supplied y values. Interior Horner results are projected to the segment's endpoint value range. This prevents roundoff overshoot but cannot make floating-point arithmetic an exact monotone real function. Derivatives are analytic derivatives of stored coefficients, with stored PCHIP slopes returned at exact knots; they are not derivatives of quantization or endpoint projection.

## Inverse invariants

The y lower-bound search finds exact knot equality before bisection. All consecutive equal-y knots form the declared closed plateau; its endpoints are returned even when the plateau touches a domain endpoint or exceeds the requested tolerance. A single matching knot returns a point.

For other targets the initial segment satisfies F(lo) < target < F(hi). Each evaluated midpoint replaces lo only if F(mid) < target; otherwise it replaces hi. Thus F(lo) <= target <= F(hi) is retained by the same implemented evaluator used by callers. Rounded equality at a midpoint never collapses the answer to a point. Finite floating evaluation is not claimed to be perfectly monotone at every representable coordinate, so these are sign brackets, not a certified enclosure of every accidental rounding preimage.

A midpoint equal to either endpoint signals representable-coordinate stagnation. Width is tested before reporting success. Stagnation and exhausted budgets return unresolved sign brackets rather than invented precision. Exact knot/declared plateau semantics take precedence over rounded equality shelves.

## Integration

The analytic primitive is a*t + b*t²/2 + c*t³/3 + d*t⁴/4, multiplied by h. Production code factors its difference over limits l,r into the physical x width times:

```text
a + b*(l+r)/2
  + c*(l*l+l*r+r*r)/3
  + d*(l+r)*(l*l+r*r)/4
```

This avoids subtracting nearly equal large primitive values. Normalized limits and physical width are rounded separately; it is a floating implementation of the analytic formula, not exact real integration. Segment contributions use Neumaier compensated summation. There is no cached cumulative-area table whose subtraction could erase a small partial area.

## Surface area and cost

The public library has one immutable curve type, immutable knots/results, and typed errors. Internal files are library parts, so numerical helpers are not public API. No I/O, callbacks, clock, mutable globals, or runtime packages are used by curves. Storage is O(n), capped at 4096 knots. Integration visits at most 4095 segments. Bisection has an explicit hard cap of 1024 and a default budget of 80.

The CLI owns its output sinks, subscribes to their completion before writes, awaits flush/close/completion, and uses fixed diagnostics. A five-second timeout bounds each output wait. Its default process exit status is failure until awaited completion succeeds. This I/O timeout does not enter numerical behavior.

## Evidence and non-goals

The fixed test suite combines rational answers, Hermite-basis evaluation, independent direct polynomial primitives, analytical quadratic derivative extrema, and adversarial resource/rounding cases. Dense value samples supplement, rather than replace, extrema checks. This is not a proof over all binary64 inputs or a standards certification.

No extrapolation, prediction, noise reduction, plotting, arbitrary precision, outward-rounded intervals, measurement validation, or safety-critical decision support is provided.
