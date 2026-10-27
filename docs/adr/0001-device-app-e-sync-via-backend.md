# ADR 0001: Device App no relógio e sincronização via backend

**Status:** proposta (validar no POC)
**Data:** 2026-10-26

## Contexto

- O FR255 não tem tela de toque: toda interação é pelos botões.
- O diferencial do produto é confirmar o consumo, e um Data Field não recebe botões.
- O desenvolvimento é em Windows com iPhone. Um módulo nativo React Native para o SDK
  mobile do Garmin exigiria Mac/Xcode para depurar no iOS.

## Decisão

1. **Device App (watch-app)** que grava a própria atividade (`ActivityRecording`), com alertas
   persistentes e confirmação por botão.
2. **O relógio fala direto com o backend** (`Communications.makeWebRequest`, que passa pelo app
   Garmin Connect no celular): baixa a estratégia antes do treino e envia os registros depois.
   Durante o treino tudo é offline (`Application.Storage`).
3. O app mobile (Expo) só conversa com o Supabase. Não há ponte nativa celular ⇄ relógio no MVP.

## Consequências

- ✅ Mobile pode usar Expo Go no início; nada de Mac.
- ✅ Um único caminho de sincronização para testar.
- ❌ O atleta não usa a atividade nativa "Corrida" e as telas de métricas precisam ser recriadas.
- ❌ Sincronizar exige o celular por perto com o Garmin Connect aberto em segundo plano.
- ❓ Vínculo de conta no relógio: código curto nas configurações do app ou OAuth. Decidir no POC.

## Plano B

Se `makeWebRequest` não for viável, usar `Communications.transmit` + SDK mobile do Garmin
via módulo nativo Expo (exige build nativo do iOS).
