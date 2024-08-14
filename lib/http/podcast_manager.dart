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
  }) async {
    try {
      final rssUrls =
          _subscriptionController.subscriptions.map((s) => s.rssUrl).toList();

      final List<Future<List<Episode>>> fetchTasks = rssUrls.map((url) {
        final service = PodcastService(url);
        return service.fetchEpisodes(
          forceRefresh: forceRefresh,
          useCacheOnError: useCacheOnError,
        );
      }).toList();

      // 使用 Future.wait 并发执行所有 fetchTasks
      final List<List<Episode>> allEpisodes = await Future.wait(fetchTasks);

      // Flatten the list and sort episodes by publication date
      final flattenedEpisodes = allEpisodes.expand((e) => e).toList();
      flattenedEpisodes.sort(
          (a, b) => b.pubDate.compareTo(a.pubDate)); // Sort in descending order

      // Limit the number of episodes to 100
      return [flattenedEpisodes.take(100).toList()];
    } catch (e) {
      print('Error fetching all episodes: $e');
      return []; // 返回空列表或根据需要处理错误
    }
  }
}
