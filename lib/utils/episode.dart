import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/models/subscription.dart';

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

Episode episodeFromMediaItem(MediaItem mediaItem) {
  return Episode(
    title: mediaItem.title,
    descriptionHTML: mediaItem.extras?['descriptionHTML'] ?? '',
    pubDate: DateTime.parse(mediaItem.extras?['pubDate'] ?? ''),
    audioUrl: mediaItem.id,
    durationInSeconds: mediaItem.duration?.inSeconds ?? 0,
    imageUrl: mediaItem.artUri.toString(),
    subscription: Subscription.fromJson(mediaItem.extras?['subscription']),
  );
}

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );
  }
