import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/pages/episode_detail.dart';
import 'package:podcasts_pro/pages/main/favorite_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'package:podcasts_pro/pages/subscription_detail.dart';
import 'package:podcasts_pro/widgets/play_button.dart';
import 'package:podcasts_pro/widgets/progress_bar.dart'; // Import ProgressBar component

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with AutomaticKeepAliveClientMixin<PlayerPage> {
  final PlayerController playerController = Get.find<PlayerController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Player'),
      ),
      body: SafeArea(
        child: Obx(() {
          final episode = playerController.currentEpisode.value;

          if (episode == null) {
            return const Center(child: Text('No episode selected.'));
          }

          final formattedDate =
              DateFormat('yyyy-MM-dd a h:mm').format(episode.pubDate);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 90.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: episode.imageUrl!,
                          httpHeaders: const {
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                          },
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )),
                    const SizedBox(height: 16),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EpisodeDetailPage(episode: episode),
                          ),
                        );
                      },
                      child: Text(
                        episode.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Subscription 信息
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionDetailPage(
                              rssUrl: episode.subscription.rssUrl, // 传递 rssUrl
                              title: episode.subscription.title,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: episode.subscription.imageUrl,
                              httpHeaders: const {
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                              },
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '单集来自',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                episode.subscription.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  children: [
                    ProgressBar(
                      duration: Duration(seconds: episode.durationInSeconds),
                      playbackPosition: playerController.currentPosition.value,
                      onSeek: playerController.seek,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.speed),
                          onPressed: () {
                            // 弹出一个对话框，让用户选择播放速度
                            showDialog<double>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('选择播放速度'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: const Text('0.5x'),
                                        onTap: () {
                                          // playerController.setSpeed(0.5);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('1.0x'),
                                        onTap: () {
                                          // playerController.setSpeed(1.0);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('1.5x'),
                                        onTap: () {
                                          // playerController.setSpeed(1.5);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('2.0x'),
                                        onTap: () {
                                          // playerController.setSpeed(2.0);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () {
                            // playerController.prev();
                          },
                        ),
                        const SizedBox(width: 16),
                        PlayButton(),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: () {
                            // playerController.next();
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Obx(() {
                            final isFavorite =
                                favoriteController.isFavorite(episode);
                            return Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.black,
                            );
                          }),
                          onPressed: () {
                            favoriteController.addEpisodeToFavorites(episode);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
