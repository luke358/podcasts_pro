// PlaylistItem.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/main/playback_position_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';

class PlaylistItem extends StatelessWidget {
  final Episode episode;
  final VoidCallback onDelete; // Callback for delete action

  const PlaylistItem(
      {super.key, required this.episode, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final playbackPositionController = Get.find<PlaybackPositionController>();

    return Obx(() {
      final playbackPosition =
          playbackPositionController.getPlaybackPosition(episode.audioUrl) ??
              Duration.zero;
      final duration = Duration(seconds: episode.durationInSeconds);
      final remaining = duration - playbackPosition;

      // Determine if the current episode is playing
      bool isPlaying = playerController.isCurrentEpisode(episode) &&
          playerController.playingState == PlayingState.playing;

      return Dismissible(
        key: ValueKey(episode.audioUrl),
        background: Container(
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          onDelete(); // Call the callback when item is dismissed
          return true;
        },
        // onDismissed: (direction) {
        // },
        child: ListTile(
          leading: episode.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: episode.imageUrl!,
                    httpHeaders: const {
                      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                    },
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    // Optionally, you can use cache management strategies here
                  ))
              : null,
          title: Text(
            episode.title,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '剩余: ${formatRemainingDuration(remaining)}',
            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: isPlaying ? Colors.red : Colors.blue,
            ),
            onPressed: () {
              if (isPlaying) {
                playerController.pause(); // Pause if currently playing
              } else {
                playerController.play(); // Play if currently paused
              }
            },
          ),
          onTap: () {
            // Optionally handle tap action
          },
        ),
      );
    });
  }
}

String formatRemainingDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$totalMinutes分钟 ${seconds.toString().padLeft(2, '0')}秒';
}
