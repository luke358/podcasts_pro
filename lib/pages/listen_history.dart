import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/main/listen_history_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/episode_list.dart';

class ListenHistoryPage extends StatelessWidget {
  final ListenHistoryController _listenHistoryController =
      Get.find<ListenHistoryController>();
  final PlayerController _playerController = Get.find<PlayerController>();

  ListenHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收听记录'),
      ),
      body: Obx(() {
        final history = _listenHistoryController.listenHistory;

        if (history.isEmpty) {
          return const Center(child: Text('没有收听记录'));
        }

        return EpisodeList(
          episodes: history,
          playerController: _playerController,
          enableSlidable: true,
          onDelete: (p0) => _listenHistoryController.removeListenHistory(p0),
        );
      }),
    );
  }
}
