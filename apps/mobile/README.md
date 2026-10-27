# FuelUp mobile

App Expo (SDK 58, Expo Router) para iOS e Android. A lógica de sugestões, teste de suor,
cronograma e métricas vem de `@fuelup/core`.

```sh
pnpm install          # na raiz do repositório
cd apps/mobile
npx expo start        # abra no Expo Go (QR code) ou pressione w para a web
pnpm typecheck
```

## Telas

- **Plano** (`src/app/index.tsx`): modalidade, duração, temperatura e perfil → metas sugeridas
  (editáveis, com “Voltar à sugestão”) → produtos → cronograma com alertas combinados.
- **Histórico** (`src/app/historico.tsx`): planejado × realizado, carboidrato por hora e status de
  cada consumo. Por enquanto usa um treino de exemplo.

## Próximos passos

Login e dados no Supabase, cadastro de produtos (US-004), teste de suor (US-021), enviar ao relógio
(US-016) e corrigir consumos no histórico (US-027). Formulários com React Hook Form + Zod e dados com
TanStack Query entram junto com o Supabase.
