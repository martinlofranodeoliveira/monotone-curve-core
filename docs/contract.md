# Numerical contract / Contrato numérico

Development version / versão de desenvolvimento **0.1.0**. This document defines the public behavior; no broad interpolation-standard compliance is claimed.

## English

### Construction and lifetime

`build(List<Knot>)` and `MonotoneCurve.build(List<Knot>)` are equivalent. `Knot` has final double `x` and `y`. Construction requires:

1. 2 through 4096 knots, inclusive. This is a hard cap in 0.1.0.
2. Finite x and y with absolute value <= 1000000000, inclusive.
3. Strictly increasing x and nondecreasing y, in the supplied order.
4. Representable construction arithmetic: every nonzero input and intermediate must be a normal binary64 value (absolute value >= 2.2250738585072014e-308); zero is allowed. Nonfinite intermediates, nonzero multiply/divide operations underflowing to zero, unsafe reciprocal spacing, secants, slopes, coefficients, and absolute derivative-expression bounds are rejected. Rounded cancellation to zero from addition/subtraction is allowed.

This last condition is intentionally conservative and can reject bounded, finite mathematical datasets. There is no coordinate merging, sorting, extrapolation, or automatic repair. Signed zero compares as zero; -0 and +0 duplicate x are invalid.

The caller's list is never changed. Success retains detached immutable knots, slopes and segments. Failure exposes no curve. `knots` is an unmodifiable list of immutable objects. There is no clock, I/O, persistent storage, or shared mutable state.

Validation throws `CurveValidationError` with `code`:

| Code | Meaning |
| --- | --- |
| `knotCount` | Outside 2–4096 |
| `nonFiniteInput` | NaN/infinite x or y |
| `magnitudeLimit` | Absolute x or y > 1e9 |
| `xNotIncreasing` | Duplicate or decreasing x |
| `yDecreasing` | Decreasing y |
| `unsafeArithmetic` | Construction representability policy failed |

The input count is captured once and checked first; custom List length getters cannot enlarge the subsequent bounded read. Knots are visited in order: finite check, magnitude check, normal-number check, ordering checks. `index` is supplied for direct finite/magnitude/order errors; arithmetic failures have no index. No exception includes a partially usable object.

### Scalar queries

`evaluate(x)`, `derivative(x)` and `integrate(a,b)` return `ScalarResult(value, clamped)`. x, a and b must be finite even when clamping is enabled; otherwise `QueryError(nonFiniteInput)` is thrown. The domain is `[minX,maxX]`, including endpoints. Finite values outside it throw `DomainError`, unless `clamp: true` is explicitly supplied.

Clamping replaces an exterior coordinate by its nearest endpoint. `clamped` is true if at least one coordinate was actually replaced; an exact endpoint does not count. Evaluation returns the exact endpoint y. Derivative returns the endpoint's one-sided stored curve slope, **not zero for a constant exterior extension**. Integration clamps a and b independently and integrates only between the resulting coordinates; it adds no exterior rectangle. Even equal exterior bounds fail by default. Valid equal bounds after domain handling return exactly `0.0`. Reversed bounds negate the answer.

Interior evaluation uses normalized t, Horner arithmetic on stored coefficients, then projection to `[yLeft,yRight]`. Exact knots return supplied y. There is no user-set evaluation tolerance, decimal rounding, or hidden epsilon. Operations use ordinary Dart double rounding; gradual query underflow to a subnormal or zero is allowed. Any nonfinite query arithmetic throws `NumericalError` with no scalar result. CLI decimal formatting is presentation only.

Derivatives use the analytic derivative of the stored polynomial divided by segment width, with stored PCHIP slopes at exact knots. The derivative does not differentiate floating rounding or value projection. Small floating discrepancies from ideal C1 continuity or nonnegativity are not certified away.

Integration uses analytic polynomial segment formulas, including partial segments, with compensated summation across segments. Its normalized limits, physical width and arithmetic are rounded independently. No quadrature or sampling is used, and no universal absolute/relative error bound is promised. The `1e-12` errors in fixture tests are fixture acceptance thresholds, not general library tolerances.

### Inversion

Signature: `inverseRange(y, {double tolerance = 1e-9, int maxIterations = 80})`.

