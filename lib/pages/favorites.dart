import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/episode_list.dart'; // 假设你已经有一个用于渲染 Episode 列表的组件

class FavoritesPage extends StatelessWidget {
  FavoritesPage({super.key});

  final PlayerController playerController = Get.find<PlayerController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: Obx(() {
        final favoriteEpisodes = playerController.favoriteEpisodes;
        if (favoriteEpisodes.isEmpty) {
          return const Center(child: Text('No favorites yet.'));
        }
        return EpisodeList(
          episodes: favoriteEpisodes,
          playerController: playerController,
          enableSlidable: true,
          onDelete: (p0) => playerController.removeFavoriteEpisode(p0),
        );
      }),
    );
  }
}
