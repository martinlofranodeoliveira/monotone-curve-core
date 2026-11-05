# Contributing

This is development version 0.1.0. Contributions should preserve the precise contract in [docs/contract.md](docs/contract.md), or explicitly describe a proposed contract change. Use synthetic data only. Do not include private client code, personal information, credentials, measured-user claims, or generated build output.

## Local checks

Use Dart 3.13.7. The exact development dependency is `test: 1.33.0`; the runtime library must remain SDK-only.

```sh
dart pub get
dart format lib bin test
dart analyze --fatal-infos
dart test
dart run bin/monotone_curve.dart demo --assert
dart run bin/monotone_curve.dart demo --assert --json
```

Retain the real `pubspec.lock` produced by Dart tooling in version control. Do not hand-author lockfile hashes. With the lock and populated cache:

```sh
dart pub get --offline --enforce-lockfile
dart test
```

CI uses the digest-pinned official Dart image recorded in the READMEs, requires the committed lock, prepares the package cache under `build/`, and checks offline resolution. Keep other generated output in `.dart_tool/` or `build/`.

## Numerical changes

Explain the mathematical derivation and arithmetic policy. Include an independently derived regression case, not merely the output of the changed implementation. Shape changes need analytical derivative-extrema checks; area changes need independent primitives or rational integrals; inverse changes need endpoint-inequality, plateau, budget, equality-rounding and stagnation tests. Avoid introducing exact-root or interval-certification claims for ordinary floating arithmetic.

Keep knot and iteration caps, immutable storage and typed failures. No network, telemetry, model service, clock, or shared mutable state belongs in the curve library. New CLI output must retain fixed safe diagnostics and handle write, flush and completion failures.

Documentation changes affecting public behavior belong in both READMEs and both language sections of the numerical contract. Add user-visible changes to the unreleased changelog. Source contributions are under the repository's MIT license; identify external mathematical references without copying their implementations.

Use repository issues for non-sensitive defects with minimal synthetic inputs and SDK version. Follow [SECURITY.md](SECURITY.md) for vulnerabilities. General contact: [Lofrano Tecnologia](https://lofranotecnologia.com.br).
