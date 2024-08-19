import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/episode_detail.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';

class EpisodeListItem extends StatelessWidget {
  final Episode episode;
  final PlayerController playerController;

  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.playerController,
  });

  String formatDate(String pubDate) {
    try {
      final date = DateFormat('E, d MMM yyyy HH:mm:ss Z').parse(pubDate);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return pubDate;
    }
  }

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes min ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // final isCurrentEpisode = playerController.isCurrentEpisode(episode);
      final playingState = playerController.playingState;
      final isCurrentEpisode = playerController.isCurrentEpisode(episode);

      return ListTile(
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
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ))
            : null,
        title: Text(episode.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              'Published on: ${formatDate(episode.pubDate.toString())}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    playerController.add(episode);
                    // await audioHandler
                    //     .addQueueItem(mediaItemFromEpisode(episode));
                    // await audioHandler.play();
                    // if (isCurrentEpisode && isPlaying) {
                    //   // playerController.pause();
                    // } else {
                    //   // playerController.playEpisode(episode);
                    // }
                  },
                  icon: isCurrentEpisode
                      ? playingState == PlayingState.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 5),
                            )
                          : Icon(
                              playingState == PlayingState.paused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              size: 24,
                            )
                      : const Icon(Icons.play_arrow, size: 24),
                  label: Text(
                    formatDuration(episode.durationInSeconds),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    playerController.add(episode);
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text("稍后听"),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EpisodeDetailPage(episode: episode),
            ),
          );
        },
      );
    });
  }
}