- y must be finite and in the closed range `[minY,maxY]`. Nonfinite y throws `QueryError(nonFiniteInput)`; finite exterior y throws `DomainError`. There is no inverse clamping option.
- `tolerance` must be finite and nonnegative; otherwise `QueryError(invalidTolerance)`. It is absolute width in **x units**, not a y residual or relative tolerance. Zero and negative zero are accepted.
- `maxIterations` must be 0–1024 inclusive; otherwise `QueryError(invalidIterations)`. Parameters are checked even for exact targets, before any loop.
- Exact comparison with supplied y determines declared plateaus. All consecutive equal-y knots return their whole closed `[firstX,lastX]` as `InverseBracket(isPlateau: true, iterations: 0)`. This includes endpoint and fully constant plateaus. The width tolerance does not truncate them.
- An exact y knot not in a plateau returns `InverseBracket` with `[x,x]`, `isPlateau: false`, and zero iterations. Accidental rounding equality nearby does not expand this point.
- Every other target starts with its containing knot segment. Results retain `F(lower) <= y <= F(upper)` under the documented implemented evaluation F. These endpoint inequalities are the bracket contract. They are not outward-rounded certification of the arbitrary-precision cubic or enclosure of every accidental floating equality shelf.
- A nonplateau `InverseBracket` meets `upper-lower <= tolerance`. Its width can be positive even when a midpoint evaluates exactly to y. Rounded equality is assigned to the upper side; it is never used to manufacture an exact root.
- An initial bracket already narrow enough resolves with zero iterations. Otherwise zero budget returns `UnresolvedBracket(reason: iterationLimit)`.
- Each iteration evaluates at most one midpoint. `iterations` counts those evaluations. Budget exhaustion returns `UnresolvedBracket(reason: iterationLimit)` with valid endpoints. A rounded midpoint equal to an endpoint returns `UnresolvedBracket(reason: stagnation)` without evaluating that midpoint. This covers adjacent-representable endpoints and insufficient coordinate resolution. More budget cannot necessarily help.

`InverseResult` exposes `lower`, `upper`, `width`, and `iterations`. Only `InverseBracket` exposes `isPlateau`; only `UnresolvedBracket` exposes `reason`. A declared flat polynomial means consecutive supplied equal-y knots, not incidental equality in rounded evaluation. Complete preimage claims apply to these declared flat polynomial intervals; nonflat floating answers have the sign-bracket semantics above.

### CLI

`dart run bin/monotone_curve.dart demo [--assert] [--json]`. Each flag may occur once, in either order. `--assert` performs explicit checks regardless of Dart assertion settings. No input files or network are read. Text success is exactly `DEMO_OK value=0.687500 area=1.625000 plateau=[1,2]` plus LF. JSON success contains status, value, area and plateau. Status codes: 0 success, 64 usage, 70 internal demo/CLI failure, 74 output failure. Synchronous writes, asynchronous flush/close/completion errors, and bounded output-wait timeouts are handled without raw exception text. If diagnostics themselves fail, status remains nonzero.

## Português

### Construção e vida útil

`build(List<Knot>)` equivale a `MonotoneCurve.build(List<Knot>)`. Cada `Knot` possui x e y imutáveis do tipo double. São obrigatórios 2–4096 nós, x e y finitos com módulo <= 1000000000, x estritamente crescente e y não decrescente na ordem original.

Além disso, a construção admite somente zero ou números binary64 normais, com módulo >= 2.2250738585072014e-308, em entradas e intermediários. Rejeita resultados não finitos, underflow de multiplicação/divisão não nula para zero e falhas de representação em recíprocos dos espaçamentos, secantes, inclinações, coeficientes e limites absolutos das expressões de derivada. Cancelamento arredondado para zero em soma/subtração é permitido. Essa política conservadora pode rejeitar conjuntos finitos matematicamente válidos. -0 e +0 são a mesma coordenada para comparação.

Não há ordenação, fusão, correção automática ou alteração da lista original. A curva publicada contém cópias imutáveis. Uma falha não expõe curva parcial. `knots` não permite alterações. Não há relógio, entrada/saída, persistência ou estado mutável compartilhado.

Falhas lançam `CurveValidationError`: `knotCount` para quantidade; `nonFiniteInput` para NaN/infinito; `magnitudeLimit` para módulo excessivo; `xNotIncreasing` para x duplicado/decrescente; `yDecreasing` para y decrescente; `unsafeArithmetic` para representação insegura. A quantidade é capturada uma vez e verificada primeiro; getters de tamanho de listas personalizadas não podem ampliar a leitura limitada. Cada nó passa por finitude, módulo, normalidade e ordem, nessa sequência. `index` identifica erros diretos de finitude, módulo ou ordem; falhas aritméticas não possuem índice.

### Consultas escalares

`evaluate`, `derivative` e `integrate` retornam `ScalarResult` com `value` e `clamped`. Coordenadas não finitas geram `QueryError(nonFiniteInput)`, mesmo com ajuste habilitado. O domínio `[minX,maxX]` é fechado. Fora dele ocorre `DomainError`, exceto com `clamp: true` explícito.

