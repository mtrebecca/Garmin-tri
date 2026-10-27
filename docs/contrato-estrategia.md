# Contrato: estratégia e registros (celular ⇄ backend ⇄ relógio)

O relógio tem pouca memória, então o formato é compacto e o relógio **não calcula nada**:
toda a lógica fica em `packages/core` (`generateSchedule` + `toWatchStrategy`).

## Estratégia (backend → relógio)

```json
{
  "v": 1,
  "id": "uuid-da-estrategia",
  "name": "Longão 2h",
  "items": [
    { "t": 900,  "p": "Gel 25g",         "c": 25, "na": 50,  "ml": 0 },
    { "t": 2400, "p": "Isotônico 500ml", "c": 30, "na": 300, "ml": 500 }
  ]
}
```

| Campo | Significado |
|---|---|
| `v` | Versão do formato |
| `t` | Segundos de **timer** desde o início (pausas não contam) |
| `p` | Nome do produto, até 20 caracteres |
| `c` / `na` / `ml` | Carboidrato (g), sódio (mg), volume (ml), inteiros |

Produtos combinados no mesmo minuto (ex.: gel + água) chegam como **um item só**, com nomes
unidos por `+` (cortados em 20 caracteres) e nutrientes somados. Qualquer campo pode ser 0
(água tem só `ml`; cápsula de sal tem só `na`).

## Registro de consumo (relógio → backend)

```json
{ "id": "1761480000-0-1", "sid": "uuid-da-estrategia", "i": 0, "a": "taken", "t": 905, "ts": 1761480905 }
```

| Campo | Significado | Coluna em `consumption_logs` |
|---|---|---|
| `id` | `<início da sessão>-<índice>-<sequência>`, estável | `client_event_id` |
| `sid` | Id da estratégia | `strategy_id` |
| `i` | Índice do item na estratégia | `item_index` |
| `a` | `taken`, `skipped` ou `snoozed` | `action` |
| `t` | Segundos de timer no momento da ação | `elapsed_sec` |
| `ts` | Unix time da ação | `occurred_at` |

O envio é um upsert por `(user_id, client_event_id)`, então reenviar é seguro.
Itens sem nenhum registro `taken`/`skipped` ao final contam como **não realizados** (US-015).
