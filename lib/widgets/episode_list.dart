import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/episode_list_item.dart'; // 引入 EpisodeListItem

class EpisodeList extends StatelessWidget {
  final List<Episode> episodes;
  final PlayerController playerController;
  final bool enableSlidable;
  final Function(Episode)? onDelete;

  const EpisodeList({
    super.key,
    required this.episodes,
    required this.playerController,
    this.enableSlidable = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];

        return enableSlidable
            ? Slidable(
                key: ValueKey(episode.audioUrl),
                endActionPane: ActionPane(
                  extentRatio: 0.2,
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        onDelete?.call(episode);
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: '删除',
                    ),
                  ],
                ),
                child: EpisodeListItem(
                  episode: episode,
                  playerController: playerController,
                ),
              )
            : EpisodeListItem(
                key: ValueKey(episode.audioUrl),
                episode: episode,
                playerController: playerController,
              );
      },
    );
  }
}
