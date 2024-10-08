import 'package:flutter/material.dart';
import 'package:flutter_splash_screen/flutter_splash_screen.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/config/route.dart';
import 'package:podcasts_pro/config/theme.dart';
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
  List<Episode> _episodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _podcastManager = PodcastManager();
    _initialLoadData();

    // 监听订阅数据变化并添加防抖处理
    debounce(_subscriptionController.subscriptions, (_) {
      _loadData();
    }, time: const Duration(milliseconds: 500)); // 设置防抖延迟时间
  }

  // 初次加载数据
  Future<void> _initialLoadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _loadData();
    } finally {
      FlutterSplashScreen.hide();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 加载数据（不显示loading）
  Future<void> _refreshData() async {
    await _loadData(forceRefresh: true);
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      final subscriptions = _subscriptionController.subscriptions;
      if (subscriptions.isEmpty) {
        return;
      }

      final fetchedEpisodes = await _podcastManager.fetchAllEpisodes(
        forceRefresh: forceRefresh,
        useCacheOnError: true,
      );

      if (fetchedEpisodes.isEmpty || fetchedEpisodes[0].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No episodes available. Please check your connection.'),
          ),
        );
      } else {
        setState(() {
          _episodes = fetchedEpisodes.expand((e) => e).toList();
          // _playerController.playlist.value = _episodes;
          // _playerController.savePlaylist();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
        ),
      );
    }
  }

  void _navigateToSubscriptions() {
    Navigator.push(
      context,
      Right2LeftPageRoute(page: const MySubscriptionsPage()),
    );
  }

  void _navigateToAddSubscriptions() {
    Navigator.push(
      context,
      Right2LeftPageRoute(page: AddSubscriptionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新'),
        actions: [
          TextButton.icon(
              onPressed: _navigateToSubscriptions,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('我的订阅节目'),
              style: ButtonStyle(
                iconColor: WidgetStateProperty.resolveWith(
                    (states) => ThemeColor.primary),
                foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => ThemeColor.primary),
              )),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Obx(() {
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
                child: EpisodeList(
                  episodes: _episodes,
                  playerController: _playerController,
                ),
              );
            }),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
