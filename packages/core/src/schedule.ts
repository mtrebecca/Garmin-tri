import type { Nutrients, Product, Schedule, ScheduleInput, ScheduledItem, WatchItem, WatchStrategy } from './types';

const MAX_DURATION_MIN = 24 * 60;
const MAX_CARBS_PER_HOUR = 150;
const MAX_FLUID_ML_PER_HOUR = 1500;
const MAX_SODIUM_MG_PER_HOUR = 2000;
const WATCH_NAME_MAX = 20;

export class ScheduleError extends Error {}

/**
 * Gera o cronograma de consumo a partir das metas por hora (carboidrato, líquido, sódio).
 *
 * A cada minuto compara as metas acumuladas com o que já foi planejado e mede o
 * erro somando o déficit de cada meta, normalizado pela meta por hora (assim
 * gramas, ml e mg pesam igual). Agenda o produto que mais reduz esse erro, se
 * algum reduzir. Com uma só meta e um só produto, isso equivale a consumir quando
 * o déficit passa da metade da porção, o que mantém o consumo centrado na meta.
 * Em empate, prefere o produto usado há mais tempo, para variar.
 *
 * No mesmo minuto pode combinar produtos diferentes (ex.: gel + água), enquanto
 * cada um continuar reduzindo o erro; senão, com intervalo mínimo entre consumos,
 * várias metas disputariam os mesmos horários e nenhuma seria atingida.
 */
export function generateSchedule(input: ScheduleInput): Schedule {
  validate(input);

  const startAfter = input.startAfterMin ?? 15;
  const lastMinute = input.durationMin - (input.stopBeforeEndMin ?? 10);
  const minInterval = input.minIntervalMin ?? 10;
  const goals = activeGoals(input);

  const items: ScheduledItem[] = [];
  const planned: Nutrients = { carbsG: 0, sodiumMg: 0, volumeMl: 0 };
  const lastUsed = input.products.map(() => -Infinity);
  let lastAt = -Infinity;

  for (let t = startAfter; t <= lastMinute; t++) {
    if (t - lastAt < minInterval) continue;

    const error = (extra?: Product) =>
      goals.reduce((sum, [key, perHour]) => {
        const deficit = (perHour * t) / 60 - planned[key] - (extra?.[key] ?? 0);
        return sum + (deficit / perHour) ** 2;
      }, 0);

    const byLeastRecent = input.products
      .map((_, i) => i)
      .sort((a, b) => lastUsed[a]! - lastUsed[b]!);

    for (;;) {
      let best = -1;
      let bestError = error();
      for (const i of byLeastRecent) {
        if (lastUsed[i] === t) continue;
        const e = error(input.products[i]);
        if (e < bestError) {
          best = i;
          bestError = e;
        }
      }
      if (best < 0) break;

      const product = input.products[best]!;
      items.push({ atMin: t, product });
      planned.carbsG += product.carbsG;
      planned.sodiumMg += product.sodiumMg;
      planned.volumeMl += product.volumeMl;
      lastUsed[best] = t;
      lastAt = t;
    }
  }

  const perHour = (total: number) => Math.round((total / input.durationMin) * 60);
  return {
    items,
    totals: planned,
    perHourPlanned: {
      carbsG: perHour(planned.carbsG),
      sodiumMg: perHour(planned.sodiumMg),
      volumeMl: perHour(planned.volumeMl),
    },
  };
}

/** Itens do mesmo minuto viram um único alerta no relógio (ex.: "Gel 25g+Água 150ml"). */
export function toWatchStrategy(id: string, name: string, schedule: Schedule): WatchStrategy {
  const items: WatchItem[] = [];
  let names: string[] = [];
  for (const { atMin, product } of schedule.items) {
    let item = items[items.length - 1];
    if (item?.t !== atMin * 60) {
      item = { t: atMin * 60, p: '', c: 0, na: 0, ml: 0 };
      items.push(item);
      names = [];
    }
    names.push(product.name);
    item.p = names.join('+').slice(0, WATCH_NAME_MAX);
    item.c += Math.round(product.carbsG);
    item.na += Math.round(product.sodiumMg);
    item.ml += Math.round(product.volumeMl);
  }
  return { v: 1, id, name: name.slice(0, WATCH_NAME_MAX), items };
}

function activeGoals(input: ScheduleInput): [keyof Nutrients, number][] {
  const { carbsPerHour, fluidMlPerHour = 0, sodiumMgPerHour = 0 } = input.targets;
  const goals: [keyof Nutrients, number][] = [
    ['carbsG', carbsPerHour],
    ['volumeMl', fluidMlPerHour],
    ['sodiumMg', sodiumMgPerHour],
  ];
  return goals.filter(([, perHour]) => perHour > 0);
}

function validate(input: ScheduleInput): void {
  if (!(input.durationMin > 0 && input.durationMin <= MAX_DURATION_MIN)) {
    throw new ScheduleError(`Duração deve estar entre 1 e ${MAX_DURATION_MIN} minutos.`);
  }
  const { carbsPerHour, fluidMlPerHour = 0, sodiumMgPerHour = 0 } = input.targets;
  if (!(carbsPerHour >= 0 && carbsPerHour <= MAX_CARBS_PER_HOUR)) {
    throw new ScheduleError(`Meta de carboidrato deve estar entre 0 e ${MAX_CARBS_PER_HOUR} g/h.`);
  }
  if (!(fluidMlPerHour >= 0 && fluidMlPerHour <= MAX_FLUID_ML_PER_HOUR)) {
    throw new ScheduleError(`Meta de líquido deve estar entre 0 e ${MAX_FLUID_ML_PER_HOUR} ml/h.`);
  }
  if (!(sodiumMgPerHour >= 0 && sodiumMgPerHour <= MAX_SODIUM_MG_PER_HOUR)) {
    throw new ScheduleError(`Meta de sódio deve estar entre 0 e ${MAX_SODIUM_MG_PER_HOUR} mg/h.`);
  }
  if (activeGoals(input).length === 0) {
    throw new ScheduleError('Defina ao menos uma meta.');
  }
  if (input.products.length === 0) {
    throw new ScheduleError('Informe ao menos um produto.');
  }
  const invalid = input.products.find(
    (p) =>
      !(p.carbsG >= 0 && p.sodiumMg >= 0 && p.volumeMl >= 0) ||
      p.carbsG + p.sodiumMg + p.volumeMl === 0,
  );
  if (invalid) {
    throw new ScheduleError(`Produto "${invalid.name}" precisa de carboidrato, sódio ou volume.`);
  }
}
