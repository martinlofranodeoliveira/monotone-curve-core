# Security policy

## Reporting

Report suspected vulnerabilities privately using GitHub private vulnerability reporting:

https://github.com/martinlofranodeoliveira/monotone-curve-core/security/advisories/new

Do not put secrets, real personal data, private measurement records, or client code in reports. Include a minimal synthetic reproducer, Dart version, relevant operation, expected behavior, and the resource or numerical boundary involved. Do not disclose sensitive details in a public issue. No response-time SLA is offered.

For general contact, use the official homepage: https://lofranotecnologia.com.br

## Scope

0.1.0 is an unreleased development version. No released-version support or production-readiness claim is made. The runtime library performs no I/O, network activity, persistence, telemetry, or dynamic code loading. It bounds knots and inverse iterations, validates construction arithmetic, and returns typed failures rather than partially usable curves.

The CLI accepts only fixed demo options and synthetic in-memory data. It handles synchronous and asynchronous output failures with fixed diagnostics and nonzero status. The development-only test dependency still requires ordinary dependency review and a genuine Dart-generated lock.

Floating-point rounding, inability to meet a sub-ULP tolerance, and documented conservative input rejection are numerical limitations, not hidden exactness guarantees. Report violations of the documented bracket inequalities, resource bounds, validation, or immutability as defects. This software is not intended for clinical or financial decisions or safety-critical control.
