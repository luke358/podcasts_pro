import 'package:podcasts_pro/models/subscription.dart';
import 'package:html/parser.dart' as html_parser; // 添加 HTML 解析库

class Episode {
  final String title;
  final String descriptionHTML;
  final DateTime pubDate;
  final String? audioUrl;
  final int durationInSeconds;
  final String? imageUrl;
  final Subscription subscription;
  Episode({
    required this.title,
    required this.descriptionHTML,
    required this.pubDate,
    this.audioUrl,
    required this.durationInSeconds,
    this.imageUrl,
    required this.subscription,
  });

  // 将 Episode 对象转换为 Map（用于序列化）
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'pubDate': pubDate.toIso8601String(),
      'audioUrl': audioUrl,
      'durationInSeconds': durationInSeconds,
      'imageUrl': imageUrl,
      'descriptionHTML': descriptionHTML,
      'subscription': subscription.toMap(),
    };
  }

  // 从 Map 创建 Episode 实例（用于反序列化）
  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      title: map['title'],
      descriptionHTML: map['descriptionHTML'],
      pubDate: DateTime.parse(map['pubDate']),
      audioUrl: map['audioUrl'],
      durationInSeconds: map['durationInSeconds'],
      imageUrl: map['imageUrl'],
      subscription: Subscription.fromMap(map['subscription']),
    );
  }
  get description {
    return parseHtml(descriptionHTML);
  }

  // 将 Episode 对象转换为 JSON 字符串
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // 从 JSON 创建 Episode 实例的工厂构造函数
  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title'],
      descriptionHTML: json['descriptionHTML'],
      pubDate: DateTime.parse(json['pubDate']), // 将 pubDate 解析为 DateTime
      audioUrl: json['audioUrl'],
      durationInSeconds: json['durationInSeconds'],
      imageUrl: json['imageUrl'],
      subscription: Subscription.fromMap(json['subscription']),
    );
  }

  // 将 Episode 对象转换为 XML 字符串
  String toXml() {
    final buffer = StringBuffer();
    buffer.writeln('<item>');
    buffer.writeln('<title>$title</title>');
    buffer.writeln('<description>$description</description>');
    buffer.writeln('<pubDate>${pubDate.toIso8601String()}</pubDate>');
    if (audioUrl != null) buffer.writeln('<enclosure url="$audioUrl"/>');
    buffer.writeln('<itunes:duration>${_formatDuration()}</itunes:duration>');
    if (imageUrl != null) buffer.writeln('<itunes:image href="$imageUrl"/>');
    buffer.writeln('</item>');
    return buffer.toString();
  }

  // 格式化时长
  String _formatDuration() {
    final hours = durationInSeconds ~/ 3600;
    final minutes = (durationInSeconds % 3600) ~/ 60;
    final seconds = durationInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

String parseHtml(String htmlString) {
  final document = html_parser.parse(htmlString);
  return document.body?.text ?? '';
}
