# POC — semanas 1 e 2

Objetivo: provar no FR255 real o fluxo crítico antes de construir o app mobile.
Cada etapa só começa quando a anterior passar. Anote problemas em "Achados".

- [ ] **0. Ambiente**: Connect IQ SDK, extensão Monkey C, chave de desenvolvedor, projeto Supabase.
- [ ] **1. Hello World no relógio**: rodar no simulador (`fr255`) e instalar no FR255 real.
- [ ] **2. Alerta persistente**: com a estratégia de teste (alertas aos 1, 3 e 5 min), conferir:
  - [ ] vibração + bipe e repetição a cada 15 s até agir
  - [ ] START = consumi, DOWN = +5 min, BACK = pular
  - [ ] atividade salva aparece no Garmin Connect (e no Strava) como corrida, com GPS e FC
- [ ] **3. Offline**: registros sobrevivem com o Bluetooth desligado e após fechar o app.
- [ ] **4. Backend**: relógio baixa a estratégia do Supabase e envia os registros (token fixo no POC).
- [ ] **5. Sem duplicidade**: reenviar os mesmos registros gera só uma linha por evento.
- [ ] **Teste final**: corrida real de 30–60 min com 3 alertas e registros no banco.

## Achados

| Data | Etapa | O que aconteceu | Decisão |
|---|---|---|---|
| | | | |
