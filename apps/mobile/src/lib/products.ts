import type { Product } from '@fuelup/core';

// Produtos genéricos para começar; o cadastro do atleta (US-004) e a biblioteca de marcas
// vendidas no Brasil vêm depois, pelo Supabase.
export const STARTER_PRODUCTS: Product[] = [
  { id: 'gel', name: 'Gel 25g', carbsG: 25, sodiumMg: 50, volumeMl: 0 },
  { id: 'gel-cafeina', name: 'Gel c/ cafeína', carbsG: 25, sodiumMg: 50, volumeMl: 0 },
  { id: 'isotonico', name: 'Isotônico 500ml', carbsG: 30, sodiumMg: 300, volumeMl: 500 },
  { id: 'agua', name: 'Água 150ml', carbsG: 0, sodiumMg: 0, volumeMl: 150 },
  { id: 'sal', name: 'Cápsula de sal', carbsG: 0, sodiumMg: 250, volumeMl: 0 },
  { id: 'banana', name: 'Banana', carbsG: 25, sodiumMg: 0, volumeMl: 0 },
];

export function formatMinutes(min: number): string {
  const h = Math.floor(min / 60);
  const m = min % 60;
  return h > 0 ? `${h}h${String(m).padStart(2, '0')}` : `${m} min`;
}
