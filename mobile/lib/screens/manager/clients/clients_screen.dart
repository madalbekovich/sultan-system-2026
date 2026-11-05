import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/tokens.dart';
import '../../../data/clients_repository.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/stamp_badge.dart';
import '../../../widgets/status_views.dart';
import 'client_detail_screen.dart';
import 'client_form_sheet.dart';
import 'clients_controller.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = putOnce(
      () => ClientsController(Get.find<ClientsRepository>()),
      tag: 'clients',
    )..reload();

    return Scaffold(
      appBar: AppBar(title: const Text('Склады')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showClientFormSheet(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Поиск по названию, коду или телефону…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
            child: Obx(() => Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Показать архив'),
                    selected: controller.showArchived.value,
                    onSelected: (v) => controller.showArchived.value = v,
                  ),
                )),
          ),
          Expanded(
            child: Obx(() {
              final Widget content;
              final items = controller.filteredClients;
              if (controller.isLoading.value) {
                content = const SkeletonCardList(key: ValueKey('skeleton'));
              } else if (controller.errorMessage.value != null) {
                content = ErrorView(
                  key: const ValueKey('error'),
                  message: controller.errorMessage.value!,
                  onRetry: controller.reload,
                );
              } else if (items.isEmpty) {
                content = const Center(key: ValueKey('empty'), child: Text('Ничего не найдено.'));
              } else {
                content = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: controller.reload,
                  child: ListView.separated(
                    padding: EdgeInsets.only(bottom: 80 + MediaQuery.of(context).padding.bottom),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = items[index];
                      return StaggeredFadeIn(
                        index: index,
                        child: Opacity(
                          opacity: client.isArchived ? 0.5 : 1,
                          child: ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(client.name)),
                              StampBadge(label: client.clientCode, color: AppColors.steelBlue),
                            ],
                          ),
                          subtitle: Text(
                            [
                              formatPhone(client.phone),
                              client.address ?? '',
                              client.isArchived ? 'В архиве' : '',
                              client.isBound ? '' : 'Telegram не привязан',
                            ].where((s) => s.isNotEmpty).join(' · '),
                          ),
                          leading: Hero(
                            tag: 'client-avatar-${client.id}',
                            child: ClientAvatar(name: client.name),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Get.to(() => ClientDetailScreen(client: client)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: AppCurves.enter,
                child: content,
              );
            }),
          ),
        ],
      ),
    );
  }
}
