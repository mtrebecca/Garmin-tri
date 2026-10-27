import { summarizeSession } from './metrics';
import type { ConsumptionLog, WatchStrategy } from './types';

const strategy: WatchStrategy = {
  v: 1,
  id: 's1',
  name: 'Longão',
  items: [
    { t: 900, p: 'Gel 25g', c: 25, na: 50, ml: 0 },
    { t: 2400, p: 'Água 150ml', c: 0, na: 0, ml: 150 },
    { t: 4500, p: 'Gel 25g', c: 25, na: 50, ml: 0 },
  ],
};

const log = (i: number, a: ConsumptionLog['a'], t: number, extra: Partial<ConsumptionLog> = {}): ConsumptionLog => ({
  id: `x-${i}-${t}`,
  sid: 's1',
  i,
  a,
  t,
  ts: 1_000_000 + t,
  ...extra,
});

describe('summarizeSession', () => {
  it('compara planejado e realizado', () => {
    const s = summarizeSession(strategy, [log(0, 'taken', 905), log(1, 'skipped', 2410), log(2, 'taken', 4520)]);

    expect(s.planned).toEqual({ carbsG: 50, sodiumMg: 100, volumeMl: 150 });
    expect(s.taken).toEqual({ carbsG: 50, sodiumMg: 100, volumeMl: 0 });
    expect(s.items.map((o) => o.status)).toEqual(['taken', 'skipped', 'taken']);
    expect(s.items[0]!.delaySec).toBe(5);
    expect(s.compliance).toBeCloseTo(2 / 3);
  });

  it('item sem registro final conta como não realizado, mesmo adiado', () => {
    const s = summarizeSession(strategy, [log(0, 'snoozed', 900), log(0, 'snoozed', 1200)]);

    expect(s.items[0]).toMatchObject({ status: 'missed', snoozes: 2 });
    expect(s.compliance).toBe(0);
  });

  it('correção no celular vence o registro do relógio', () => {
    const s = summarizeSession(strategy, [
      log(0, 'taken', 900, { by: 'auto' }),
      log(0, 'missed', 900, { by: 'phone', ts: 2_000_000 }),
    ]);

    expect(s.items[0]).toMatchObject({ status: 'missed', by: 'phone' });
  });

  it('conta consumos presumidos pelo Data Field', () => {
    const s = summarizeSession(strategy, [log(0, 'taken', 900, { by: 'auto' }), log(1, 'taken', 2400, { by: 'lap' })]);

    expect(s.presumed).toBe(1);
  });

  it('agrupa por hora pelo horário planejado e pelo horário real', () => {
    // O 2º gel estava planejado para 1h15 e foi tomado em 1h16.
    const s = summarizeSession(strategy, [log(0, 'taken', 905), log(2, 'taken', 4560)], 2 * 3600);

    expect(s.byHour).toHaveLength(2);
    expect(s.byHour[0]!.planned.carbsG).toBe(25);
    expect(s.byHour[0]!.taken.carbsG).toBe(25);
    expect(s.byHour[1]!.planned.carbsG).toBe(25);
    expect(s.byHour[1]!.taken.carbsG).toBe(25);
  });

  it('ignora registros de outra estratégia', () => {
    const s = summarizeSession(strategy, [log(0, 'taken', 900, { sid: 'outra' })]);

    expect(s.items[0]!.status).toBe('missed');
  });
});
