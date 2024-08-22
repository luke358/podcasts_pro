import 'package:flutter/material.dart';
import 'package:podcasts_pro/config/route.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:intl/intl.dart';
import 'package:podcasts_pro/pages/episode_detail.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/cache_image.dart';
import 'package:podcasts_pro/widgets/play_button.dart';

class EpisodeListItem extends StatelessWidget {
  final Episode episode;
  final PlayerController playerController;
  final bool isSubscriptionPage;
  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.playerController,
    this.isSubscriptionPage = false,
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
    return InkWell(
      onTap: isSubscriptionPage
          ? null
          : () {
              Navigator.push(
                context,
                Right2LeftPageRoute(
                    page: EpisodeDetailPage(
                  episode: episode,
                )),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CacheImage(
                  url: episode.imageUrl ?? episode.subscription.imageUrl,
                  size: 80,
                )),
            const SizedBox(width: 16.0),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    episode.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4.0),
                  // Description
                  Text(
                    isSubscriptionPage
                        ? episode.subscription.title
                        : episode.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4.0),
                  // Published Date
                  Text(
                    'Published on: ${formatDate(episode.pubDate.toString())}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8.0),
                  // Actions
                  Row(
                    children: [
                      PlayButton(episode: episode, size: 28),
                      const SizedBox(width: 8.0),
                      TextButton.icon(
                        onPressed: () {
                          if (playerController.playlist.isEmpty) {
                            playerController.play(episode);
                          } else {
                            playerController.add(episode);
                          }
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: const Text("稍后听"),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
