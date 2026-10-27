-- Metas de hidratação e sódio, origem das metas e perfil do atleta (sugestões e teste de suor).

alter table public.strategies
  drop constraint strategies_carbs_per_hour_check,
  add constraint strategies_carbs_per_hour_check check (carbs_per_hour >= 0),
  add column fluid_ml_per_hour numeric not null default 0 check (fluid_ml_per_hour >= 0),
  add column sodium_mg_per_hour numeric not null default 0 check (sodium_mg_per_hour >= 0),
  -- suggested = aceitou a sugestão do app; sweat_test = líquido pela taxa de suor; custom = valores próprios.
  add column targets_source text not null default 'custom'
    check (targets_source in ('suggested', 'sweat_test', 'custom')),
  -- Temperatura prevista usada na sugestão (°C).
  add column temperature_c numeric;

create table public.profiles (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  sports text[] not null default '{}' check (sports <@ array['run', 'bike']),
  weight_kg numeric check (weight_kg > 0),
  sweat_rate_ml_per_hour int check (sweat_rate_ml_per_hour > 0),
  salty_sweater boolean not null default false,
  gut_trained boolean not null default false,
  updated_at timestamptz not null default now()
);

-- Histórico dos testes de suor; o mais recente alimenta profiles.sweat_rate_ml_per_hour.
create table public.sweat_tests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  tested_on date not null default current_date,
  duration_min int not null check (duration_min >= 30),
  weight_before_kg numeric not null check (weight_before_kg > 0),
  weight_after_kg numeric not null check (weight_after_kg > 0),
  fluid_intake_ml int not null default 0 check (fluid_intake_ml >= 0),
  urine_ml int not null default 0 check (urine_ml >= 0),
  temperature_c numeric,
  sweat_rate_ml_per_hour int not null check (sweat_rate_ml_per_hour > 0),
  created_at timestamptz not null default now()
);

create index on public.sweat_tests (user_id, tested_on desc);

alter table public.profiles enable row level security;
alter table public.sweat_tests enable row level security;

create policy "gerenciar perfil próprio" on public.profiles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "gerenciar testes de suor próprios" on public.sweat_tests
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
