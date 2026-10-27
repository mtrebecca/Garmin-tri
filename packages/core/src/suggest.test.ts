import { suggestTargets, SuggestionError, sweatRateFromTest } from './suggest';

describe('suggestTargets', () => {
  it('treino curto não pede carboidrato nem sódio', () => {
    const s = suggestTargets({ sport: 'run', durationMin: 45 });

    expect(s.carbsPerHour.suggested).toBe(0);
    expect(s.sodiumMgPerHour.suggested).toBe(0);
    expect(s.fluidMlPerHour.suggested).toBe(0);
  });

  it('treino curto no calor ainda sugere líquido', () => {
    const s = suggestTargets({ sport: 'run', durationMin: 45, temperatureC: 30 });

    expect(s.fluidMlPerHour.suggested).toBe(650);
  });

  it('treino de 2 h sugere 60 g/h', () => {
    const s = suggestTargets({ sport: 'bike', durationMin: 120 });

    expect(s.carbsPerHour).toEqual({ min: 30, max: 60, suggested: 60 });
    expect(s.fluidMlPerHour).toEqual({ min: 400, max: 600, suggested: 500 });
    expect(s.sodiumMgPerHour).toEqual({ min: 300, max: 600, suggested: 400 });
  });

  it('prova longa só sugere 90 g/h com intestino treinado', () => {
    expect(suggestTargets({ sport: 'bike', durationMin: 300 }).carbsPerHour.suggested).toBe(60);
    expect(suggestTargets({ sport: 'bike', durationMin: 300, gutTrained: true }).carbsPerHour.suggested).toBe(90);
  });

  it('calor ou suor salgado aumentam o sódio', () => {
    expect(suggestTargets({ sport: 'run', durationMin: 120, temperatureC: 28 }).sodiumMgPerHour.suggested).toBe(700);
    expect(suggestTargets({ sport: 'run', durationMin: 120, saltySweater: true }).sodiumMgPerHour.suggested).toBe(700);
  });

  it('usa a taxa de suor sem sugerir beber mais do que se perde', () => {
    const s = suggestTargets({ sport: 'run', durationMin: 120, sweatRateMlPerHour: 900 });

    expect(s.fluidMlPerHour).toEqual({ min: 450, max: 900, suggested: 700 });
  });

  it('limita a sugestão de líquido para quem sua muito', () => {
    const s = suggestTargets({ sport: 'run', durationMin: 120, sweatRateMlPerHour: 2000 });

    expect(s.fluidMlPerHour.max).toBe(1200);
    expect(s.fluidMlPerHour.suggested).toBe(1200);
  });

  it('alerta sobre o intestino na corrida com meta alta', () => {
    const s = suggestTargets({ sport: 'run', durationMin: 120 });

    expect(s.notes.some((n) => n.includes('gastrointestinal'))).toBe(true);
  });

  it('rejeita duração inválida', () => {
    expect(() => suggestTargets({ sport: 'run', durationMin: 0 })).toThrow(SuggestionError);
  });
});

describe('sweatRateFromTest', () => {
  it('soma peso perdido e líquido ingerido, por hora', () => {
    // 1 kg perdido + 500 ml bebidos em 90 min = 1500 ml / 1,5 h
    const rate = sweatRateFromTest({ durationMin: 90, weightBeforeKg: 70, weightAfterKg: 69, fluidIntakeMl: 500 });

    expect(rate).toBe(1000);
  });

  it('desconta a urina', () => {
    const rate = sweatRateFromTest({
      durationMin: 60,
      weightBeforeKg: 70,
      weightAfterKg: 69.5,
      fluidIntakeMl: 300,
      urineMl: 100,
    });

    expect(rate).toBe(700);
  });

  it.each([
    [{ durationMin: 20, weightBeforeKg: 70, weightAfterKg: 69, fluidIntakeMl: 0 }],
    [{ durationMin: 60, weightBeforeKg: 70, weightAfterKg: 60, fluidIntakeMl: 0 }],
    [{ durationMin: 60, weightBeforeKg: 70, weightAfterKg: 71, fluidIntakeMl: 0 }],
    [{ durationMin: 60, weightBeforeKg: 70, weightAfterKg: 69, fluidIntakeMl: -1 }],
  ])('rejeita teste inválido %#', (input) => {
    expect(() => sweatRateFromTest(input)).toThrow(SuggestionError);
  });
});
