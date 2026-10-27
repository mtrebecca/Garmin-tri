import type { Range, Suggestion, SuggestionInput, SweatTestInput } from './types';

// Faixas baseadas em diretrizes gerais de nutrição esportiva (ver docs/sugestoes.md).
// São ponto de partida editável, não prescrição individualizada.

const HOT_C = 25;
const COLD_C = 10;
const MAX_SWEAT_RATE = 3000;
const MAX_FLUID_SUGGESTED = 1200;

export class SuggestionError extends Error {}

export function suggestTargets(input: SuggestionInput): Suggestion {
  if (!(input.durationMin > 0 && input.durationMin <= 24 * 60)) {
    throw new SuggestionError('Duração deve estar entre 1 e 1440 minutos.');
  }
  if (input.sweatRateMlPerHour !== undefined && !(input.sweatRateMlPerHour > 0 && input.sweatRateMlPerHour <= MAX_SWEAT_RATE)) {
    throw new SuggestionError(`Taxa de suor deve estar entre 1 e ${MAX_SWEAT_RATE} ml/h.`);
  }

  const notes: string[] = [];
  const short = input.durationMin < 60;
  const hot = input.temperatureC !== undefined && input.temperatureC >= HOT_C;
  const cold = input.temperatureC !== undefined && input.temperatureC < COLD_C;

  let carbsPerHour: Range;
  if (short) {
    carbsPerHour = { min: 0, max: 30, suggested: 0 };
    notes.push('Treinos com menos de 1 h não exigem carboidrato; até 30 g/h é opcional.');
  } else if (input.durationMin <= 150) {
    carbsPerHour = { min: 30, max: 60, suggested: input.durationMin < 90 ? 45 : 60 };
  } else {
    carbsPerHour = { min: 60, max: 90, suggested: input.gutTrained ? 90 : 60 };
    notes.push('Acima de 60 g/h, use mistura de glicose e frutose e treine o intestino antes da prova.');
  }
  if (input.sport === 'run' && carbsPerHour.suggested >= 60) {
    notes.push('Na corrida o desconforto gastrointestinal é mais comum: teste a estratégia em treinos.');
  }

  let fluidMlPerHour: Range;
  if (input.sweatRateMlPerHour !== undefined) {
    const sweat = input.sweatRateMlPerHour;
    const max = round50(Math.min(sweat, MAX_FLUID_SUGGESTED));
    fluidMlPerHour = { min: round50(sweat * 0.5), max, suggested: Math.min(round50(sweat * 0.75), max) };
    notes.push('Líquido baseado na sua taxa de suor: reponha parte da perda, sem beber mais do que sua.');
  } else if (hot) {
    fluidMlPerHour = { min: 500, max: 800, suggested: 650 };
  } else if (cold) {
    fluidMlPerHour = { min: 300, max: 500, suggested: 400 };
  } else {
    fluidMlPerHour = { min: 400, max: 600, suggested: 500 };
  }
  if (short && !hot) {
    fluidMlPerHour = { ...fluidMlPerHour, min: 0, suggested: 0 };
    notes.push('Em treinos curtos e sem calor, beba conforme a sede.');
  }

  let sodiumMgPerHour: Range =
    hot || input.saltySweater ? { min: 500, max: 1000, suggested: 700 } : { min: 300, max: 600, suggested: 400 };
  if (short) {
    sodiumMgPerHour = { ...sodiumMgPerHour, min: 0, suggested: 0 };
  }

  return { carbsPerHour, fluidMlPerHour, sodiumMgPerHour, notes };
}

/**
 * Taxa de suor pelo teste de pesagem: peso perdido + líquido ingerido − urina, por hora.
 * 1 kg de peso perdido ≈ 1 litro de suor.
 */
export function sweatRateFromTest(input: SweatTestInput): number {
  const { durationMin, weightBeforeKg, weightAfterKg, fluidIntakeMl, urineMl = 0 } = input;
  if (!(durationMin >= 30 && durationMin <= 24 * 60)) {
    throw new SuggestionError('O teste precisa durar ao menos 30 minutos.');
  }
  if (!(weightBeforeKg > 0 && weightAfterKg > 0)) {
    throw new SuggestionError('Informe os pesos antes e depois.');
  }
  if (Math.abs(weightBeforeKg - weightAfterKg) > weightBeforeKg * 0.1) {
    throw new SuggestionError('Diferença de peso maior que 10%: confira os valores.');
  }
  if (!(fluidIntakeMl >= 0 && urineMl >= 0)) {
    throw new SuggestionError('Líquido ingerido e urina não podem ser negativos.');
  }

  const lossMl = (weightBeforeKg - weightAfterKg) * 1000 + fluidIntakeMl - urineMl;
  if (lossMl <= 0) {
    throw new SuggestionError('O resultado não indica perda de suor: confira os valores.');
  }
  const rate = Math.round(lossMl / (durationMin / 60));
  if (rate > MAX_SWEAT_RATE) {
    throw new SuggestionError(`Taxa acima de ${MAX_SWEAT_RATE} ml/h: confira os valores.`);
  }
  return rate;
}

function round50(value: number): number {
  return Math.round(value / 50) * 50;
}
