import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../core/theme.dart';

/// Horizontal scroller of the next 7 days (today + 6), used wherever a
/// screen needs "which delivery day am I looking at" — the factory plans
/// a week ahead, not just today/tomorrow.
class WeekDayPicker extends StatelessWidget {
  const WeekDayPicker({super.key, required this.selected, required this.onSelected});

  final DateTime selected;
  final void Function(DateTime date) onSelected;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day + i));

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selected);
          final label = index == 0
              ? 'Сегодня'
              : index == 1
                  ? 'Завтра'
                  : intl.DateFormat.E('ru').format(day);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(day),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? BrandColors.black : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: BrandColors.black,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? const [BoxShadow(color: BrandColors.yellow, offset: Offset(3, 3), blurRadius: 0)]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isSelected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    intl.DateFormat('d.MM').format(day),
                    style: numberStyle(
                      fontSize: 14,
                      color: isSelected ? BrandColors.yellow : BrandColors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
