import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/get_utils.dart';
import '../../../data/clients_repository.dart';
import '../../../widgets/client_avatar.dart';
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
        if (controller.isLoading.value) return const LoadingView();
        if (controller.errorMessage.value != null) {
          return ErrorView(message: controller.errorMessage.value!, onRetry: controller.reload);
        }
        if (controller.clients.isEmpty) {
          return const Center(child: Text('Пока нет клиентов.'));
        }
        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView.separated(
            itemCount: controller.clients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final client = controller.clients[index];
              return ListTile(
                title: Text(client.name),
                subtitle: Text([client.phone, client.address].whereType<String>().join(' · ')),
                leading: ClientAvatar(name: client.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(() => ClientDetailScreen(client: client)),
              );
            },
          ),
        );
      }),
    );
  }
}
