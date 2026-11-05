# Independent fixtures / Exemplos independentes

All data here are synthetic. Fractions describe ideal Hermite polynomials; tests permit `1e-12` absolute floating error for these small fixtures. They are not universal error bounds.

Todos os dados são sintéticos. As frações descrevem os polinômios ideais de Hermite; o limite de erro dos testes não é uma garantia geral.

## Linear

x=[0,1,2], y=[1,3,5]. All secants and slopes are 2, hence f(x)=1+2x. f(0.5)=2, integral over [0,2]=6, and the exact knot inverse of 3 is [1,1].

## Plateau / Patamar

x=[0,1,2], y=[0,1,1]. Slopes are [3/2,0,0]. The first normalized polynomial is `3t/2 - t³/2`; the second is constant 1. Thus:

```text
f(1/2) = 3/4 - 1/16 = 11/16 = 0.6875
integral[0,1] = 3/4 - 1/8 = 5/8
integral[0,2] = 5/8 + 1 = 13/8 = 1.625
inverseRange(1) = [1,2]
```

Its first derivative is `3/2 - 3t²/2`, whose minimum on [0,1] is zero at 1. The second derivative polynomial is identically zero. O intervalo constante inteiro é preservado, não apenas um ponto escolhido pela bisseção.

## Unequal widths / Espaçamentos diferentes

x=[0,1,3], y=[0,1,2]. Widths are 1 and 2; secants are 1 and 1/2. Harmonic weights are 5 and 4, so the middle slope is `9/(5+8)=9/13`. Endpoint estimates are 7/6 and 1/6.

Expanding the independent Hermite basis gives normalized coefficients `[a,b,c,d]`:

```text
segment [0,1]: [0, 7/6, -1/39, -11/78]
segment [1,3]: [1, 18/13, -4/39, -11/39]
```

Values and derivatives:

| x | f(x) | f'(x) |
| --- | --- | --- |
| 1/2 | 349/624 | 323/312 |
| 2 | 509/312 | 167/312 |

For direct primitive `A(t)=a*t+b*t²/2+c*t³/3+d*t⁴/4`, multiply differences by segment width. Independently reduced results:

```text
integral[0,1]   = 505/936
integral[1,3]   = 743/234
integral[0,3]   = 1159/312
integral[0,1/2] = 2135/14976
integral[1/2,2] = 8615/4992
```

Tests use this direct primitive, while implementation factors the primitive difference. Evaluation tests use the four Hermite basis functions, while implementation uses Horner coefficients.

## Analytic shape checks / Verificação analítica da forma

For a normalized cubic, derivative extrema occur at t=0, t=1, and t=-c/(3d) when that point is interior. Evaluating this finite candidate set checks the entire derivative quadratic, unlike dense samples alone.

For additional fixed fixtures tests use the independent Bernstein expression, in x derivative units:

```text
q(t) = m0*(1-t)^2 + 2*(3*delta-m0-m1)*t*(1-t) + m1*t^2
```

The single interior vertex, if present, and both endpoints are checked against -1e-12. Values are additionally sampled for endpoint containment. Verificam-se os extremos analíticos da quadrática; as amostras de valores são complementares.

## Other regression cases / Outros casos

- Constant y=4 over x=[0,2,5]: zero derivatives, area 20, inverse [0,5].
- Negative-domain linear x=[-4,-1,2], y=[-3,0,3]: f(x)=x+1, whole area zero.
- Initial, middle multi-segment, and final plateaus in one curve.
- Adjacent x values 1 and 1.0000000000000002: no interior representable midpoint; zero-width inverse request remains unresolved.
- Coordinates near 1e9: a 1e-9 inverse width is below coordinate resolution and cannot be fabricated.
- A large y offset: rounded equality at an interior midpoint does not declare a flat polynomial.
- Subnormal construction input, overflowing secants and underflowing secants: explicit rejection without mutation.
