import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PodcastCacheManager {
  static final _cacheManager = CacheManager(
    Config(
      'podcastCache',
      stalePeriod: const Duration(days: 7), // 缓存过期时间
      maxNrOfCacheObjects: 100, // 最大缓存对象数
    ),
  );

  static Future<String?> getCachedFile(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      final now = DateTime.now();
      if (fileInfo.validTill.isAfter(now)) {
        // 缓存仍然有效
        print("走缓存");
        try {
          final bytes = await fileInfo.file.readAsBytes();
          return utf8.decode(bytes);
        } catch (e) {
          print('Error reading cache file: $e');
          await clearCache(url);
        }
      } else {
        // 缓存已过期，尝试刷新
        try {
          final newFileInfo = await _cacheManager.downloadFile(url);
          final bytes = await newFileInfo.file.readAsBytes();
          return utf8.decode(bytes);
        } catch (e) {
          print('Error refreshing cache: $e');
          // 如果刷新失败，仍然使用旧的缓存
          final bytes = await fileInfo.file.readAsBytes();
          return utf8.decode(bytes);
        }
      }
    }
    return null;
  }

  static Future<void> cacheFile(String url, String data) async {
    try {
      final Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      await _cacheManager.putFile(url, bytes);
    } catch (e) {
      print('Error caching file: $e');
    }
  }

  static Future<void> clearCache(String url) async {
    try {
      await _cacheManager.removeFile(url);
    } catch (e) {
      print('Error clearing cache file: $e');
    }
  }
}
