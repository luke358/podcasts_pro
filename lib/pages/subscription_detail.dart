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

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage>
    with AutomaticKeepAliveClientMixin<SubscriptionDetailPage> {
  List<Episode> _episodes = [];
  bool _isLoading = true;
  late Subscription _subscription;
  final PlayerController _playerController = Get.find<PlayerController>();
  final SubscriptionController _subscriptionController =
      Get.find<SubscriptionController>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initialLoadData();
  }

  // Initial data loading with loading indicator
  void _initialLoadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
    setState(() {
      _isLoading = false;
    });
  }

  // Load data without showing loading indicator (for pull-to-refresh)
  Future<void> _onRefresh() async {
    await _loadData(forceRefresh: true);
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      try {
        _episodes = await PodcastService(widget.rssUrl)
            .fetchEpisodes(forceRefresh: forceRefresh);
        // ignore: empty_catches
      } catch (e) {}
      if (_episodes.isEmpty) {
        _subscription = await Subscription.fromRssUrl(widget.rssUrl);
      } else {
        _subscription = _episodes[0].subscription;
      }
    } catch (e) {
      // Handle error, e.g., log it or show a message
      print('Error loading data: $e');
    }
    setState(() {});
  }

  void _toggleSubscription() async {
    await _subscriptionController.toggleSubscription(_subscription);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: PodcastHeader(
                          subscription: _subscription,
                          onSubscriptionToggle: _toggleSubscription,
                          isSubscribed: _subscriptionController
                              .isSubscribed(widget.rssUrl),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final episode = _episodes[index];
                            return EpisodeListItem(
                              episode: episode,
                              playerController: _playerController,
                            );
                          },
                          childCount: _episodes.length,
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
              ),
            ),
    );
  }
}
