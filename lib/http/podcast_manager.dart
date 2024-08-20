import 'dart:math';

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:podcasts_pro/http/podcast_service.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';

class PodcastManager {
  final SubscriptionController _subscriptionController =
      Get.find<SubscriptionController>();

  Future<List<List<Episode>>> fetchAllEpisodes({
    bool forceRefresh = false,
    bool useCacheOnError = true,
    int batchSize = 5, // 每次拉取的 RSS 源数量
    int maxEpisodes = 100, // 返回的最大 Episode 数量
  }) async {
    try {
      final rssUrls =
          _subscriptionController.subscriptions.map((s) => s.rssUrl).toList();
      final totalUrls = rssUrls.length;
      final List<List<Episode>> allEpisodes = [];

      for (int i = 0; i < totalUrls; i += batchSize) {
        final batchUrls = rssUrls.sublist(i, min(i + batchSize, totalUrls));
        final List<Future<List<Episode>>> fetchTasks =
            batchUrls.map((url) async {
          try {
            final service = PodcastService(url);
            return await service.fetchEpisodes(
              forceRefresh: forceRefresh,
              useCacheOnError: useCacheOnError,
            );
          } catch (e) {
            print('Error fetching episodes from $url: $e');
            return <Episode>[];
          }
        }).toList();

        final batchEpisodes =
            (await Future.wait(fetchTasks)).expand((e) => e).toList();
        batchEpisodes.sort((a, b) => b.pubDate.compareTo(a.pubDate));
        allEpisodes.add(batchEpisodes
            .take(maxEpisodes ~/ (totalUrls ~/ batchSize))
            .toList());
      }

      return allEpisodes;
    } catch (e) {
      print('Error fetching all episodes: $e');
      return [];
    }
  }
}
