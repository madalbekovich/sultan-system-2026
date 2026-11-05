import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../core/ru_text.dart';
import '../core/theme.dart';

/// Compact "N заказов · сумма · вес" strip shown above a day's order list.
/// Manager passes [amount] so money leads; the workshop omits it (workers
/// aren't shown the order total here) so weight is the lead figure instead.
class OrdersSummaryBar extends StatelessWidget {
  const OrdersSummaryBar({
    super.key,
    required this.orderCount,
    required this.totalWeightGrams,
    this.totalAmount,
  });

  final int orderCount;
  final double totalWeightGrams;
  final double? totalAmount;

  @override
  Widget build(BuildContext context) {
    if (orderCount == 0) return const SizedBox.shrink();
    final mainStyle = numberStyle(fontSize: 15, weight: FontWeight.w800);
    const mutedStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      color: Colors.white,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(ordersCountRu(orderCount), style: mutedStyle),
          const Text('  ·  ', style: mutedStyle),
          if (totalAmount != null) ...[
            Text(formatMoney(totalAmount!), style: mainStyle),
            const Text('  ·  ', style: mutedStyle),
            Text(formatWeightKg(totalWeightGrams), style: mutedStyle),
          ] else
            Text(formatWeightKg(totalWeightGrams), style: mainStyle),
        ],
      ),
    );
  }
}
