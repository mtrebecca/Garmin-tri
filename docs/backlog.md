# Backlog do MVP

Prioridade (MoSCoW): **M** must · **S** should · **C** could.
Status: ⬜ não iniciado · 🟨 em andamento · ✅ pronto · 🧪 pronto no `core`, falta tela/relógio.

Fluxo central: **configurar no celular → sincronizar com o Garmin → executar o treino →
registrar consumo → ver métricas no celular.**

## Épico 1 — Autenticação e perfil

| ID | História | Prior. | Status |
|---|---|---|---|
| US-001 | Criar conta e acessar histórico | M | ⬜ |
| US-002 | Configurar modalidades (corrida, ciclismo) | M | 🟨 tabela `profiles` |
| US-003 | Vincular dispositivo Garmin | M | ⬜ decidir no POC (ADR 0001) |
| US-019 | Informar perfil para sugestões: peso, suor salgado, intestino treinado | M | 🟨 tabela `profiles` |

## Épico 2 — Planejamento nutricional

| ID | História | Prior. | Status |
|---|---|---|---|
| US-004 | Cadastrar produtos com carboidrato, sódio e volume | M | 🟨 tabela `products` |
| US-005 | Informar duração prevista e temperatura do treino | M | ⬜ |
| US-006 | Definir metas de carboidrato, líquido e sódio por hora | M | 🧪 |
| US-020 | **Receber sugestão de metas do app** | M | 🧪 `suggestTargets` |
| US-021 | **Fazer o teste de suor** e usar a taxa nas metas de líquido | S | 🧪 `sweatRateFromTest` |
| US-022 | **Personalizar as metas** (editar a sugestão ou digitar valores próprios) | M | ⬜ |
| US-007 | Ver o cronograma de consumo com as três metas | M | 🧪 `generateSchedule` |
| US-023 | Editar o cronograma gerado (mover, trocar ou remover item) | S | ⬜ |

### Critérios de aceite

**US-020 — Sugestão de metas**
- Com modalidade, duração e (opcional) temperatura, o app mostra faixa mínima–máxima e um valor
  sugerido para carboidrato (g/h), líquido (ml/h) e sódio (mg/h).
- Usa o perfil: suor salgado aumenta o sódio; intestino treinado permite sugerir até 90 g/h.
- Mostra as observações (ex.: “acima de 60 g/h use glicose + frutose”).
- Sempre exibe o aviso: “Sugestão geral, não é prescrição. Ajuste com seu nutricionista.”
- A estratégia salva registra a origem das metas (`targets_source`).

**US-021 — Teste de suor**
- O app guia o teste: pesar antes e depois (sem roupa molhada), anotar o que bebeu e a urina.
- Calcula a taxa em ml/h, guarda o histórico (`sweat_tests`) e atualiza o perfil.
- Rejeita valores implausíveis: teste com menos de 30 min ou diferença de peso acima de 10%.
- A sugestão de líquido passa a usar a taxa, sem sugerir beber mais do que se perde.

**US-022 — Metas personalizadas**
- Cada meta pode ser editada livremente dentro de limites de segurança
  (carbo 0–150 g/h, líquido 0–1500 ml/h, sódio 0–2000 mg/h).
- O app mostra a faixa sugerida ao lado do valor escolhido, sem bloquear valores fora dela.
- Meta zerada é ignorada no cronograma (ex.: só carboidrato).

**US-007 — Cronograma**
- O cronograma combina os produtos escolhidos para se aproximar das três metas.
- Produtos podem ser combinados no mesmo horário (ex.: gel + água) e viram um único alerta no relógio.
- Mostra o total e a média por hora planejados ao lado das metas.

## Épico 3 — Execução no Garmin

| ID | História | Prior. | Status |
|---|---|---|---|
| US-026 | Rodar dentro da atividade nativa sem ocupar o visor (Data Field, ADR 0002) | M | 🟨 código pronto, validar no FR255 |
| US-008 | Receber lembretes durante a atividade | M | 🟨 código pronto, validar no FR255 |
| US-009 | Confirmar o consumo: automático (padrão) ou com LAP, conforme configuração | M | 🟨 código pronto, validar no FR255 |
| US-010 | Consultar o próximo consumo | M | 🟨 código pronto, validar no FR255 |
| US-011 | Operar offline e sobreviver ao fechamento do app | S | 🟨 código pronto, validar no FR255 |

**US-011 — Continuar treino interrompido**
- O progresso do plano é salvo a cada ação e a cada 30 s.
- Ao reabrir, o relógio mostra “Treino interrompido” e o tempo corrido; START abre
  “Continuar plano” ou “Novo treino”.
- Continuar segue do próximo consumo, soma o tempo já corrido e mantém os ids dos registros estáveis.
- Limitação do Connect IQ: a gravação não pode ser retomada. Se o app fechar normalmente, a parte
  gravada é salva e a continuação vira uma segunda atividade. Se o app travar, a parte gravada se perde,
  mas o plano e os registros de consumo continuam salvos.

**US-026 / US-009 — Data Field e confirmação**
- O atleta inicia a atividade nativa; o campo FuelUp fica numa tela extra e mostra a contagem.
- No horário, vibra e mostra o alerta por cima da tela atual, que some sozinho.
- Configuração “Confirmar consumo com LAP”: desligada, o alerta conta como consumido; ligada,
  LAP em até 2 min confirma e sem LAP fica como não realizado.
- Cada registro guarda a origem (`auto`, `lap`, `button`, `phone`).

**US-027 — Corrigir no celular**
- Depois da sincronização, o app lista os alertas do treino com o status de cada um.
- O atleta marca o que consumiu ou não; a alteração grava `confirmed_by = 'phone'` e `edited_at`.
- As métricas mostram quantos registros foram presumidos (`auto`) e não corrigidos.

## Épico 4 — Histórico e métricas

| ID | História | Prior. | Status |
|---|---|---|---|
| US-012 | Consultar sessões anteriores | S | ⬜ |
| US-013 | Comparar planejado × realizado (carbo, líquido e sódio) | S | ⬜ |
| US-014 | Ver consumo por hora em gráficos | S | ⬜ |
| US-015 | Identificar consumos pulados ou adiados e quando aconteceram | S | ⬜ |
| US-027 | Corrigir no celular, após o treino, o que foi ou não consumido | M | 🟨 coluna `confirmed_by` |
| US-024 | Ver evolução: média de g/h atingida e taxa de cumprimento do plano | S | ⬜ |
| US-025 | Cruzar consumo com ritmo e FC do treino (Garmin/Strava) | C | ⬜ |

## Épico 5 — Sincronização

| ID | História | Prior. | Status |
|---|---|---|---|
| US-016 | Enviar a estratégia para o relógio | M | ⬜ |
| US-017 | Sincronizar o consumo com o celular | M | ⬜ |
| US-018 | Evitar duplicidades após reconexão | M | 🟨 `unique (user_id, client_event_id)` |

## Fora do MVP

Strava (C), biblioteca de produtos brasileiros (C), compartilhamento (C).
Rede social, marketplace, IA nutricional e assinaturas ficam fora do MVP.

## Próximos passos de desenvolvimento

1. POC do relógio no FR255 (ver [poc.md](poc.md)): ambiente, alertas e modo offline.
2. ~~Salvar o progresso da sessão no relógio (US-011)~~ — código pronto, entra no teste do POC.
3. Edge Function no Supabase e `makeWebRequest` no relógio (US-016, US-017).
4. App mobile: login → perfil → sugestão/teste de suor → metas → produtos → cronograma → enviar.
5. Métricas: planejado × realizado e gráficos por hora.