O ajuste substitui a coordenada externa pela borda mais próxima. `clamped` é verdadeiro somente quando houve substituição; uma borda exata não conta. A avaliação devolve y exato da borda. A derivada devolve a inclinação unilateral armazenada, não zero de uma extensão constante imaginada. A integral ajusta cada limite separadamente, sem área externa. Limites externos iguais também falham por padrão. Após validar/ajustar o domínio, limites iguais produzem exatamente `0.0`; limites invertidos negam o resultado.

Nos nós, a avaliação retorna o y original. No interior usa t normalizado, Horner e projeção para os valores das extremidades. Não há tolerância de avaliação configurável, epsilon oculto ou arredondamento decimal. As operações seguem double do Dart; underflow finito nas consultas pode gerar subnormal ou zero. Um intermediário não finito gera `NumericalError`, sem resultado. A formatação decimal do CLI é apenas apresentação.

A derivada é analítica para o polinômio armazenado, usando as inclinações PCHIP nos nós exatos; não deriva quantização nem projeção. Pequenas diferenças de continuidade C1 ou não negatividade por arredondamento não recebem certificação. A integral usa fórmulas analíticas por trecho, inclusive trechos parciais, com soma compensada. Limites normalizados e largura física são arredondados separadamente. Não usa quadratura. O limiar `1e-12` dos testes vale para aqueles exemplos, não como garantia geral de erro.

### Inversão

`inverseRange(y, tolerance: 1e-9, maxIterations: 80)` exige y finito no intervalo fechado `[minY,maxY]`. y não finito gera `QueryError(nonFiniteInput)`; y externo finito gera `DomainError`. Não existe ajuste de domínio para inversão.

A tolerância deve ser finita e não negativa, em largura absoluta de **unidades de x**, não em resíduo de y nem erro relativo. Zero e -0 são válidos. Orçamentos de 0 a 1024 são válidos, com padrão 80. Parâmetros inválidos geram `QueryError(invalidTolerance)` ou `QueryError(invalidIterations)` antes de qualquer laço, inclusive para alvos exatos.

Igualdade exata com os valores y fornecidos define patamares. Toda sequência consecutiva de y iguais retorna o intervalo fechado completo, incluindo bordas, com `InverseBracket.isPlateau == true` e zero iterações. A tolerância não recorta esse intervalo. Um nó exato que não pertence a patamar retorna `[x,x]`, `isPlateau == false` e zero iterações. Igualdades acidentais próximas por arredondamento não expandem esse ponto.

Outros alvos iniciam no trecho entre nós correspondente. Todo resultado mantém `F(lower) <= y <= F(upper)` para a avaliação implementada F. Esse é o contrato dos limites; não é certificação com arredondamento externo do polinômio em precisão arbitrária nem inclusão de todas as igualdades acidentais do ponto flutuante.

Um `InverseBracket` não constante satisfaz `upper-lower <= tolerance`. Igualdade arredondada no ponto médio atualiza o limite superior, sem fabricar raiz exata. Se o intervalo inicial já tem largura suficiente, resolve com zero iterações; caso contrário, orçamento zero retorna `UnresolvedBracket` com motivo `iterationLimit`.

Cada iteração avalia no máximo um ponto médio. `iterations` conta avaliações. Esgotamento retorna limites válidos com motivo `iterationLimit`. Ponto médio arredondado igual a uma extremidade retorna `stagnation` sem avaliá-lo. Isso cobre coordenadas adjacentes representáveis; mais iterações podem não ajudar. `InverseResult` expõe limites, largura e contagem. Somente `InverseBracket` possui `isPlateau`; somente `UnresolvedBracket` possui `reason`. A preimagem completa é a dos trechos polinomiais declarados constantes, não a de igualdades acidentais da avaliação arredondada.

### CLI

`dart run bin/monotone_curve.dart demo [--assert] [--json]` aceita cada opção uma vez, em qualquer ordem. `--assert` verifica explicitamente os resultados, independentemente das asserções do Dart. Não lê arquivos nem rede. A linha de sucesso é exatamente `DEMO_OK value=0.687500 area=1.625000 plateau=[1,2]`, seguida de LF. JSON contém status, valor, área e patamar. Códigos: 0 sucesso, 64 uso inválido, 70 falha interna, 74 falha de saída. Escrita síncrona, flush/fechamento/conclusão assíncronos e tempos de espera limitados são tratados sem texto bruto de exceções. Se o próprio diagnóstico falhar, o código continua diferente de zero.
