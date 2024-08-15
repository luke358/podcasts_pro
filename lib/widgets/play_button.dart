import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';

class PlayButton extends StatelessWidget {
  final PlayerController playerController = Get.find<PlayerController>();
  final double size;

  PlayButton({super.key, this.size = 48}); // 设置默认大小为 48

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = playerController.isLoading.value;
      final isPlaying = playerController.isPlaying.value;

      return IconButton(
        iconSize: size, // 使用传入的 size
        icon: isLoading
            ? SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(strokeWidth: 5),
              )
            : Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: size,
              ),
        onPressed: () {
          if (!isLoading) {
            if (isPlaying) {
              playerController.pause();
            } else {
              playerController.play();
            }
          }
        },
      );
    });
  }
}
