-- Data Field (ADR 0002): consumo não confirmado e origem de cada registro.

alter table public.consumption_logs
  drop constraint consumption_logs_action_check,
  add constraint consumption_logs_action_check
    check (action in ('taken', 'skipped', 'snoozed', 'missed')),
  -- button = botão no Device App; auto = alerta sem ação; lap = LAP no Data Field;
  -- phone = corrigido no celular depois do treino.
  add column confirmed_by text not null default 'button'
    check (confirmed_by in ('button', 'auto', 'lap', 'phone')),
  add column edited_at timestamptz;
