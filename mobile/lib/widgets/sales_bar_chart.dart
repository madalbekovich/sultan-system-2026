import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../core/theme.dart';
import '../models/dashboard_analytics.dart';

/// Minimal custom bar chart for the week's sales — no charting dependency,
/// just enough to show the trend at a glance.
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.data});

  final List<DailySales> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxValue = data.map((d) => d.totalAmount).fold<double>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((entry) {
          final isToday = entry.deliveryDate.year == today.year &&
              entry.deliveryDate.month == today.month &&
              entry.deliveryDate.day == today.day;
          final heightFraction = maxValue == 0 ? 0.0 : entry.totalAmount / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (entry.totalAmount > 0)
                    Text(
                      _compact(entry.totalAmount),
                      style: numberStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 6 + 84 * heightFraction,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.red : AppColors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    intl.DateFormat.E('ru').format(entry.deliveryDate),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? AppColors.red : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _compact(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}к';
    return value.toStringAsFixed(0);
  }
}
