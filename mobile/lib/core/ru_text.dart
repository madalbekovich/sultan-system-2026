/// Small helpers for correct Russian text in the UI: unit labels and
/// plural forms, which don't follow the simple "s / no s" English rule.
String unitLabelRu(String unitType) => unitType.toUpperCase() == 'KG' ? 'кг' : 'шт';

/// Picks the right plural form for a count, e.g. pluralRu(n, 'клиент', 'клиента', 'клиентов').
String pluralRu(int count, String one, String few, String many) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return few;
  return many;
}

String clientsCountRu(int count) => '$count ${pluralRu(count, 'клиент', 'клиента', 'клиентов')}';

String itemsCountRu(int count) => '$count ${pluralRu(count, 'товар', 'товара', 'товаров')}';
