import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/http/podcast_service.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';
import 'package:podcasts_pro/widgets/episode_list_item.dart';
import 'package:podcasts_pro/widgets/player_bar.dart';
import 'package:podcasts_pro/widgets/podcast_header.dart';

class SubscriptionDetailPage extends StatefulWidget {
  final String rssUrl;
  final String title;

  const SubscriptionDetailPage({
    super.key,
    required this.rssUrl,
    required this.title,
  });

  @override
  _SubscriptionDetailPageState createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  late Future<List<Episode>> _episodesFuture;
  late Future<Subscription> _subscriptionFuture;
  late Subscription _subscription;
  final PlayerController _playerController = Get.find<PlayerController>();
  final SubscriptionController _subscriptionController =
      Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();
    _episodesFuture = PodcastService(widget.rssUrl).fetchEpisodes();
    _subscriptionFuture = Subscription.fromRssUrl(widget.rssUrl);

    // Fetch and save subscription instance
    _subscriptionFuture.then((subscription) {
      setState(() {
        _subscription = subscription;
      });
    });
  }

  void _toggleSubscription() async {
    await _subscriptionController.toggleSubscription(_subscription);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Episode>>(
        future: _episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No episodes found'));
          } else {
            final episodes = snapshot.data!;
            return FutureBuilder<Subscription>(
              future: _subscriptionFuture,
              builder: (context, subscriptionSnapshot) {
                if (subscriptionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (subscriptionSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${subscriptionSnapshot.error}'));
                } else if (!subscriptionSnapshot.hasData) {
                  return const Center(
                      child: Text('Subscription status unknown'));
                } else {
                  return Obx(() {
                    final isSubscribed =
                        _subscriptionController.isSubscribed(widget.rssUrl);
                    return Stack(
                      children: [
                        CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: PodcastHeader(
                                subscription: _subscription,
                                onSubscriptionToggle: _toggleSubscription,
                                isSubscribed: isSubscribed,
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final episode = episodes[index];
                                  return EpisodeListItem(
                                    episode: episode,
                                    playerController: _playerController,
                                  );
                                },
                                childCount: episodes.length,
                              ),
                            ),
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 80.0),
                            ), // Add padding here to avoid overlap
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: PlayerBar(), // Bottom player bar
                        ),
                      ],
                    );
                  });
                }
              },
            );
          }
        },
      ),
    );
  }
}
