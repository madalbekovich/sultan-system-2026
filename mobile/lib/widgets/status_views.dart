import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../core/refresh_status.dart';
import '../core/tokens.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact "the data on screen might be stale" notice — distinguishes real
/// connectivity loss from a slow/erroring backend (same underlying cause
/// in the old version always said "Нет сети", even for a 500), shows when
/// it was last refreshed, and offers a manual retry. Disappears on its own
/// once [status] goes back to [DataStatus.ok].
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({
    super.key,
    required this.status,
    required this.lastUpdated,
    required this.onRetry,
  });

  final DataStatus status;
  final DateTime? lastUpdated;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == DataStatus.ok) return const SizedBox.shrink();
    final message = status == DataStatus.offline
        ? 'Нет сети — показаны последние сохранённые данные'
        : 'Сервер не отвечает — показаны последние данные';
    final updatedLabel =
        lastUpdated != null ? 'Обновлено ${intl.DateFormat('HH:mm').format(lastUpdated!)}' : null;

    return Container(
      width: double.infinity,
      color: AppColors.staleBanner,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.staleBannerText),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: message),
                  if (updatedLabel != null) TextSpan(text: ' · $updatedLabel'),
                ],
              ),
              style: const TextStyle(color: AppColors.staleBannerText, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Повторить', style: TextStyle(fontSize: 12, color: AppColors.redDark)),
          ),
        ],
      ),
    );
  }
}
