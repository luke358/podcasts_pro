import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/episode_list_item.dart';
import 'package:podcasts_pro/widgets/player_bar.dart';

class EpisodeDetailPage extends StatelessWidget {
  final Episode episode;

  const EpisodeDetailPage({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Scaffold(
      appBar: AppBar(
          // title: Text(episode.subscription.title),
          ),
      body: SafeArea(
        child: Column(
          children: [
            EpisodeListItem(
              episode: episode,
              playerController: playerController,
              isSubscriptionPage: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Html(
                    data: episode.descriptionHTML, // TODO: style format
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Obx(() {
          final hasCurrentEpisode =
              Get.find<PlayerController>().currentEpisode.value != null;
          return hasCurrentEpisode
              ? SizedBox(
                  height: 80,
                  child: PlayerBar(),
                )
              : const SizedBox.shrink(); // Empty widget if no current episode
        }),
      ),
    );
  }
}
