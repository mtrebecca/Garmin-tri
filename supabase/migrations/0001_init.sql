-- Esquema inicial do FuelUp: produtos, estratégias e registros de consumo vindos do relógio.

create table public.products (
  id uuid primary key default gen_random_uuid(),
  -- null = produto da biblioteca pública (pré-cadastrado); senão, produto do usuário.
  user_id uuid references auth.users on delete cascade,
  name text not null,
  brand text,
  carbs_g numeric not null check (carbs_g >= 0),
  sodium_mg numeric not null default 0 check (sodium_mg >= 0),
  volume_ml numeric not null default 0 check (volume_ml >= 0),
  created_at timestamptz not null default now()
);

create table public.strategies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null,
  sport text not null check (sport in ('run', 'bike')),
  duration_min int not null check (duration_min > 0),
  carbs_per_hour numeric not null check (carbs_per_hour > 0),
  -- Estratégia no formato compacto do relógio (docs/contrato-estrategia.md).
  watch_payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.consumption_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  strategy_id uuid references public.strategies on delete set null,
  -- Id gerado no relógio; garante que reenvios após reconexão não dupliquem (US-018).
  client_event_id text not null,
  item_index int not null,
  action text not null check (action in ('taken', 'skipped', 'snoozed')),
  elapsed_sec int not null,
  occurred_at timestamptz not null,
  received_at timestamptz not null default now(),
  unique (user_id, client_event_id)
);

create index on public.strategies (user_id, created_at desc);
create index on public.consumption_logs (user_id, strategy_id);

alter table public.products enable row level security;
alter table public.strategies enable row level security;
alter table public.consumption_logs enable row level security;

create policy "ler biblioteca pública e produtos próprios" on public.products
  for select using (user_id is null or user_id = auth.uid());
create policy "gerenciar produtos próprios" on public.products
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "gerenciar estratégias próprias" on public.strategies
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "gerenciar registros próprios" on public.consumption_logs
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
