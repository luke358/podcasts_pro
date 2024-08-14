import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/episode_list.dart';

class ListenHistoryPage extends StatelessWidget {
  final PlayerController playerController = Get.find<PlayerController>();

  ListenHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收听记录'),
      ),
      body: Obx(() {
        final history = playerController.listenHistory;

        if (history.isEmpty) {
          return const Center(child: Text('没有收听记录'));
        }

        return EpisodeList(
          episodes: history,
          playerController: playerController,
          enableSlidable: true,
          onDelete: (p0) => playerController.removeListenHistory(p0),
        );
      }),
    );
  }
}
