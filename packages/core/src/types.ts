export type Sport = 'run' | 'bike';

export interface Nutrients {
  carbsG: number;
  sodiumMg: number;
  volumeMl: number;
}

export interface Product extends Nutrients {
  id: string;
  name: string;
}

/** Metas por hora. Metas zeradas ou ausentes são ignoradas no cronograma. */
export interface Targets {
  carbsPerHour: number;
  fluidMlPerHour?: number;
  sodiumMgPerHour?: number;
}

export interface ScheduleInput {
  durationMin: number;
  targets: Targets;
  /** Produtos disponíveis; o cronograma escolhe o que melhor aproxima as metas. */
  products: Product[];
  /** Não agenda nada antes deste minuto. Padrão: 15. */
  startAfterMin?: number;
  /** Não agenda nada nos últimos N minutos. Padrão: 10. */
  stopBeforeEndMin?: number;
  /** Intervalo mínimo entre dois consumos. Padrão: 10. */
  minIntervalMin?: number;
}

export interface ScheduledItem {
  atMin: number;
  product: Product;
}

export interface Schedule {
  items: ScheduledItem[];
  totals: Nutrients;
  /** Média por hora efetivamente planejada. */
  perHourPlanned: Nutrients;
}

export interface Range {
  min: number;
  max: number;
  suggested: number;
}

export interface SuggestionInput {
  sport: Sport;
  durationMin: number;
  /** Temperatura prevista em °C. */
  temperatureC?: number;
  /** Taxa de suor medida no teste de pesagem (ver sweatRateFromTest). */
  sweatRateMlPerHour?: number;
  /** Atleta que perde muito sal (manchas brancas na roupa, cãibras). */
  saltySweater?: boolean;
  /** Já treinou o intestino para mais de 60 g/h. */
  gutTrained?: boolean;
}

export interface Suggestion {
  carbsPerHour: Range;
  fluidMlPerHour: Range;
  sodiumMgPerHour: Range;
  notes: string[];
}

export interface SweatTestInput {
  durationMin: number;
  weightBeforeKg: number;
  weightAfterKg: number;
  fluidIntakeMl: number;
  urineMl?: number;
}

/** Formato compacto enviado ao relógio. Ver docs/contrato-estrategia.md. */
export interface WatchStrategy {
  v: 1;
  id: string;
  name: string;
  items: WatchItem[];
}

export interface WatchItem {
  /** Segundos desde o início da atividade (tempo de timer, descontando pausas). */
  t: number;
  p: string;
  c: number;
  na: number;
  ml: number;
}

/** Registro de consumo vindo do relógio (ou corrigido no celular). Ver docs/contrato-estrategia.md. */
export interface ConsumptionLog {
  id: string;
  sid: string;
  i: number;
  a: 'taken' | 'skipped' | 'snoozed' | 'missed';
  /** Ausente = button (Device App). */
  by?: 'button' | 'auto' | 'lap' | 'phone';
  t: number;
  ts: number;
}

export interface ItemOutcome {
  index: number;
  item: WatchItem;
  status: 'taken' | 'skipped' | 'missed';
  by?: NonNullable<ConsumptionLog['by']>;
  snoozes: number;
  takenAtSec?: number;
  /** Atraso em relação ao planejado (negativo = antecipado). */
  delaySec?: number;
}

export interface SessionSummary {
  items: ItemOutcome[];
  planned: Nutrients;
  taken: Nutrients;
  /** Fração dos itens consumidos, de 0 a 1. */
  compliance: number;
  /** Consumos presumidos pelo Data Field (sem confirmação nem correção). */
  presumed: number;
  byHour: { hour: number; planned: Nutrients; taken: Nutrients }[];
}
