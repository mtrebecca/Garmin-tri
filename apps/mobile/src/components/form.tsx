import { Pressable, StyleSheet, Switch, TextInput, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <ThemedView type="backgroundElement" style={styles.card}>
      <ThemedText type="smallBold" themeColor="textSecondary">
        {title.toUpperCase()}
      </ThemedText>
      {children}
    </ThemedView>
  );
}

type NumberFieldProps = {
  label: string;
  unit: string;
  value: string;
  onChange: (value: string) => void;
  hint?: string;
  placeholder?: string;
};

export function NumberField({ label, unit, value, onChange, hint, placeholder }: NumberFieldProps) {
  const theme = useTheme();
  return (
    <View style={styles.row}>
      <View style={styles.grow}>
        <ThemedText>{label}</ThemedText>
        {hint ? (
          <ThemedText type="small" themeColor="textSecondary">
            {hint}
          </ThemedText>
        ) : null}
      </View>
      <TextInput
        accessibilityLabel={label}
        value={value}
        onChangeText={(text) => onChange(text.replace(',', '.').replace(/[^0-9.-]/g, ''))}
        keyboardType="numeric"
        placeholder={placeholder}
        placeholderTextColor={theme.textSecondary}
        style={[styles.input, { color: theme.text, backgroundColor: theme.background }]}
      />
      <ThemedText type="small" themeColor="textSecondary" style={styles.unit}>
        {unit}
      </ThemedText>
    </View>
  );
}

export function ToggleRow({ label, value, onChange }: { label: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <View style={styles.row}>
      <ThemedText style={styles.grow}>{label}</ThemedText>
      <Switch accessibilityLabel={label} value={value} onValueChange={onChange} />
    </View>
  );
}

type SegmentedProps<T extends string> = {
  options: { value: T; label: string }[];
  value: T;
  onChange: (value: T) => void;
};

export function Segmented<T extends string>({ options, value, onChange }: SegmentedProps<T>) {
  return (
    <View style={styles.segmented}>
      {options.map((o) => (
        <Pressable
          key={o.value}
          accessibilityRole="button"
          accessibilityState={{ selected: o.value === value }}
          onPress={() => onChange(o.value)}
          style={styles.grow}>
          <ThemedView type={o.value === value ? 'backgroundSelected' : 'background'} style={styles.segment}>
            <ThemedText type="small" themeColor={o.value === value ? 'text' : 'textSecondary'}>
              {o.label}
            </ThemedText>
          </ThemedView>
        </Pressable>
      ))}
    </View>
  );
}

export function TextButton({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} hitSlop={8}>
      <ThemedText type="smallBold" themeColor="accent">
        {label}
      </ThemedText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: Spacing.three,
    padding: Spacing.three,
    gap: Spacing.three,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
  },
  grow: {
    flex: 1,
  },
  input: {
    width: 72,
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.two,
    borderRadius: Spacing.two,
    fontSize: 16,
    textAlign: 'right',
  },
  unit: {
    width: 40,
  },
  segmented: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  segment: {
    alignItems: 'center',
    paddingVertical: Spacing.two,
    borderRadius: Spacing.two,
  },
});
