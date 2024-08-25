import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';

class AddSubscriptionPage extends StatefulWidget {
  const AddSubscriptionPage({super.key});

  @override
  _AddSubscriptionPageState createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  final TextEditingController _rssUrlController = TextEditingController();
  final SubscriptionController _subscriptionController =
      Get.find<SubscriptionController>();
  bool _isLoading = false;
  final Map<String, String> _importResults = {};

  Future<void> _addSubscriptions() async {
    setState(() {
      _isLoading = true;
      _importResults.clear();
    });

    try {
      final rssUrls = _rssUrlController.text
          .split('\n')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      List<Future<Subscription?>> tasks = [];
      for (String rssUrl in rssUrls) {
        tasks.add(_importSubscription(rssUrl));
      }

      final subscriptions = await Future.wait(tasks);
      final successfulSubscriptions =
          subscriptions.whereType<Subscription>().toList();

      if (successfulSubscriptions.isNotEmpty) {
        await _subscriptionController
            .addOrReplaceSubscriptions(successfulSubscriptions);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Subscription?> _importSubscription(String rssUrl) async {
    try {
      final subscription = await Subscription.fromRssUrl(rssUrl);
      setState(() {
        _importResults[rssUrl] = 'Success';
      });
      return subscription;
    } catch (e) {
      setState(() {
        _importResults[rssUrl] = 'Failed: $e';
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加订阅')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _rssUrlController,
                decoration: const InputDecoration(
                  labelText: '输入 RSS 地址  (每行一个)',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                minLines: 5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addSubscriptions,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('订阅'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _importResults.length,
                itemBuilder: (context, index) {
                  final rssUrl = _importResults.keys.elementAt(index);
                  final result = _importResults[rssUrl];
                  return ListTile(
                    title: Text(rssUrl),
                    subtitle: Text(result!),
                    leading: result == 'Success'
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
