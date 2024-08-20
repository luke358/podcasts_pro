// PlaylistItem.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/episode_detail.dart';
import 'package:podcasts_pro/pages/main/playback_position_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/cache_image.dart';
import 'package:podcasts_pro/widgets/play_button.dart';

class PlaylistItem extends StatelessWidget {
  final Episode episode;
  final VoidCallback onDelete; // Callback for delete action

  const PlaylistItem(
      {super.key, required this.episode, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final playbackPositionController = Get.find<PlaybackPositionController>();
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final playbackPosition =
          playbackPositionController.getPlaybackPosition(episode.audioUrl) ??
              Duration.zero;
      // final duration = Duration(seconds: episode.durationInSeconds);
      final duration = playerController.currentDuration.value;
      final remaining = duration - playbackPosition;

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
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodeDetailPage(episode: episode),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CacheImage(
                      url: episode.imageUrl ?? episode.subscription.imageUrl,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          episode.title,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        // Subtitle (Remaining time)
                        Text(
                          '剩余: ${formatRemainingDuration(remaining)}',
                          style: const TextStyle(
                              fontSize: 14.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Trailing PlayButton
                  PlayButton(
                    episode: episode,
                    size: 28,
                  ),
                ],
              ),
            ),
          ));
    });
  }
}

String formatRemainingDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$totalMinutes分钟 ${seconds.toString().padLeft(2, '0')}秒';
}
