import 'package:get/get.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SubscriptionController extends GetxController {
  static const String _subscriptionsKey = 'subscriptions';
  var subscriptions = <Subscription>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSubscriptions();
  }

  // 加载所有订阅数据
  Future<void> _loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_subscriptionsKey) ?? '[]';
    final List<dynamic> jsonList = json.decode(jsonString);

    subscriptions.value = jsonList.map((jsonItem) {
      return Subscription.fromMap(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  // 添加或替换订阅数据
  Future<bool> addOrReplaceSubscription(Subscription subscription) async {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionsKey, jsonString);

    return existingIndex != -1;
  }

  // 添加或替换多个订阅数据
  Future<void> addOrReplaceSubscriptions(
      List<Subscription> newSubscriptions) async {
    bool hasChanges = false;

    for (var subscription in newSubscriptions) {
      final existingIndex =
          subscriptions.indexWhere((s) => s.rssUrl == subscription.rssUrl);
      if (existingIndex != -1) {
        // 如果已存在相同的 RSS URL，替换它
        subscriptions[existingIndex] = subscription;
      } else {
        // 否则添加新的订阅
        subscriptions.add(subscription);
      }
      hasChanges = true;
    }

    if (hasChanges) {
      final jsonString =
          json.encode(subscriptions.map((e) => e.toMap()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionsKey, jsonString);
    }
  }

  // 检查是否已订阅
  bool isSubscribed(String rssUrl) {
    return subscriptions.any((sub) => sub.rssUrl == rssUrl);
  }

  // 切换订阅状态
  Future<void> toggleSubscription(Subscription subscription) async {
    final isCurrentlySubscribed = isSubscribed(subscription.rssUrl);
    if (isCurrentlySubscribed) {
      await clearSubscriptions(subscription.rssUrl); // 取消订阅逻辑
    } else {
      await addOrReplaceSubscription(subscription); // 订阅逻辑
    }
  }

  // 清除所有订阅数据
  Future<void> clearSubscriptions([String? rssUrl]) async {
    if (rssUrl != null) {
      subscriptions.removeWhere((sub) => sub.rssUrl == rssUrl);
    } else {
      subscriptions.clear();
    }
    final jsonString =
        json.encode(subscriptions.map((e) => e.toMap()).toList());
    final prefs = await SharedPreferences.getInstance();
    if (rssUrl != null) {
      await prefs.setString(_subscriptionsKey, jsonString);
    } else {
      await prefs.remove(_subscriptionsKey);
    }
  }

  // 获取所有订阅数据
  List<Subscription> getSubscriptions() {
    return subscriptions;
  }
}
