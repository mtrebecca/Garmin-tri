# FuelUp

Planejamento e execução de alimentação e hidratação para atletas de endurance:
estratégia no celular → alertas e confirmação no Garmin → planejado vs. realizado no histórico.

## Estrutura

```
apps/garmin-field  Data Field Connect IQ: roda dentro da atividade nativa (modo principal, ADR 0002)
apps/garmin      Device App Connect IQ: atividade própria com botões (alternativa)
apps/mobile      App Expo (iOS/Android) — começa depois do POC
packages/core    Lógica compartilhada em TS (sugestões, teste de suor, cronograma, formato do relógio)
supabase         Migrações do banco
docs             Backlog, POC, decisões (adr/), contrato de dados, regras de sugestão, pesquisa
```

## Começando

### Core (TypeScript)

```sh
pnpm install
pnpm test
```

### Relógio (Connect IQ)

1. Baixe o **SDK Manager** em <https://developer.garmin.com/connect-iq/sdk/>, instale o SDK mais recente
   e o dispositivo **Forerunner 255**.
2. No VS Code, instale a extensão **Monkey C** (Garmin).
3. `Ctrl+Shift+P` → **Monkey C: Verify Installation** e depois **Monkey C: Generate a Developer Key**.
4. Abra a pasta `apps/garmin-field` (ou `apps/garmin`) e use **Run → Run Without Debugging**, escolhendo `fr255`.
   No simulador: **Settings → Activity Data** para simular GPS e FC.
5. No relógio real: **Monkey C: Build for Device** → `fr255`, conecte o FR255 via USB e copie o `.prg`
   gerado para `GARMIN\APPS`.

Data Field: no relógio, em **Corrida (ou Ciclismo) → Configurações → Telas de dados**, adicione uma tela
de **1 campo** e escolha **Connect IQ → FuelUp**: ela vira uma tela a mais na sequência, com próximo consumo,
contagem e consumido × planejado. Num espaço pequeno de outra tela, o campo mostra só a contagem. No alerta, se
"Confirmar consumo com LAP" estiver ligado (configurações do app no Garmin Connect), aperte **LAP**.
No simulador: inicie a atividade em **Settings → Activity Data** (os alertas de teste vêm aos 1, 3 e 5 min).

Device App, botões no alerta: **START** consumi · **DOWN** +5 min · **BACK** pular.

## Status

POC em andamento — ver [docs/poc.md](docs/poc.md) e [ADR 0001](docs/adr/0001-device-app-e-sync-via-backend.md).
Backlog e próximos passos em [docs/backlog.md](docs/backlog.md).

> As metas nutricionais são definidas pelo usuário. O FuelUp não faz prescrição individualizada.
