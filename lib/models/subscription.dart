import 'dart:convert';

import 'package:podcasts_pro/http/podcast_service.dart';
import 'package:xml/xml.dart' as xml;

class Subscription {
  final String title;
  final String link;
  final String description;
  final String imageUrl;
  final String author;
  final DateTime subscriptionDate;
  final String rssUrl;

  Subscription({
    required this.title,
    required this.link,
    required this.description,
    required this.imageUrl,
    required this.author,
    required this.subscriptionDate,
    required this.rssUrl,
  });

  static Future<Subscription> fromRssUrl(String rssUrl) async {
    final service = PodcastService(rssUrl);
    final xmlString = await service.fetchSubscriptionData(); // 获取 RSS 数据

    // 解析订阅信息
    final subscription = parseSubscription(xmlString, rssUrl);

    return subscription;
  }

  static Subscription parseSubscription(String xmlString, String rssUrl) {
    final document = xml.XmlDocument.parse(xmlString);
    final channel = document.findAllElements('channel').first;

    final title = channel.findElements('title').single.text;
    final link = channel.findElements('link').single.text;
    final description = channel.findElements('description').single.text;
    final imageUrl =
        channel.findElements('itunes:image').single.getAttribute('href') ?? '';
    final author = channel.findElements('itunes:author').single.text;

    return Subscription(
      title: title,
      link: link,
      description: description,
      imageUrl: imageUrl,
      author: author,
      subscriptionDate: DateTime.now(),
      rssUrl: rssUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'description': description,
      'imageUrl': imageUrl,
      'author': author,
      'subscriptionDate': subscriptionDate.toIso8601String(),
      'rssUrl': rssUrl,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      title: map['title'],
      link: map['link'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      author: map['author'],
      subscriptionDate: DateTime.parse(map['subscriptionDate']),
      rssUrl: map['rssUrl'],
    );
  }
  factory Subscription.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return Subscription.fromMap(map);
  }

  String toJson() => json.encode(toMap());
}
