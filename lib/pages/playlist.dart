// PlaylistPage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/playlist_item.dart'; // Import the PlaylistItem widget

class PlaylistPage extends StatelessWidget {
  final PlayerController playerController = Get.find<PlayerController>();

  PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              playerController.clearPlaylist(); // Clear playlist logic
            },
          ),
        ],
      ),
      body: Obx(() {
        final playlist = playerController.playlist;
        if (playlist.isEmpty) {
          return const Center(
            child: Text('Playlist is empty'),
          );
        }
        return ListView.builder(
          itemCount: playlist.length,
          itemBuilder: (context, index) {
            final episode = playlist[index];
            return PlaylistItem(
              episode: episode,
              onDelete: () {
                playerController.remove(episode); // Remove item logic
              },
            );
          },
        );
      }),
    );
  }
}
