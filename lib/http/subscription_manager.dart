import 'package:podcasts_pro/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SubscriptionManager {
  static const String _subscriptionsKey = 'subscriptions';

  // 添加或替换订阅数据
  Future<bool> addOrReplaceSubscription(Subscription subscription) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptions = await _loadSubscriptions();

    final existingIndex =
        subscriptions.indexWhere((s) => s.rssUrl == subscription.rssUrl);
    if (existingIndex != -1) {
      // 如果已存在相同的 RSS URL，替换它
      subscriptions[existingIndex] = subscription;
    } else {
      // 否则添加新的订阅
      subscriptions.add(subscription);
    }

    final jsonString =
        json.encode(subscriptions.map((e) => e.toMap()).toList());
    await prefs.setString(_subscriptionsKey, jsonString);

    return existingIndex != -1;
  }

  // 检查是否已订阅
  Future<bool> isSubscribed(String rssUrl) async {
    final subscriptions = await _loadSubscriptions();
    return subscriptions.any((sub) => sub.rssUrl == rssUrl);
  }

  // 切换订阅状态
  Future<void> toggleSubscription(Subscription subscription) async {
    final isCurrentlySubscribed = await isSubscribed(subscription.rssUrl);
    if (isCurrentlySubscribed) {
      await clearSubscriptions(subscription.rssUrl); // 取消订阅逻辑
    } else {
      await addOrReplaceSubscription(subscription); // 订阅逻辑
    }
  }

  // 清除所有订阅数据
  Future<void> clearSubscriptions([String? rssUrl]) async {
    final prefs = await SharedPreferences.getInstance();
    if (rssUrl != null) {
      final subscriptions = await _loadSubscriptions();
      final updatedSubscriptions =
          subscriptions.where((sub) => sub.rssUrl != rssUrl).toList();
      final jsonString =
          json.encode(updatedSubscriptions.map((e) => e.toMap()).toList());
      await prefs.setString(_subscriptionsKey, jsonString);
    } else {
      await prefs.remove(_subscriptionsKey);
    }
  }

  // 加载所有订阅数据
  Future<List<Subscription>> _loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_subscriptionsKey) ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);

    return jsonList.map((jsonItem) {
      return Subscription.fromMap(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  // 获取所有订阅数据
  Future<List<Subscription>> getSubscriptions() async {
    return await _loadSubscriptions();
  }
}
