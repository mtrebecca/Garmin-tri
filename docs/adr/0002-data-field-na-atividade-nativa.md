# ADR 0002: Data Field dentro da atividade nativa

**Status:** proposta (validar no POC) · substitui o item 1 da ADR 0001
**Data:** 2026-10-27

## Contexto

- O atleta quer iniciar a Corrida, o Ciclismo ou o Triathlon nativos do Garmin e ter o FuelUp
  rodando em segundo plano, aparecendo só na hora do alerta.
- O Connect IQ não deixa um Device App rodar por cima de uma atividade nativa. O único tipo que
  roda dentro dela é o **Data Field**.
- Um Data Field não recebe botões, exceto o aviso de LAP (`onTimerLap`).

## Decisão

1. O modo principal é um **Data Field** (`apps/garmin-field`). O atleta coloca o campo numa tela
   extra da atividade; ele mostra só a contagem para o próximo consumo.
2. Na hora do consumo, o campo vibra e abre um alerta (`DataField.showAlert`) por cima da tela
   atual, que o sistema fecha sozinho.
3. O registro é configurável (`confirmWithLap`, nas configurações do app no Garmin Connect):
   - **desligado (padrão):** alerta sem ação conta como consumido (`by: "auto"`);
   - **ligado:** LAP em até 2 min confirma (`by: "lap"`); sem LAP vira `missed`.
4. O app do celular permite corrigir os registros depois do treino (`by: "phone"`).
5. O Device App (`apps/garmin`) fica como alternativa até o teste no relógio decidir.
6. **Em quais atividades atua** (`enabled`, `activeRun`, `activeBike`, `activeSwim`, `activeOther`):
   o atleta adiciona a tela do FuelUp uma vez em cada atividade; o campo lê o esporte
   (`Activity.getProfileInfo`) e só alerta e registra nas marcadas. Nas demais mostra “inativo”.
   Por enquanto as opções ficam nas configurações do app no Garmin Connect; depois o app FuelUp
   do celular as envia junto com a estratégia.
7. **Posição da tela:** nenhum app Connect IQ pode criar telas de dados nem mudar a ordem delas.
   O app do celular vai guiar o atleta a colocar o FuelUp como última tela, logo antes do relógio.
8. **Visual:** foco em tempo, carboidrato e hidratação. Contagem grande até o próximo consumo, o
   produto e dois anéis na borda: laranja (carboidrato) e azul (hidratação), com os totais
   consumido / planejado. No modo padrão os totais sobem sozinhos a cada alerta, sem clique.
   Distância e FC ficam nas telas nativas.

## Consequências

- ✅ Mantém treinos estruturados, alertas nativos, métricas, Training Effect e multiesporte.
- ✅ Não ocupa o visor principal.
- ❌ Sem “pular” e “+5 min” no relógio; o LAP de confirmação cria uma volta extra na atividade.
- ❌ No modo automático, o “realizado” é presumido até o atleta corrigir no celular.
- ❓ Sincronização: um Data Field não chama a internet direto; precisa de serviço em segundo
  plano (`Background`) ou receber a estratégia pelas configurações do app. Decidir no POC.
- ❓ Validar no FR255: o alerta aparece com a tela do campo fora de vista? Quanto tempo fica?
  Vibração é permitida em Data Field? (Memória: 11,5 de 252,5 KB no simulador do FR255 Music.)
