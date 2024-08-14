import 'dart:convert'; // 确保导入了 dart:convert 包
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PodcastCacheManager {
  static final _cacheManager = CacheManager(
    Config(
      'podcastCache',
      stalePeriod: Duration(days: 7), // 缓存过期时间
      maxNrOfCacheObjects: 100, // 最大缓存对象数
    ),
  );

  static Future<String?> getCachedFile(String url,
      {bool ignoreCacheValidity = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshFeedTime = prefs.getInt('${url}_lastRefreshFeedTime') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (ignoreCacheValidity || now - lastRefreshFeedTime < 60 * 60 * 1000) {
      // 缓存有效期为 1 小时
      final file = await _cacheManager.getFileFromCache(url);
      if (file != null) {
        try {
          final bytes = await file.file.readAsBytes();
          return utf8.decode(bytes); // 使用 utf-8 解码
        } catch (e) {
          print('Error reading cache file: $e');
          await clearCache(url);
        }
      }
    }
    return null;
  }

  static Future<void> cacheFile(String url, String data) async {
    try {
      final Uint8List bytes =
          Uint8List.fromList(utf8.encode(data)); // 使用 utf-8 编码
      await _cacheManager.putFile(url, bytes);
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt(
          '${url}_lastRefreshFeedTime', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching file: $e');
    }
  }

  static Future<void> clearCache(String url) async {
    try {
      final file = await _cacheManager.getFileFromCache(url);
      if (file != null) {
        await file.file.delete();
      }
    } catch (e) {
      print('Error clearing cache file: $e');
    }
  }
}
