import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:podcasts_pro/http/podcast_cache_manager.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

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

FutureOr<List<Episode>> parseEpisodes(ParserParams params) async {
  final document = xml.XmlDocument.parse(params.xmlString);

  // 先解析并获取 Subscription 信息
  final subscription = Subscription.parseSubscription(document, params.rssUrl);

  final items = document.findAllElements('item');
  List<Episode> episodes = [];

  for (var item in items) {
    final titleElement = item.findElements('title').single;
    final descriptionElement = item.findElements('description').single;
    final pubDateElement = item.findElements('pubDate').single;
    final audioUrlElement = item.findElements('enclosure').single;
    final durationElement = item.findElements('itunes:duration').firstOrNull;
    final imageElement = item.findElements('itunes:image').firstOrNull;

    final title = titleElement.text;
    final descriptionHTML = descriptionElement.text;
    final pubDate = pubDateElement.text;
    final audioUrl = audioUrlElement.getAttribute('url');
    final durationInSeconds = durationElement != null
        ? parseDurationToSeconds(durationElement.text)
        : null;
    final imageUrl = imageElement?.getAttribute('href');

    // 创建 Episode 对象时，附带 Subscription 信息
    episodes.add(Episode(
      title: title,
      descriptionHTML: descriptionHTML,
      pubDate: DateFormat('E, d MMM yyyy HH:mm:ss Z').parse(pubDate),
      audioUrl: audioUrl,
      durationInSeconds: durationInSeconds ?? 0,
      imageUrl: imageUrl,
      subscription: subscription, // 传入 Subscription
    ));
  }

  return episodes;
}

class PodcastService {
  final String rssUrl;

  PodcastService(this.rssUrl);

  Future<String> fetchSubscriptionData() async {
    try {
      final response =
          await http.get(Uri.parse(rssUrl)).timeout(const Duration(seconds: 5));
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
          final cachedData = await PodcastCacheManager.getCachedFile(rssUrl);
          if (cachedData != null) {
            return await compute(
              parseEpisodes,
              ParserParams(cachedData, rssUrl),
            );
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
        return await compute(
          parseEpisodes,
          ParserParams(cachedData, rssUrl),
        );
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
          final cachedData = await PodcastCacheManager.getCachedFile(rssUrl);
          if (cachedData != null) {
            return await compute(
              parseEpisodes,
              ParserParams(cachedData, rssUrl),
            );
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
      return await compute(
        parseEpisodes,
        ParserParams(body, rssUrl),
      );
    } else {
      throw Exception('Failed to load podcast episodes');
    }
  }
}

// 定义一个参数类
class ParserParams {
  final String xmlString;
  final String rssUrl;

  ParserParams(this.xmlString, this.rssUrl);
}
