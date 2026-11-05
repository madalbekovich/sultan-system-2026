import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/price_sheet_excel.dart';
import '../../../core/theme.dart';
import '../../../data/clients_repository.dart';
import '../../../data/orders_repository.dart';
import '../../../data/products_repository.dart';
import '../../../models/client.dart';
import '../../../models/order.dart';
import '../../../models/price_sheet_row.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import '../../../widgets/ticket_card.dart';
import '../catalog/product_form_sheet.dart';
import 'client_detail_controller.dart';

class ClientDetailScreen extends StatelessWidget {
  ClientDetailScreen({super.key, required this.client});

  final Client client;
  late final ClientDetailController controller = Get.put(
    ClientDetailController(
      Get.find<OrdersRepository>(),
      Get.find<ClientsRepository>(),
      Get.find<ProductsRepository>(),
      client,
    ),
    tag: 'client_detail_${client.id}',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showEditClientSheet(context, controller),
          ),
          Obx(() {
            final archived = controller.client.value.isArchived;
            return IconButton(
              tooltip: archived ? 'Вернуть из архива' : 'Архивировать',
              icon: Icon(archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              onPressed: () => _confirmArchive(context, controller, archived),
            );
          }),
        ],
      ),
      body: Obx(() {
        final Widget content;
        if (controller.isLoading.value) {
          content = const SkeletonCardList(key: ValueKey('skeleton'));
        } else if (controller.errorMessage.value != null) {
          content = ErrorView(
            key: const ValueKey('error'),
            message: controller.errorMessage.value!,
            onRetry: controller.load,
          );
        } else {
          content = RefreshIndicator(
            key: const ValueKey('content'),
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ClientHeaderCard(controller: controller),
                const SizedBox(height: AppSpacing.xl),
                _PriceSheetSection(controller: controller),
                const SizedBox(height: AppSpacing.xl),
                Text('История заказов', style: headingStyle()),
                const SizedBox(height: AppSpacing.sm + 2),
                if (controller.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text('Заказов пока не было.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...controller.orders.asMap().entries.map(
                    (indexed) {
                      final order = indexed.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: StaggeredFadeIn(
                          index: indexed.key,
                          child: TicketCard(
                            accentColor: orderStatusColor(order.status),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '№${order.id} · ${order.deliveryDate.toLocal().toString().split(' ').first}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${order.items.length} поз. · ${formatQtyLabel(order.totalQty, 'шт')} · ${formatMoney(order.totalAmount)}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                                StampBadge(label: order.status.label, color: orderStatusColor(order.status)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }
        return AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: AppCurves.enter,
          child: content,
        );
      }),
    );
  }
}

class _ClientHeaderCard extends StatelessWidget {
  const _ClientHeaderCard({required this.controller});

  final ClientDetailController controller;

  @override
  Widget build(BuildContext context) {
    // GetX only tracks .value reads made synchronously inside an Obx
    // builder — this must wrap the whole subtree here, not sit one level
    // up at the call site, otherwise these reads happen too late for GetX
    // to see them and it throws "improper use of GetX" on first build.
    return Obx(() {
      final current = controller.client.value;
      return _buildCard(context, current);
    });
  }

  Widget _buildCard(BuildContext context, Client current) {
    return TicketCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'client-avatar-${current.id}',
                child: ClientAvatar(name: current.name, size: 52),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(current.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(width: AppSpacing.sm),
                        StampBadge(
                          label: current.clientCode,
                          color: AppColors.steelBlue,
                        ),
                      ],
                    ),
                    Text(
                      'Всего заказано: ${formatMoney(controller.totalSpent)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (current.phone != null || current.address != null) ...[
            const Divider(height: AppSpacing.xl),
            if (current.phone != null)
              _InfoRow(icon: Icons.phone_outlined, text: formatPhone(current.phone)),
            if (current.address != null)
              _InfoRow(icon: Icons.location_on_outlined, text: current.address!),
          ],
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Icon(
                current.isBound ? Icons.telegram : Icons.link_off,
                size: 18,
                color: current.isBound ? AppColors.moss : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(current.isBound ? 'Telegram привязан' : 'Telegram не привязан'),
              ),
              if (current.isBound)
                controller.isUnbinding.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: () => _confirmUnbind(context, controller),
                        child: const Text('Отвязать'),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmUnbind(BuildContext context, ClientDetailController controller) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Отвязать Telegram?'),
      content: const Text(
        'Склад перестанет быть доступен в текущем Telegram-аккаунте. '
        'Код можно будет ввести заново с другого аккаунта.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Отвязать')),
      ],
    ),
  );
  if (confirmed != true) return;
  final success = await controller.unbind();
  if (!success && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось отвязать.')));
  }
}

