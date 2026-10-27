import { generateSchedule, ScheduleError, toWatchStrategy } from './schedule';
import type { Product } from './types';

const gel: Product = { id: 'gel', name: 'Gel 25g', carbsG: 25, sodiumMg: 50, volumeMl: 0 };
const drink: Product = { id: 'iso', name: 'Isotônico 500ml', carbsG: 30, sodiumMg: 300, volumeMl: 500 };
const water: Product = { id: 'agua', name: 'Água 150ml', carbsG: 0, sodiumMg: 0, volumeMl: 150 };
const salt: Product = { id: 'sal', name: 'Cápsula de sal', carbsG: 0, sodiumMg: 250, volumeMl: 0 };

describe('generateSchedule', () => {
  it('distribui géis para bater a meta por hora', () => {
    const s = generateSchedule({ durationMin: 120, targets: { carbsPerHour: 60 }, products: [gel] });

    expect(s.items.map((i) => i.atMin)).toEqual([15, 38, 63, 88]);
    expect(s.totals).toEqual({ carbsG: 100, sodiumMg: 200, volumeMl: 0 });
    expect(s.perHourPlanned.carbsG).toBe(50);
  });

  it('alterna produtos equivalentes', () => {
    const gel2 = { ...gel, id: 'gel2' };
    const s = generateSchedule({ durationMin: 150, targets: { carbsPerHour: 60 }, products: [gel, gel2] });

    expect(s.items.map((i) => i.product.id)).toEqual(['gel', 'gel2', 'gel', 'gel2', 'gel', 'gel2']);
  });

  it('combina gel e água para bater carboidrato e líquido', () => {
    const s = generateSchedule({
      durationMin: 180,
      targets: { carbsPerHour: 60, fluidMlPerHour: 450 },
      products: [gel, water],
    });

    expect(s.items.some((i) => i.product.id === 'gel')).toBe(true);
    expect(s.items.some((i) => i.product.id === 'agua')).toBe(true);
    expect(s.perHourPlanned.carbsG).toBeGreaterThanOrEqual(45);
    expect(s.perHourPlanned.volumeMl).toBeGreaterThanOrEqual(350);
  });

  it('combina produtos no mesmo horário para bater as três metas', () => {
    const s = generateSchedule({
      durationMin: 180,
      targets: { carbsPerHour: 60, fluidMlPerHour: 650, sodiumMgPerHour: 700 },
      products: [gel, water, salt],
    });

    expect(s.perHourPlanned.carbsG).toBeGreaterThanOrEqual(50);
    expect(s.perHourPlanned.volumeMl).toBeGreaterThanOrEqual(550);
    expect(s.perHourPlanned.sodiumMg).toBeGreaterThanOrEqual(550);
    const minutes = s.items.map((i) => i.atMin);
    expect(new Set(minutes).size).toBeLessThan(minutes.length);
  });

  it('inclui cápsula de sal quando há meta de sódio', () => {
    const s = generateSchedule({
      durationMin: 180,
      targets: { carbsPerHour: 60, sodiumMgPerHour: 500 },
      products: [gel, salt],
    });

    expect(s.items.some((i) => i.product.id === 'sal')).toBe(true);
    expect(s.perHourPlanned.sodiumMg).toBeGreaterThanOrEqual(350);
  });

  it('ignora produtos que não contribuem para nenhuma meta', () => {
    const s = generateSchedule({ durationMin: 120, targets: { carbsPerHour: 60 }, products: [water, gel] });

    expect(s.items.every((i) => i.product.id === 'gel')).toBe(true);
  });

  it('respeita o intervalo mínimo mesmo com metas altas', () => {
    const s = generateSchedule({
      durationMin: 180,
      targets: { carbsPerHour: 120, fluidMlPerHour: 800, sodiumMgPerHour: 800 },
      products: [gel, drink, water, salt],
    });
    const minutes = [...new Set(s.items.map((i) => i.atMin))];
    const gaps = minutes.slice(1).map((m, i) => m - minutes[i]!);

    expect(gaps.every((g) => g >= 10)).toBe(true);
  });

  it('não agenda nada em treino mais curto que a janela', () => {
    const s = generateSchedule({ durationMin: 20, targets: { carbsPerHour: 60 }, products: [gel] });

    expect(s.items).toEqual([]);
    expect(s.perHourPlanned).toEqual({ carbsG: 0, sodiumMg: 0, volumeMl: 0 });
  });

  it.each([
    [{ durationMin: 0, targets: { carbsPerHour: 60 }, products: [gel] }],
    [{ durationMin: 60, targets: { carbsPerHour: 200 }, products: [gel] }],
    [{ durationMin: 60, targets: { carbsPerHour: 60, fluidMlPerHour: -1 }, products: [gel] }],
    [{ durationMin: 60, targets: { carbsPerHour: 0 }, products: [gel] }],
    [{ durationMin: 60, targets: { carbsPerHour: 60 }, products: [] }],
    [{ durationMin: 60, targets: { carbsPerHour: 60 }, products: [{ ...gel, carbsG: 0, sodiumMg: 0 }] }],
  ])('rejeita entrada inválida %#', (input) => {
    expect(() => generateSchedule(input)).toThrow(ScheduleError);
  });
});

describe('toWatchStrategy', () => {
  it('gera o formato compacto em segundos e corta nomes longos', () => {
    const longName = { ...gel, name: 'Gel de carboidrato sabor morango 25g' };
    const s = generateSchedule({ durationMin: 60, targets: { carbsPerHour: 40 }, products: [longName] });
    const w = toWatchStrategy('abc', 'Longão de domingo com subidas', s);

    expect(w.name).toBe('Longão de domingo co');
    expect(w.items[0]).toEqual({ t: 19 * 60, p: 'Gel de carboidrato s', c: 25, na: 50, ml: 0 });
  });

  it('junta produtos do mesmo minuto em um alerta', () => {
    const w = toWatchStrategy('abc', 'Teste', {
      items: [
        { atMin: 15, product: gel },
        { atMin: 15, product: water },
        { atMin: 25, product: salt },
      ],
      totals: { carbsG: 25, sodiumMg: 300, volumeMl: 150 },
      perHourPlanned: { carbsG: 0, sodiumMg: 0, volumeMl: 0 },
    });

    expect(w.items).toEqual([
      { t: 900, p: 'Gel 25g+Água 150ml', c: 25, na: 50, ml: 150 },
      { t: 1500, p: 'Cápsula de sal', c: 0, na: 250, ml: 0 },
    ]);
  });
});
