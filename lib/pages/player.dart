import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/config/route.dart';
import 'package:podcasts_pro/pages/episode_detail.dart';
import 'package:podcasts_pro/pages/main/favorite_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'package:podcasts_pro/pages/subscription_detail.dart';
import 'package:podcasts_pro/widgets/play_button.dart';
import 'package:podcasts_pro/widgets/playlist_item.dart';
import 'package:podcasts_pro/widgets/progress_bar.dart';

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
        // title: const Text('Player'),
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
                          imageUrl:
                              episode.imageUrl ?? episode.subscription.imageUrl,
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
                            Right2LeftPageRoute(
                                page: EpisodeDetailPage(episode: episode)));
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
                          Right2LeftPageRoute(
                            page: SubscriptionDetailPage(
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
                      // duration: Duration(seconds: episode.durationInSeconds),
                      duration: playerController.currentDuration.value,
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
                            showModalBottomSheet<double>(
                              context: context,
                              builder: (BuildContext context) {
                                return SizedBox(child: Obx(() {
                                  double currentSpeed = playerController
                                      .playbackSpeed.value; // 使用当前播放速度初始化
                                  int selectedTime =
                                      playerController.stopTime.value;
                                  bool isTimerEnabled =
                                      playerController.isStopTimerEnabled.value;
                                  bool isEndOfEpisodeTimerEnabled =
                                      playerController
                                          .isEndOfEpisodeStopTimerEnabled.value;

                                  int minutes = playerController
                                          .remainingStopTimeInSeconds.value ~/
                                      60;
                                  int seconds = playerController
                                          .remainingStopTimeInSeconds.value %
                                      60;
                                  return Column(
                                    children: [
                                      Container(
                                        height:
                                            80, // Height for playback speed options
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (currentSpeed != 0.5) {
                                                    playerController
                                                        .setSpeed(0.5);
                                                    setState(() {
                                                      currentSpeed = 0.5;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  color: currentSpeed == 0.5
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Center(
                                                      child: Text('0.5x',
                                                          style: TextStyle(
                                                            color:
                                                                currentSpeed ==
                                                                        0.5
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ))),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (currentSpeed != 1.0) {
                                                    playerController
                                                        .setSpeed(1.0);
                                                    setState(() {
                                                      currentSpeed = 1.0;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  color: currentSpeed == 1.0
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Center(
                                                      child: Text('1.0x',
                                                          style: TextStyle(
                                                            color:
                                                                currentSpeed ==
                                                                        1.0
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ))),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (currentSpeed != 1.5) {
                                                    playerController
                                                        .setSpeed(1.5);
                                                    setState(() {
                                                      currentSpeed = 1.5;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  color: currentSpeed == 1.5
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Center(
                                                      child: Text('1.5x',
                                                          style: TextStyle(
                                                            color:
                                                                currentSpeed ==
                                                                        1.5
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ))),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (currentSpeed != 2.0) {
                                                    playerController
                                                        .setSpeed(2.0);
                                                    setState(() {
                                                      currentSpeed = 2.0;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  color: currentSpeed == 2.0
                                                      ? Colors.blue
                                                      : Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Center(
                                                      child: Text('2.0x',
                                                          style: TextStyle(
                                                            color:
                                                                currentSpeed ==
                                                                        2.0
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                          ))),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    '定时关闭: ${isTimerEnabled ? '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}' : ''}',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Switch(
                                                  value: isTimerEnabled,
                                                  onChanged: (bool value) {
                                                    playerController
                                                        .toggleTimer(value);
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const Text('设置定时关闭时间:',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 10,
                                              children: [
                                                600,
                                                1200,
                                                1800,
                                                2700,
                                                3600,
                                                5400
                                              ].map((time) {
                                                return ChoiceChip(
                                                  label: Text(
                                                      '${time ~/ 60} min'), // Display time in minutes
                                                  selected: selectedTime ==
                                                          time.toDouble() &&
                                                      isTimerEnabled &&
                                                      !isEndOfEpisodeTimerEnabled,
                                                  onSelected: (value) {
                                                    playerController
                                                        .stopTime.value = time;
                                                    playerController
                                                        .toggleTimer(true);
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                                '自定义关闭时间: ${formatRemainingDuration(Duration(seconds: selectedTime))} minutes'),
                                            Slider(
                                              value: selectedTime * 1.0,
                                              min: 600,
                                              max: 5400,
                                              // divisions: 5400 - 600,
                                              label: selectedTime
                                                  .toStringAsFixed(0),
                                              onChanged: (value) {
                                                playerController.stopTime
                                                    .value = value.toInt();
                                                playerController
                                                    .toggleTimer(true);
                                              },
                                            ),
                                            const SizedBox(
                                              height: 8,
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text('播完整集再停止播放:',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Switch(
                                                  value:
                                                      isEndOfEpisodeTimerEnabled,
                                                  onChanged: (bool value) {
                                                    playerController
                                                        .toggleEndOfEpisodeTimer(
                                                            value);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }));
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Obx(() {
                          final hasMore = playerController.playlist.length > 1;
                          return IconButton(
                            icon: Icon(Icons.skip_previous,
                                color: hasMore ? Colors.black : Colors.grey),
                            onPressed: () {
                              if (hasMore) {
                                playerController.prev();
                              }
                            },
                          );
                        }),
                        const SizedBox(width: 16),
                        PlayButton(episode: episode),
                        const SizedBox(width: 16),
                        Obx(() {
                          final hasMore = playerController.playlist.length > 1;
                          return IconButton(
                            icon: Icon(Icons.skip_next,
                                color: hasMore ? Colors.black : Colors.grey),
                            onPressed: () {
                              if (hasMore) {
                                playerController.next();
                              }
                            },
                          );
                        }),
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
