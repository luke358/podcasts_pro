import 'package:flutter/material.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:podcasts_pro/widgets/cache_image.dart'; // 确保路径正确

class PodcastHeader extends StatelessWidget {
  final Subscription subscription;
  final bool isSubscribed; // 表示当前是否已经订阅
  final VoidCallback onSubscriptionToggle;

  const PodcastHeader({
    super.key,
    required this.subscription,
    required this.isSubscribed, // 添加这个属性
    required this.onSubscriptionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧的播客封面图
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CacheImage(
              url: subscription.imageUrl,
              size: 100,
            ),
          ),
          const SizedBox(width: 16.0),
          // 右侧的标题、作者和按钮
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  subscription.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                // 假设作者信息可以从订阅数据中获取，或者可以添加一个作者属性
                Text(
                  subscription.author,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16.0),
                TextButton.icon(
                  onPressed: onSubscriptionToggle,
                  icon: Icon(
                    isSubscribed ? Icons.check : Icons.add,
                    color: isSubscribed ? Colors.green : Colors.blue,
                  ),
                  label: Text(
                    isSubscribed ? '已经订阅' : '订阅',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSubscribed ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