Future<void> _confirmArchive(
  BuildContext context,
  ClientDetailController controller,
  bool currentlyArchived,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(currentlyArchived ? 'Вернуть склад из архива?' : 'Архивировать склад?'),
      content: Text(
        currentlyArchived
            ? 'Склад снова появится в общем списке и сможет оформлять заказы.'
            : 'Склад скроется из общего списка и не сможет оформлять новые заказы. '
                'История и данные не удаляются — можно вернуть в любой момент.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(currentlyArchived ? 'Вернуть' : 'Архивировать'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final success = await controller.setArchived(!currentlyArchived);
  if (!success && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось изменить статус.')));
  }
}

/// Edit an existing warehouse's name/phone/address — code, binding and
/// prices are managed elsewhere on this screen, not here.
Future<void> showEditClientSheet(BuildContext context, ClientDetailController controller) {
  final current = controller.client.value;
  final nameController = TextEditingController(text: current.name);
  final phoneController = TextEditingController(text: current.phone ?? '');
  final addressController = TextEditingController(text: current.address ?? '');

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Редактировать склад', style: headingStyle(fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название склада'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Телефон'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: 'Адрес'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final success = await controller.updateInfo(
                  name: name,
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );
                if (success && sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PriceSheetSection extends StatelessWidget {
  const _PriceSheetSection({required this.controller});

  final ClientDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Цены склада', style: headingStyle())),
            IconButton(
              tooltip: 'Новый товар',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => showProductFormSheet(
                context,
                categories: controller.categories,
                onCreate: controller.createCatalogProduct,
                onEdit: controller.editCatalogProduct,
              ),
            ),
            IconButton(
              tooltip: 'Скачать Excel',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _exportPrices(context, controller),
            ),
            IconButton(
              tooltip: 'Загрузить Excel',
              icon: const Icon(Icons.upload_outlined),
              onPressed: () => _importPrices(context, controller),
            ),
          ],
        ),
        Obx(() {
          if (controller.isLoadingPrices.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.priceSheet.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('Нет товаров в каталоге.', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return TicketCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: controller.priceSheet.map((row) {
                return ListTile(
                  dense: true,
                  title: Text(row.productName),
                  subtitle: row.hasOwnPrice
                      ? null
                      : const Text('Своя цена не задана — берётся базовая',
                          style: TextStyle(color: AppColors.ochre, fontSize: 11.5)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${formatMoney(row.effectivePrice)} / ${row.unitType == 'PCS' ? 'шт' : 'кг'}',
                        style: numberStyle(fontSize: 14, weight: FontWeight.w700),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Деактивировать товар',
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                        onPressed: () => _confirmDeactivateProduct(context, controller, row),
                      ),
                    ],
                  ),
                  onTap: () => _editSinglePrice(context, controller, row),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

Future<void> _confirmDeactivateProduct(
  BuildContext context,
  ClientDetailController controller,
  PriceSheetRow row,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Деактивировать товар?'),
      content: Text(
        '«${row.productName}» пропадёт из каталога у всех складов и бота. '
        'История заказов не изменится — товар можно будет снова включить в разделе «Каталог».',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Деактивировать')),
      ],
    ),
  );
  if (confirmed != true) return;
  final success = await controller.deactivateProduct(row.productId);
  if (!success && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось деактивировать товар.')));
  }
}

Future<void> _exportPrices(BuildContext context, ClientDetailController controller) async {
  try {
    await PriceSheetExcelService.export(client: controller.client.value, rows: controller.priceSheet);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось сформировать файл.')));
    }
  }
}

Future<void> _importPrices(BuildContext context, ClientDetailController controller) async {
  List<ParsedPriceRow>? parsed;
  try {
    parsed = await PriceSheetExcelService.pickAndParse();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Файл повреждён или не открывается.')));
    }
    return;
  }
  if (parsed == null || !context.mounted) return;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _ImportPreviewSheet(rows: parsed!),
  );
  if (confirmed != true || !context.mounted) return;

  final clientsRepository = Get.find<ClientsRepository>();
  final result = await clientsRepository.importPriceSheet(
    controller.client.value.id,
    parsed.map((r) => r.toImportRow()).toList(),
  );

  if (!context.mounted) return;
  if (!result.ok) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ошибки в файле — ничего не применено'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: result.errors
                .map((e) => ListTile(dense: true, title: Text('Строка ${e.row}: ${e.message}')))
                .toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Ок'))],
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Обновлено: ${result.updated}, сброшено на базовую: ${result.cleared}')),
  );
  await controller.loadPriceSheet();
}

class _ImportPreviewSheet extends StatelessWidget {
  const _ImportPreviewSheet({required this.rows});

  final List<ParsedPriceRow> rows;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Предпросмотр (${rows.length} строк)', style: headingStyle()),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  final invalid = r.productId == null;
                  return ListTile(
                    dense: true,
                    title: Text(r.productName.isEmpty ? 'Строка ${r.row}' : r.productName),
                    trailing: Text(
                      r.priceText.isEmpty ? '—' : r.priceText,
                      style: TextStyle(color: invalid ? AppColors.error : AppColors.textPrimary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Применить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editSinglePrice(
  BuildContext context,
  ClientDetailController controller,
  PriceSheetRow row,
) async {
  final priceController = TextEditingController(
    text: row.hasOwnPrice ? row.ownPrice.toString() : '',
  );
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.productName, style: headingStyle()),
          Text('Базовая цена: ${formatMoney(row.basePrice)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: priceController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Цена для этого склада (пусто = базовая)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    ),
  );
  if (saved != true || !context.mounted) return;

  final clientsRepository = Get.find<ClientsRepository>();
  final priceText = priceController.text.trim();
  final result = await clientsRepository.importPriceSheet(
    controller.client.value.id,
    [PriceImportRow(row: 1, productId: row.productId, price: priceText.isEmpty ? null : priceText)],
  );
  if (!context.mounted) return;
  if (!result.ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errors.isNotEmpty ? result.errors.first.message : 'Не удалось сохранить.')),
    );
    return;
  }
  await controller.loadPriceSheet();
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.redDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
