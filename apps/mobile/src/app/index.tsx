import {
  generateSchedule,
  type Range,
  type Schedule,
  type Sport,
  suggestTargets,
  type Suggestion,
} from '@fuelup/core';
import { useMemo, useState } from 'react';
import { Platform, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Card, NumberField, Segmented, TextButton, ToggleRow } from '@/components/form';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { BottomTabInset, MaxContentWidth, Spacing } from '@/constants/theme';
import { formatMinutes, STARTER_PRODUCTS } from '@/lib/products';

type TargetKey = 'carbsPerHour' | 'fluidMlPerHour' | 'sodiumMgPerHour';
type Targets = Record<TargetKey, string>;

const TARGET_FIELDS: { key: TargetKey; label: string; unit: string }[] = [
  { key: 'carbsPerHour', label: 'Carboidrato', unit: 'g/h' },
  { key: 'fluidMlPerHour', label: 'Líquido', unit: 'ml/h' },
  { key: 'sodiumMgPerHour', label: 'Sódio', unit: 'mg/h' },
];

function toNumber(value: string): number | undefined {
  const n = Number(value);
  return value.trim() === '' || Number.isNaN(n) ? undefined : n;
}

function suggestedTargets(s: Suggestion): Targets {
  return {
    carbsPerHour: String(s.carbsPerHour.suggested),
    fluidMlPerHour: String(s.fluidMlPerHour.suggested),
    sodiumMgPerHour: String(s.sodiumMgPerHour.suggested),
  };
}

function rangeHint(r: Range): string {
  return `sugestão ${r.suggested} (faixa ${r.min}–${r.max})`;
}

export default function PlanScreen() {
  const [sport, setSport] = useState<Sport>('run');
  const [duration, setDuration] = useState('120');
  const [temperature, setTemperature] = useState('');
  const [saltySweater, setSaltySweater] = useState(false);
  const [gutTrained, setGutTrained] = useState(false);
  // null = segue a sugestão; preenchido = o atleta personalizou as metas.
  const [customTargets, setCustomTargets] = useState<Targets | null>(null);
  const [selected, setSelected] = useState<string[]>(['gel', 'agua', 'sal']);

  const durationMin = toNumber(duration) ?? 0;

  const suggestion = useMemo(() => {
    try {
      return suggestTargets({
        sport,
        durationMin,
        temperatureC: toNumber(temperature),
        saltySweater,
        gutTrained,
      });
    } catch {
      return null;
    }
  }, [sport, durationMin, temperature, saltySweater, gutTrained]);

  const targets = customTargets ?? (suggestion ? suggestedTargets(suggestion) : null);

  const plan = useMemo((): { schedule?: Schedule; error?: string } => {
    if (!targets) return { error: 'Informe a duração do treino.' };
    try {
      return {
        schedule: generateSchedule({
          durationMin,
          targets: {
            carbsPerHour: toNumber(targets.carbsPerHour) ?? 0,
            fluidMlPerHour: toNumber(targets.fluidMlPerHour) ?? 0,
            sodiumMgPerHour: toNumber(targets.sodiumMgPerHour) ?? 0,
          },
          products: STARTER_PRODUCTS.filter((p) => selected.includes(p.id)),
        }),
      };
    } catch (e) {
      return { error: e instanceof Error ? e.message : String(e) };
    }
  }, [targets, durationMin, selected]);

  function editTarget(key: TargetKey, value: string) {
    if (!targets) return;
    setCustomTargets({ ...targets, [key]: value });
  }

  function toggleProduct(id: string) {
    setSelected((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]));
  }

  return (
    <ThemedView style={styles.container}>
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        <ScrollView contentContainerStyle={styles.content}>
          <ThemedText type="subtitle">Novo plano</ThemedText>

          <Card title="Treino">
            <Segmented
              options={[
                { value: 'run', label: 'Corrida' },
                { value: 'bike', label: 'Ciclismo' },
              ]}
              value={sport}
              onChange={setSport}
            />
            <NumberField label="Duração prevista" unit="min" value={duration} onChange={setDuration} />
            <NumberField
              label="Temperatura"
              unit="°C"
              value={temperature}
              onChange={setTemperature}
              placeholder="—"
            />
            <ToggleRow label="Perco muito sal no suor" value={saltySweater} onChange={setSaltySweater} />
            <ToggleRow label="Intestino treinado (> 60 g/h)" value={gutTrained} onChange={setGutTrained} />
          </Card>

          <Card title={customTargets ? 'Metas por hora · personalizadas' : 'Metas por hora · sugeridas'}>
            {suggestion && targets ? (
              <>
                {TARGET_FIELDS.map((f) => (
                  <NumberField
                    key={f.key}
                    label={f.label}
                    unit={f.unit}
                    value={targets[f.key]}
                    onChange={(v) => editTarget(f.key, v)}
                    hint={rangeHint(suggestion[f.key])}
                  />
                ))}
                {customTargets ? (
                  <TextButton label="Voltar à sugestão" onPress={() => setCustomTargets(null)} />
                ) : null}
                {suggestion.notes.map((n) => (
                  <ThemedText key={n} type="small" themeColor="textSecondary">
                    • {n}
                  </ThemedText>
                ))}
                <ThemedText type="small" themeColor="textSecondary">
                  Sugestão geral, não é prescrição. Ajuste com seu nutricionista.
                </ThemedText>
              </>
            ) : (
              <ThemedText type="small" themeColor="danger">
                Informe uma duração entre 1 e 1440 minutos.
              </ThemedText>
            )}
          </Card>

          <Card title="Produtos">
            <View style={styles.chips}>
              {STARTER_PRODUCTS.map((p) => {
                const on = selected.includes(p.id);
                return (
                  <Pressable
                    key={p.id}
                    accessibilityRole="checkbox"
                    accessibilityState={{ checked: on }}
                    onPress={() => toggleProduct(p.id)}>
                    <ThemedView type={on ? 'backgroundSelected' : 'background'} style={styles.chip}>
                      <ThemedText type="small" themeColor={on ? 'text' : 'textSecondary'}>
                        {on ? '✓ ' : ''}
                        {p.name}
                      </ThemedText>
                    </ThemedView>
                  </Pressable>
                );
              })}
            </View>
          </Card>

          <Card title="Cronograma">
            {plan.error ? (
              <ThemedText type="small" themeColor="danger">
                {plan.error}
              </ThemedText>
            ) : (
              <ScheduleView schedule={plan.schedule!} targets={targets!} />
            )}
          </Card>

          <ThemedView type="backgroundSelected" style={styles.sendButton}>
            <ThemedText type="smallBold" themeColor="textSecondary">
              Enviar ao relógio (em breve)
            </ThemedText>
          </ThemedView>
        </ScrollView>
      </SafeAreaView>
    </ThemedView>
  );
}

