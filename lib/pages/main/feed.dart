import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/http/podcast_manager.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/add_subscription.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';
import 'package:podcasts_pro/pages/my_subscriptions.dart';
import 'package:podcasts_pro/widgets/episode_list.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with AutomaticKeepAliveClientMixin<FeedPage> {
  final PlayerController _playerController = Get.find<PlayerController>();
  final SubscriptionController _subscriptionController =
      Get.find<SubscriptionController>();
  late PodcastManager _podcastManager;

  @override
  void initState() {
    super.initState();
    _podcastManager = PodcastManager();
  }

  Future<List<List<Episode>>> _loadFeedList() async {
    try {
      final subscriptions = _subscriptionController.subscriptions;

      if (subscriptions.isEmpty) {
        return Future.error(
            'No subscriptions found. Please add some subscriptions.');
      }

      return _podcastManager.fetchAllEpisodes();
    } catch (e) {
      print('Error loading feed list: $e');
      return Future.error('Error loading feed list: $e');
    }
  }

  Future<void> _refreshData() async {
    try {
      final refreshedEpisodes = await _podcastManager.fetchAllEpisodes(
        forceRefresh: true,
        useCacheOnError: true,
      );
      if (refreshedEpisodes.isEmpty || refreshedEpisodes[0].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No episodes available. Please check your connection.'),
          ),
        );
      } else {
        setState(() {
          // Only update the future if successful data is fetched
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing data: $e'),
        ),
      );
    }
  }

  void _navigateToSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MySubscriptionsPage()),
    );
  }

  void _navigateToAddSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSubscriptionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcast Feed'),
        actions: [
          TextButton.icon(
            onPressed: _navigateToSubscriptions,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('我的订阅节目'),
          ),
        ],
      ),
      body: Obx(() {
        if (_subscriptionController.subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No subscriptions found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToAddSubscriptions,
                  child: const Text('Add Subscriptions'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: FutureBuilder<List<List<Episode>>>(
            future: _loadFeedList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading feed list: ${snapshot.error}'),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No episodes found'));
              } else {
                final flatEpisodes = snapshot.data!.expand((e) => e).toList();
                return EpisodeList(
                  episodes: flatEpisodes,
                  playerController: _playerController,
                );
              }
            },
          ),
        );
      }),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
