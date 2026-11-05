# Monotone Curve Core

Versão de desenvolvimento **0.1.0**, ainda não lançada. Software original MIT da [Lofrano Tecnologia](https://lofranotecnologia.com.br). Repositório: [martinlofranodeoliveira/monotone-curve-core](https://github.com/martinlofranodeoliveira/monotone-curve-core).

Biblioteca Dart para interpolação PCHIP de medições fornecidas, ordenadas e não decrescentes. Oferece avaliação, derivadas analíticas, integração analítica e inversão que preserva intervalos constantes. Não ajusta modelo estatístico, não suaviza dados, não inventa medições e não depende de gráficos, rede ou serviço de API.

[English](README.md) · [Contrato numérico bilíngue](docs/contract.md) · [Projeto](docs/design.md) · [Exemplos derivados à mão](docs/numerical-fixtures.md)

## Instalação e verificação

Ambiente-alvo: Dart **3.13.7**, fornecido pela imagem oficial `dart:stable@sha256:517cbeb4612c4dff11c983edea521d5aef3f47a674c23684fad5e89803ca5b1c`. A biblioteca usa somente o SDK. `test: 1.33.0` é uma dependência exata apenas de desenvolvimento.

No diretório do projeto:

```sh
dart --version
dart pub get
dart analyze --fatal-infos
dart test
dart run bin/monotone_curve.dart demo --assert
dart run bin/monotone_curve.dart demo --assert --json
```

Saída legível exata:

```text
DEMO_OK value=0.687500 area=1.625000 plateau=[1,2]
```

Saída para processamento automático:

```json
{"status":"DEMO_OK","value":0.6875,"area":1.625,"plateau":[1.0,2.0]}
```

Resolva as dependências uma vez, mantenha o `pubspec.lock` gerado pelo Dart no controle de versão e preserve o cache populado para testes sem rede. O CI exige o lock versionado e verifica a resolução offline após a preparação:

```sh
dart pub get --offline --enforce-lockfile
dart test
dart run bin/monotone_curve.dart demo --assert
```

A biblioteca e a lógica da demonstração não acessam a rede nem resolvem dependências durante o uso. As ferramentas Dart ainda precisam da configuração e do cache preparados. Arquivos gerados ficam em `.dart_tool/` ou `build/`, não junto ao código-fonte.

## Uso

Neste pacote, ou em um projeto Dart que declare este pacote como dependência por caminho local:

```dart
import 'package:monotone_curve_core/monotone_curve_core.dart';

void main() {
  final curva = build(const [Knot(0, 0), Knot(1, 1), Knot(2, 1)]);
  final valor = curva.evaluate(0.5); // valor.value == 0.6875
  final derivada = curva.derivative(0.5); // derivada.value == 1.125
  final area = curva.integrate(0, 2); // area.value == 1.625
  final inversa = curva.inverseRange(1); // intervalo completo [1, 2]
  final borda = curva.evaluate(-1, clamp: true);
  // borda.value == 0; borda.clamped == true
  if (valor.clamped || derivada.clamped || area.clamped || inversa.width < 0) {
    throw StateError('resultado inesperado');
  }
}
```

Para alvos que não sejam nós, trate explicitamente resultados não resolvidos:

```dart
final curva = build(const [Knot(0, 1), Knot(1, 3), Knot(2, 5)]);
final resultado = curva.inverseRange(2.3, tolerance: 1e-9, maxIterations: 80);
if (resultado is UnresolvedBracket) {
  // Mantém F(lower) <= 2.3 <= F(upper). É possível tentar outro orçamento.
  // Mais iterações não superam a estagnação entre coordenadas representáveis.
} else {
  // Um intervalo não constante tem largura máxima de 1e-9 unidades de x.
}
```

## Contrato essencial

- De 2 a 4096 nós; x e y finitos com módulo máximo de `1e9`; x estritamente crescente e y não decrescente. A entrada não é ordenada nem alterada.
- A construção também rejeita aritmética não finita, resultados subnormais não nulos e underflow de multiplicação/divisão para zero. Essa política conservadora pode rejeitar dados matematicamente válidos, inclusive espaçamentos minúsculos ou secantes enormes.
- Domínio de x fechado. Fora dele ocorre `DomainError`, salvo `clamp: true`, que informa o ajuste em `clamped`. A derivada ajustada é a inclinação da curva na borda, não a derivada de uma extensão constante. A integral ajusta cada limite e não acrescenta área externa.
- Nos nós, a avaliação devolve o y fornecido. No interior usa Horner normalizado e projeção para o intervalo dos valores das extremidades. Não há arredondamento decimal nem epsilon oculto.
- A tolerância de `inverseRange` é uma largura absoluta em **unidades de x**, com padrão `1e-9`. O padrão é de 80 bisseções; o teto configurável é 1024. Zero é válido para tolerância e orçamento.
- Alvo exatamente igual a um nó não constante produz `[x,x]`. Uma sequência de y iguais produz todo o intervalo constante fechado. Esses casos não precisam de bisseção e não estão sujeitos à largura solicitada.
- Nos demais casos, os limites satisfazem desigualdades da avaliação em ponto flutuante implementada; não constituem certificação com arredondamento externo. Igualdade arredondada no ponto médio não cria raiz exata. Falta de iterações ou estagnação devolve `UnresolvedBracket` com limites válidos.
- A integração é analítica por trecho, inclusive em trechos parciais. Limites invertidos negam o resultado; limites válidos iguais produzem exatamente zero.

## Escolhas de projeto

Trechos de Hermite normalizados evitam potências das coordenadas absolutas. Médias harmônicas ponderadas nas inclinações internas e estimativas limitadas nas bordas preservam a monotonicidade em aritmética real. O armazenamento é imutável e separado da lista original; a construção só publica uma curva completa.

Construção e integração custam O(n), avaliação e derivada O(log n), e inversão O(log n + k log n), além de uma busca O(n) somente para localizar o fim de um patamar exato. O limite de nós e o orçamento de iterações tornam esses custos explícitos.

Os testes incluem coeficientes racionais de Hermite com espaçamentos diferentes, primitivas polinomiais independentes, extremos analíticos das derivadas quadráticas, curvas constantes/lineares em domínio negativo, patamares completos, rejeição numérica, tolerâncias menores que uma ULP e falhas síncronas/assíncronas de saída do CLI. Não são uma certificação numérica universal.

## Limitações e responsabilidade

Arredondamento binary64, cancelamento, deslocamentos de coordenadas e underflow continuam observáveis. A derivada é a do polinômio armazenado, não a de cada etapa de arredondamento/projeção. Igualdades acidentais da avaliação arredondada não expandem os patamares declarados. Não há aritmética de precisão arbitrária nem alegação ampla de conformidade com padrões.

Esta versão não valida as medições e não se destina a decisões clínicas ou financeiras, controle crítico de segurança, regressão, previsão, remoção de ruído, extrapolação ou garantias de implantação. Todos os exemplos são sintéticos. Não há telemetria, armazenamento persistente, relógio, estado mutável compartilhado nas curvas ou dados pessoais.

Consulte [CONTRIBUTING](CONTRIBUTING.md), [SECURITY](SECURITY.md) e [LICENSE](LICENSE). Contato geral pela [página oficial](https://lofranotecnologia.com.br).
