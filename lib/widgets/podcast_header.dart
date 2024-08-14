import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:podcasts_pro/models/subscription.dart'; // 确保路径正确

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
            child: CachedNetworkImage(
              width: 100,
              height: 100,
              imageUrl: subscription.imageUrl,
              httpHeaders: const {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
              },
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
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
                  'Author Name', // 使用真实的作者信息替代
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
