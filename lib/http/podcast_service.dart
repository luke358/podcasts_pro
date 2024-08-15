import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:podcasts_pro/http/podcast_cache_manager.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html_parser; // 添加 HTML 解析库
import 'package:intl/intl.dart';

class PodcastService {
  final String rssUrl;

  PodcastService(this.rssUrl);

  Future<String> fetchSubscriptionData() async {
    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return body;
      } else {
        throw Exception('Failed to load RSS feed');
      }
    } catch (e) {
      print('Error fetching subscription data: $e');
      throw e;
    }
  }

  Future<List<Episode>> fetchEpisodes({
    bool forceRefresh = false,
    bool useCacheOnError = true,
  }) async {
    if (forceRefresh) {
      print("强制刷新");
      // 强制刷新时从网络请求数据
      try {
        final episodes = await _fetchAndCacheEpisodes();
        return episodes;
      } catch (e) {
        print('Error fetching from network: $e');
        if (useCacheOnError) {
          final cachedData = await PodcastCacheManager.getCachedFile(rssUrl,
              ignoreCacheValidity: true);
          if (cachedData != null) {
            return _parseEpisodes(cachedData, rssUrl);
          } else {
            throw Exception(
                'Failed to load podcast episodes and no cache available');
          }
        } else {
          throw e;
        }
      }
    } else {
      // 尝试从缓存中获取数据
      final cachedData = await PodcastCacheManager.getCachedFile(rssUrl);
      if (cachedData != null) {
        print("使用 cachedData");

        return _parseEpisodes(cachedData, rssUrl);
      }

      // 如果缓存不存在或过期，从网络获取数据
      try {
        print("缓存不存在或过期，从网络获取数据");
        final episodes = await _fetchAndCacheEpisodes();
        return episodes;
      } catch (e) {
        print('Error fetching from network: $e');
        if (useCacheOnError) {
          // 尝试从缓存中获取过期数据
          final cachedData = await PodcastCacheManager.getCachedFile(rssUrl,
              ignoreCacheValidity: true);
          if (cachedData != null) {
            return _parseEpisodes(cachedData, rssUrl);
          } else {
            throw Exception(
                'Failed to load podcast episodes and no cache available');
          }
        } else {
          throw e;
        }
      }
    }
  }

  Future<List<Episode>> _fetchAndCacheEpisodes() async {
    final response =
        await http.get(Uri.parse(rssUrl)).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      await PodcastCacheManager.cacheFile(rssUrl, body);
      return _parseEpisodes(body, rssUrl);
    } else {
      throw Exception('Failed to load podcast episodes');
    }
  }

  List<Episode> _parseEpisodes(String xmlString, String rssUrl) {
    final document = xml.XmlDocument.parse(xmlString);

    // 先解析并获取 Subscription 信息
    final subscription = Subscription.parseSubscription(xmlString, rssUrl);

    final items = document.findAllElements('item');
    List<Episode> episodes = [];

    for (var item in items) {
      final titleElement = item.findElements('title').single;
      final descriptionElement = item.findElements('description').single;
      final pubDateElement = item.findElements('pubDate').single;
      final audioUrlElement = item.findElements('enclosure').single;
      final durationElement = item.findElements('itunes:duration').single;
      final imageElement = item.findElements('itunes:image').single;

      final title = titleElement.text;
      final descriptionHTML = descriptionElement.text;
      final pubDate = pubDateElement.text;
      final audioUrl = audioUrlElement.getAttribute('url');
      final durationInSeconds = parseDurationToSeconds(durationElement.text);
      final imageUrl = imageElement.getAttribute('href');
      // 创建 Episode 对象时，附带 Subscription 信息
      episodes.add(Episode(
        title: title,
        descriptionHTML: descriptionHTML,
        pubDate: DateFormat('E, d MMM yyyy HH:mm:ss Z').parse(pubDate),
        audioUrl: audioUrl,
        durationInSeconds: durationInSeconds,
        imageUrl: imageUrl,
        subscription: subscription, // 传入 Subscription
      ));
    }

    return episodes;
  }

  int parseDurationToSeconds(String durationStr) {
    final parts = durationStr.split(':');
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    if (parts.length == 3) {
      hours = int.parse(parts[0]);
      minutes = int.parse(parts[1]);
      seconds = int.parse(parts[2]);
    } else if (parts.length == 2) {
      minutes = int.parse(parts[0]);
      seconds = int.parse(parts[1]);
    } else if (parts.length == 1) {
      seconds = int.parse(parts[0]);
    }

    return hours * 3600 + minutes * 60 + seconds;
  }

  String parseHtml(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }
}
