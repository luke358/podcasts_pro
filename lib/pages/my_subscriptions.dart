import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/config/route.dart';
import 'package:podcasts_pro/pages/subscription_detail.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';
import 'package:podcasts_pro/widgets/player_bar.dart'; // Ensure this import

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  _MySubscriptionsPageState createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  final SubscriptionController _subscriptionController =
      Get.find<SubscriptionController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的订阅节目'),
      ),
      body: SafeArea(
        child: Obx(() {
          final subscriptions = _subscriptionController.subscriptions;

          if (subscriptions.isEmpty) {
            return const Center(child: Text('No subscriptions found'));
          }

          return Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 80.0, left: 15, right: 15),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            Right2LeftPageRoute(
                                page: SubscriptionDetailPage(
                              rssUrl: subscription.rssUrl, // 传递 rssUrl
                              title: subscription.title,
                            )));
                      },
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                width: 80,
                                height: 80,
                                imageUrl: subscription.imageUrl,
                                httpHeaders: const {
                                  'User-Agent':
                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                                },
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              subscription.title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: PlayerBar(), // Bottom playback menu
              ),
            ],
          );
        }),
      ),
    );
  }
}
