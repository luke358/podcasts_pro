import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';

class AddSubscriptionPage extends StatefulWidget {
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

    final rssUrls = _rssUrlController.text
        .split('\n')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    List<Future<void>> tasks = [];
    for (String rssUrl in rssUrls) {
      tasks.add(_importSubscription(rssUrl));
    }

    await Future.wait(tasks);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _importSubscription(String rssUrl) async {
    try {
      final subscription = await Subscription.fromRssUrl(rssUrl);
      await _subscriptionController.addOrReplaceSubscription(subscription);
      setState(() {
        _importResults[rssUrl] = 'Success';
      });
    } catch (e) {
      setState(() {
        _importResults[rssUrl] = 'Failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _rssUrlController,
                decoration: InputDecoration(
                  labelText: 'RSS URLs (one per line)',
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
                  ? CircularProgressIndicator()
                  : Text('Import Subscriptions'),
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
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.error, color: Colors.red),
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
