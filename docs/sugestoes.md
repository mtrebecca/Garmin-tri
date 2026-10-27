# Sugestões de metas

Implementado em `packages/core/src/suggest.ts`. As faixas são **ponto de partida editável**,
baseadas em diretrizes gerais de nutrição esportiva. O FuelUp não faz prescrição individualizada.

> ⚠️ Antes da publicação, revisar os números com um nutricionista esportivo e conferir as fontes abaixo.

## Carboidrato (g/h)

| Duração | Faixa | Sugerido |
|---|---|---|
| < 60 min | 0–30 | 0 |
| 60–89 min | 30–60 | 45 |
| 90–150 min | 30–60 | 60 |
| > 150 min | 60–90 | 60, ou 90 com intestino treinado |

Acima de 60 g/h é preciso misturar glicose e frutose. Na corrida, avisar que o desconforto gastrointestinal é mais comum.

## Líquido (ml/h)

| Situação | Faixa | Sugerido |
|---|---|---|
| Com taxa de suor (teste) | 50%–100% da taxa (máx. 1200) | 75% da taxa |
| Calor (≥ 25 °C) | 500–800 | 650 |
| Frio (< 10 °C) | 300–500 | 400 |
| Demais | 400–600 | 500 |

Em treinos com menos de 1 h e sem calor, sugere 0 (“beba conforme a sede”).
Nunca sugerir beber mais do que se perde no suor, por risco de hiponatremia.

## Sódio (mg/h)

| Situação | Faixa | Sugerido |
|---|---|---|
| Normal | 300–600 | 400 |
| Calor ou suor salgado | 500–1000 | 700 |

Em treinos com menos de 1 h, sugere 0.

## Teste de suor

```
taxa (ml/h) = ((peso antes − peso depois) × 1000 + líquido ingerido − urina) / horas
```

Fazer em treino de pelo menos 30 min (o ideal é 1 h), no ritmo e no clima típicos. Pesar sem roupa e seco.
Repetir em climas diferentes, porque a taxa muda bastante com o calor.

## Fontes para revisão

- ACSM, Academy of Nutrition and Dietetics e Dietitians of Canada: *Nutrition and Athletic Performance*
  (posicionamento conjunto, 2016).
- ACSM: *Exercise and Fluid Replacement* (posicionamento, 2007).
- Jeukendrup, A. *A step towards personalized sports nutrition: carbohydrate intake during exercise*.
  Sports Medicine, 2014.
