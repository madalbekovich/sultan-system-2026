import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/formatting.dart';
import '../../../core/get_utils.dart';
import '../../../core/tokens.dart';
import '../../../data/clients_repository.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/fade_in.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/status_views.dart';
import 'client_detail_screen.dart';
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
      appBar: AppBar(title: const Text('Клиенты')),
      body: Obx(() {
        final Widget content;
        if (controller.isLoading.value) {
          content = const SkeletonCardList(key: ValueKey('skeleton'));
        } else if (controller.errorMessage.value != null) {
          content = ErrorView(
            key: const ValueKey('error'),
            message: controller.errorMessage.value!,
            onRetry: controller.reload,
          );
        } else if (controller.clients.isEmpty) {
          content = const Center(key: ValueKey('empty'), child: Text('Пока нет клиентов.'));
        } else {
          content = RefreshIndicator(
            key: const ValueKey('list'),
            onRefresh: controller.reload,
            child: ListView.separated(
              itemCount: controller.clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final client = controller.clients[index];
                return StaggeredFadeIn(
                  index: index,
                  child: ListTile(
                    title: Text(client.name),
                    subtitle: Text(
                      [formatPhone(client.phone), client.address ?? '']
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                    ),
                    leading: Hero(
                      tag: 'client-avatar-${client.id}',
                      child: ClientAvatar(name: client.name),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.to(() => ClientDetailScreen(client: client)),
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
    );
  }
}
