# FuelUp mobile

Será criado no passo 3, depois que o POC do relógio passar (ver `docs/poc.md`):

```sh
pnpm create expo-app@latest . --template tabs
```

Stack: Expo + Expo Router, TypeScript, Zustand, TanStack Query, React Hook Form + Zod, Supabase.
A lógica de sugestões, teste de suor e cronograma vem de `@fuelup/core`.

Fluxo principal: login → perfil → sugestão de metas (ou teste de suor, ou valores próprios) →
produtos → cronograma → enviar ao relógio → métricas planejado × realizado.
