import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/config/route.dart';
import 'package:podcasts_pro/config/theme.dart';
import 'package:podcasts_pro/pages/main/playback_position_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/pages/player.dart';
import 'package:podcasts_pro/pages/playlist.dart';
import 'package:podcasts_pro/widgets/play_button.dart';
import 'package:podcasts_pro/widgets/playlist_item.dart';

class PlayerBar extends StatelessWidget {
  PlayerBar({super.key});
  final PlayerController playerController = Get.find<PlayerController>();
  final PlaybackPositionController playbackPositionController =
      Get.find<PlaybackPositionController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (playerController.currentEpisode.value == null) {
        return const SizedBox.shrink();
      }

      final episode = playerController.currentEpisode.value!;
      final playbackPosition =
          playbackPositionController.getPlaybackPosition(episode.audioUrl) ??
              Duration.zero;

      final duration = Duration(seconds: episode.durationInSeconds);
      final remaining = duration - playbackPosition;

      return Align(
        alignment: Alignment.bottomCenter,
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(Bottom2TopPageRoute(page: const PlayerPage()));
          },
          child: Material(
            elevation: 10.0,
            color: ThemeColor.page,
            child: Container(
              height: 80,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Left: Image
                  if (playerController.currentEpisode.value?.imageUrl != null ||
                      playerController
                              .currentEpisode.value?.subscription.imageUrl !=
                          null)
                    Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: playerController
                                      .currentEpisode.value!.imageUrl ??
                                  playerController.currentEpisode.value!
                                      .subscription.imageUrl,
                              httpHeaders: const {
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                              },
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ))),
                  // Center: Title and Remaining Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playerController.currentEpisode.value?.title ??
                              'No Episode Playing',
                          style: const TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '剩余: ${formatRemainingDuration(remaining)}',
                          style: const TextStyle(
                              fontSize: 14.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Right: Play, Playlist Icons
                  Row(
                    children: [
                      PlayButton(
                        episode: playerController.currentEpisode.value!,
                        size: 25,
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(Icons.playlist_play),
                        onPressed: () {
                          Navigator.push(
                            context,
                            Right2LeftPageRoute(
                              page: PlaylistPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
