import { type ConsumptionLog, type ItemOutcome, summarizeSession, type WatchStrategy } from '@fuelup/core';
import { Platform, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Card } from '@/components/form';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { BottomTabInset, MaxContentWidth, Spacing, type ThemeColor } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { formatMinutes } from '@/lib/products';

// Treino de exemplo até a sincronização com o relógio existir (US-016/US-017).
const SAMPLE_STRATEGY: WatchStrategy = {
  v: 1,
  id: 'exemplo',
  name: 'Longão 2h',
  items: [
    { t: 900, p: 'Gel 25g+Água 150ml', c: 25, na: 50, ml: 150 },
    { t: 1800, p: 'Água 150ml', c: 0, na: 0, ml: 150 },
    { t: 2700, p: 'Gel 25g+Sal', c: 25, na: 300, ml: 0 },
    { t: 3600, p: 'Água 150ml', c: 0, na: 0, ml: 150 },
    { t: 4500, p: 'Gel 25g+Água 150ml', c: 25, na: 50, ml: 150 },
    { t: 5400, p: 'Sal', c: 0, na: 250, ml: 0 },
    { t: 6300, p: 'Gel 25g', c: 25, na: 50, ml: 0 },
  ],
};

const SAMPLE_LOGS: ConsumptionLog[] = [
  { id: 'a', sid: 'exemplo', i: 0, a: 'taken', by: 'lap', t: 910, ts: 1 },
  { id: 'b', sid: 'exemplo', i: 1, a: 'taken', by: 'auto', t: 1800, ts: 2 },
  { id: 'c', sid: 'exemplo', i: 2, a: 'taken', by: 'lap', t: 2760, ts: 3 },
  { id: 'd', sid: 'exemplo', i: 3, a: 'missed', by: 'lap', t: 3720, ts: 4 },
  { id: 'e', sid: 'exemplo', i: 4, a: 'taken', by: 'lap', t: 4540, ts: 5 },
  { id: 'f', sid: 'exemplo', i: 5, a: 'missed', by: 'lap', t: 5520, ts: 6 },
  { id: 'g', sid: 'exemplo', i: 6, a: 'taken', by: 'auto', t: 6300, ts: 7 },
];

const STATUS: Record<ItemOutcome['status'], { label: string; color: ThemeColor }> = {
  taken: { label: 'Consumido', color: 'success' },
  skipped: { label: 'Pulado', color: 'danger' },
  missed: { label: 'Não realizado', color: 'danger' },
};

const BY_LABEL: Record<NonNullable<ItemOutcome['by']>, string> = {
  auto: 'presumido',
  lap: 'LAP',
  button: 'botão',
  phone: 'corrigido no celular',
};

export default function HistoryScreen() {
  const summary = summarizeSession(SAMPLE_STRATEGY, SAMPLE_LOGS, 2 * 3600);
  const maxCarbs = Math.max(1, ...summary.byHour.map((h) => Math.max(h.planned.carbsG, h.taken.carbsG)));

  return (
    <ThemedView style={styles.container}>
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        <ScrollView contentContainerStyle={styles.content}>
          <ThemedText type="subtitle">Histórico</ThemedText>
          <ThemedText type="small" themeColor="textSecondary">
            Exemplo: os treinos reais aparecem aqui depois da sincronização com o relógio.
          </ThemedText>

          <Card title={SAMPLE_STRATEGY.name}>
            <ThemedText type="title">{Math.round(summary.compliance * 100)}%</ThemedText>
            <ThemedText type="small" themeColor="textSecondary">
              do plano cumprido · {summary.presumed} consumo(s) presumido(s), sem confirmação
            </ThemedText>
            <Totals label="Carboidrato" unit="g" planned={summary.planned.carbsG} taken={summary.taken.carbsG} />
            <Totals label="Líquido" unit="ml" planned={summary.planned.volumeMl} taken={summary.taken.volumeMl} />
            <Totals label="Sódio" unit="mg" planned={summary.planned.sodiumMg} taken={summary.taken.sodiumMg} />
          </Card>

          <Card title="Carboidrato por hora">
            {summary.byHour.map((h) => (
              <View key={h.hour} style={styles.hourRow}>
                <ThemedText type="small" style={styles.hourLabel}>
                  {h.hour + 1}ª h
                </ThemedText>
                <View style={styles.grow}>
                  <Bar value={h.planned.carbsG} max={maxCarbs} color="textSecondary" />
                  <Bar value={h.taken.carbsG} max={maxCarbs} color="accent" />
                </View>
                <ThemedText type="small" style={styles.hourValue}>
                  {h.taken.carbsG}/{h.planned.carbsG} g
                </ThemedText>
              </View>
            ))}
            <ThemedText type="small" themeColor="textSecondary">
              Cinza: planejado · Laranja: realizado
            </ThemedText>
          </Card>

          <Card title="Consumos">
            {summary.items.map((o) => (
              <View key={o.index} style={styles.itemRow}>
                <ThemedText type="smallBold" style={styles.hourLabel}>
                  {formatMinutes(Math.round(o.item.t / 60))}
                </ThemedText>
                <View style={styles.grow}>
                  <ThemedText type="small">{o.item.p}</ThemedText>
                  <ThemedText type="small" themeColor={STATUS[o.status].color}>
                    {STATUS[o.status].label}
                    {o.by ? ` · ${o.status === 'missed' && o.by === 'lap' ? 'sem LAP' : BY_LABEL[o.by]}` : ''}
                  </ThemedText>
                </View>
              </View>
            ))}
            <ThemedText type="small" themeColor="textSecondary">
              Em breve: tocar num consumo para corrigir o que foi ou não consumido.
            </ThemedText>
          </Card>
        </ScrollView>
      </SafeAreaView>
    </ThemedView>
  );
}

function Totals({ label, unit, planned, taken }: { label: string; unit: string; planned: number; taken: number }) {
  return (
    <View style={styles.totalsRow}>
      <ThemedText style={styles.grow}>{label}</ThemedText>
      <ThemedText type="smallBold">
        {taken} / {planned} {unit}
      </ThemedText>
    </View>
  );
}

function Bar({ value, max, color }: { value: number; max: number; color: ThemeColor }) {
  const theme = useTheme();
  return (
    <View style={styles.barTrack}>
      <View style={[styles.bar, { width: `${(value / max) * 100}%`, backgroundColor: theme[color] }]} />
    </View>
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
  grow: {
    flex: 1,
  },
  totalsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  hourRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
  },
  hourLabel: {
    width: 56,
  },
  hourValue: {
    width: 64,
    textAlign: 'right',
  },
  barTrack: {
    height: 8,
    marginVertical: 2,
  },
  bar: {
    height: 8,
    borderRadius: 4,
  },
  itemRow: {
    flexDirection: 'row',
    gap: Spacing.three,
  },
});
