# FuelUp

Planejamento e execução de alimentação e hidratação para atletas de endurance:
estratégia no celular → alertas e confirmação no Garmin → planejado vs. realizado no histórico.

## Estrutura

```
apps/garmin      App Connect IQ (Monkey C) — Forerunner 255 primeiro
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
4. Abra a pasta `apps/garmin` e use **Run → Run Without Debugging**, escolhendo `fr255`.
   No simulador: **Settings → Activity Data** para simular GPS e FC.
5. No relógio real: **Monkey C: Build for Device** → `fr255`, conecte o FR255 via USB e copie o `.prg`
   gerado para `GARMIN\APPS`.

Botões no alerta: **START** consumi · **DOWN** +5 min · **BACK** pular.

## Status

POC em andamento — ver [docs/poc.md](docs/poc.md) e [ADR 0001](docs/adr/0001-device-app-e-sync-via-backend.md).
Backlog e próximos passos em [docs/backlog.md](docs/backlog.md).

> As metas nutricionais são definidas pelo usuário. O FuelUp não faz prescrição individualizada.
