import 'package:audio_service/audio_service.dart';
import 'package:podcasts_pro/models/episode.dart';

MediaItem mediaItemFromEpisode(Episode episode) {
  return MediaItem(
    id: episode.audioUrl ?? '',
    album: episode.subscription.title,
    title: episode.title,
    artist: episode.subscription.author,
    duration: Duration(seconds: episode.durationInSeconds),
    artUri: Uri.parse(episode.imageUrl ?? ''),
    extras: {
      'descriptionHTML': episode.descriptionHTML,
      'pubDate': episode.pubDate.toIso8601String(),
      'subscription': episode.subscription.toJson(),
    },
  );
}

