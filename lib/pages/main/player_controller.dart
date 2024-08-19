import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:podcasts_pro/audio/my_audio_handler.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:podcasts_pro/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const int MAX_PLAYLIST_LENGTH = 100;

enum PlayingState {
  paused,
  playing,
  loading,
}

class PlayerController extends GetxController {
  late MyAudioHandler _audioHandler;

  var playingState = PlayingState.paused.obs;
  var isShuffleMode = false.obs;

  var playlist = <Episode>[].obs;
  var currentEpisode = Rxn<Episode>();

  var currentPosition = Duration.zero.obs;
  var playbackSpeed = 1.0.obs; // 默认为1.0x速度

  @override
  void onInit() async {
    super.onInit();
    _audioHandler = await initAudioService() as MyAudioHandler;
    _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);

    await _loadPlaylist();
    await _loadPlaylistToAudioHandler();
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToMediaItem();
  }

  Future<void> _loadPlaylistToAudioHandler() async {
    final mediaItems =
        playlist.map((episode) => mediaItemFromEpisode(episode)).toList();

    // print("object ${mediaItems[0]}");
    await _audioHandler.addQueueItems(mediaItems);
    _audioHandler.suppressStreamUpdates = false;
    await _audioHandler.skipToQueueItem(1);
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playingState.value = PlayingState.loading;
      } else if (!isPlaying) {
        playingState.value = PlayingState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playingState.value = PlayingState.playing;
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((pos) {
      currentPosition.value = pos;
    });
  }

  void _listenToMediaItem() {
    _audioHandler.mediaItem.listen((mediaItem) {
      currentEpisode.value =
          mediaItem != null ? episodeFromMediaItem(mediaItem) : null;
      print("cccc");
      print(currentEpisode.value);
    });
  }

  Future<void> add(Episode episode) async {
    _audioHandler.addQueueItem(mediaItemFromEpisode(episode));
  }

  void remove(Episode episode) {
    final lastIndex = _audioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    _audioHandler.removeQueueItemAt(lastIndex);
  }

  void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((list) {
      if (list.isEmpty) {
        playlist.value = [];
        currentEpisode.value = null;
      } else {
        final newList =
            list.map((mediaItem) => episodeFromMediaItem(mediaItem)).toList();
        playlist.value = newList;
      }
      print("object ${playlist.length}");
      savePlaylist();
    });
  }

  Future<void> savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(playlist.map((e) => e.toMap()).toList());
    await prefs.setString('playlist', jsonString);
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('playlist');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      playlist.value = jsonList.map((jsonItem) {
        return Episode.fromMap(jsonItem as Map<String, dynamic>);
      }).toList();
    }
  }

  Future<void> saveCurrentEpisode() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(currentEpisode.value?.toMap());
    await prefs.setString('current_episode', jsonString);
  }

  Future<void> loadCurrentEpisode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('current_episode');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        currentEpisode.value = Episode.fromMap(jsonMap);
      } else {
        currentEpisode.value = null;
      }
    } catch (e) {
      print('Failed to load current episode: $e');
      currentEpisode.value = null;
    }
  }

  void shuffle() {
    final enable = !isShuffleMode.value;
    isShuffleMode.value = enable;
    if (enable) {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();
  void seek(Duration position) {
    print("seek $position");
    _audioHandler.seek(position);
  }

  void previous() => _audioHandler.skipToPrevious();
  void next() => _audioHandler.skipToNext();

  bool isCurrentEpisode(Episode episode) {
    return currentEpisode.value?.audioUrl == episode.audioUrl;
  }

  @override
  void dispose() {
    super.dispose();
    _audioHandler.customAction('dispose');
  }

  void stop() {
    _audioHandler.stop();
  }
}

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
