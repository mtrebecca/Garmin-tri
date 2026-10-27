import type { ConsumptionLog, ItemOutcome, Nutrients, SessionSummary, WatchItem, WatchStrategy } from './types';

const TERMINAL = new Set(['taken', 'skipped', 'missed']);

/**
 * Planejado × realizado de um treino, a partir da estratégia enviada ao relógio e dos registros.
 *
 * O status de cada item é o último registro final (taken, skipped, missed) por horário da ação;
 * correções feitas no celular depois do treino vencem por serem mais recentes. Item sem registro
 * final conta como não realizado (US-015). Adiamentos (snoozed) só entram na contagem.
 */
export function summarizeSession(
  strategy: WatchStrategy,
  logs: ConsumptionLog[],
  durationSec?: number,
): SessionSummary {
  const ours = logs.filter((l) => l.sid === strategy.id).sort((a, b) => a.ts - b.ts);

  const items: ItemOutcome[] = strategy.items.map((item, index) => {
    const forItem = ours.filter((l) => l.i === index);
    const final = forItem.filter((l) => TERMINAL.has(l.a)).pop();
    const snoozes = forItem.filter((l) => l.a === 'snoozed').length;
    if (!final) {
      return { index, item, status: 'missed', snoozes };
    }
    const outcome: ItemOutcome = { index, item, status: final.a as ItemOutcome['status'], by: final.by ?? 'button', snoozes };
    if (final.a === 'taken') {
      outcome.takenAtSec = final.t;
      outcome.delaySec = final.t - item.t;
    }
    return outcome;
  });

  const taken = items.filter((o) => o.status === 'taken');
  const lastSec = Math.max(durationSec ?? 0, ...strategy.items.map((i) => i.t), ...taken.map((o) => o.takenAtSec!));
  const hours = Math.max(1, Math.ceil(lastSec / 3600));
  const byHour = Array.from({ length: hours }, (_, hour) => ({ hour, planned: zero(), taken: zero() }));

  for (const { item } of items) add(byHour[hourOf(item.t, hours)]!.planned, item);
  for (const o of taken) add(byHour[hourOf(o.takenAtSec!, hours)]!.taken, o.item);

  return {
    items,
    planned: sum(strategy.items),
    taken: sum(taken.map((o) => o.item)),
    compliance: items.length === 0 ? 1 : taken.length / items.length,
    presumed: taken.filter((o) => o.by === 'auto').length,
    byHour,
  };
}

function hourOf(sec: number, hours: number): number {
  return Math.min(hours - 1, Math.floor(sec / 3600));
}

function zero(): Nutrients {
  return { carbsG: 0, sodiumMg: 0, volumeMl: 0 };
}

function add(acc: Nutrients, item: WatchItem): void {
  acc.carbsG += item.c;
  acc.sodiumMg += item.na;
  acc.volumeMl += item.ml;
}

function sum(items: WatchItem[]): Nutrients {
  const acc = zero();
  items.forEach((i) => add(acc, i));
  return acc;
}