function ScheduleView({ schedule, targets }: { schedule: Schedule; targets: Targets }) {
  if (schedule.items.length === 0) {
    return (
      <ThemedText type="small" themeColor="textSecondary">
        Nenhum consumo necessário para este treino.
      </ThemedText>
    );
  }

  // Itens do mesmo minuto viram um único alerta no relógio.
  const slots: { atMin: number; names: string[] }[] = [];
  for (const { atMin, product } of schedule.items) {
    const last = slots[slots.length - 1];
    if (last?.atMin === atMin) last.names.push(product.name);
    else slots.push({ atMin, names: [product.name] });
  }

  const per = schedule.perHourPlanned;
  return (
    <>
      {slots.map((s) => (
        <View key={s.atMin} style={styles.slot}>
          <ThemedText type="smallBold" style={styles.slotTime}>
            {formatMinutes(s.atMin)}
          </ThemedText>
          <ThemedText type="small" style={styles.grow}>
            {s.names.join(' + ')}
          </ThemedText>
        </View>
      ))}
      <ThemedText type="small" themeColor="textSecondary">
        Planejado por hora: {per.carbsG} g carbo (meta {targets.carbsPerHour}) · {per.volumeMl} ml (meta{' '}
        {targets.fluidMlPerHour}) · {per.sodiumMg} mg sódio (meta {targets.sodiumMgPerHour})
      </ThemedText>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  safeArea: {
    flex: 1,
  },
  content: {
    gap: Spacing.three,
    padding: Spacing.three,
    // Na web a barra de abas flutua no topo.
    paddingTop: Platform.OS === 'web' ? Spacing.six + Spacing.three : Spacing.three,
    paddingBottom: BottomTabInset + Spacing.four,
    maxWidth: MaxContentWidth,
    width: '100%',
    alignSelf: 'center',
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.two,
  },
  chip: {
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.three,
    borderRadius: Spacing.four,
  },
  slot: {
    flexDirection: 'row',
    gap: Spacing.three,
  },
  slotTime: {
    width: 56,
  },
  grow: {
    flex: 1,
  },
  sendButton: {
    alignItems: 'center',
    padding: Spacing.three,
    borderRadius: Spacing.three,
  },
});
