import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/config/theme.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';

class PlayButton extends StatelessWidget {
  final PlayerController playerController = Get.find<PlayerController>();
  final double size;
  final Episode episode;
  PlayButton({super.key, this.size = 48, required this.episode}); // 设置默认大小为 48

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final playingState = playerController.playingState;
      bool isCurrentEpisode = playerController.isCurrentEpisode(episode);
      return IconButton(
        iconSize: size, // 使用传入的 size
        icon: isCurrentEpisode
            ? playingState.value == PlayingState.loading
                ? SizedBox(
                    width: size,
                    height: size,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                    ))
                : Icon(
                    playingState.value == PlayingState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: playingState.value == PlayingState.playing
                        ? Colors.red
                        : ThemeColor.active,
                    size: size,
                  )
            : const Icon(
                Icons.play_arrow,
              ),
        onPressed: () {
          if (PlayingState.playing == playingState.value && isCurrentEpisode) {
            playerController.pause();
          } else {
            playerController.play(episode);
          }
        },
      );
    });
  }
}
